// emu.c -- LD_PRELOAD user-space emulation of /dev/focal_moh_spi for the vendor libfprint.
// Serves REAL recorded sensor frames (no synthetic data). Ports the kernel XLAT state machine.
// Env: FT_EMU_FRAMES=<raw file of N x 5120 B>  FT_EMU_CONV=0|1  FT_EMU_TRACE=1  FT_SHIM_LOG=<file>
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

#define DEVPATH "/dev/focal_moh_spi"
#define FRAME_PIX 5120
static int emu_fd = -1, trace = 0, conv_mode = 0;
static pthread_mutex_t mu = PTHREAD_MUTEX_INITIALIZER;
static int st = 0, scan_active = 0, fdt_scan = 0, work_flag = 0, stage = 0, frames_read = 0;
static uint8_t shadow[256] = { [0xC6] = 0x01, [0x80] = 0x50, [0xFE] = 0x7F, [0xFD] = 0x0A };
static uint8_t fdt_base[16] = { 0xff, 0xe2, 0xff, 0xe2, 0xff, 0xe2, 0xff, 0xe2 };
static uint8_t img[10240];
static size_t img_off = 0;
static int cur = -1;
static uint8_t *frames;
static int nframes;
static int q[1024], qn, qh;
static int native_lift_pending;
static double last_act, ack_time, t0;
static FILE *lf;

static double now(void) { struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts); return ts.tv_sec + ts.tv_nsec * 1e-9; }
static void T(const char *fmt, ...) {
  if (!trace) return;
  if (!lf) { const char *p = getenv("FT_SHIM_LOG"); lf = fopen(p ? p : "/tmp/br/emu.log", "a"); t0 = now(); setvbuf(lf, NULL, _IOLBF, 0); }
  va_list ap; va_start(ap, fmt); fprintf(lf, "%8.3f ", now() - t0); vfprintf(lf, fmt, ap); va_end(ap); fputc('\n', lf);
}

__attribute__((constructor)) static void emu_init(void) {
  const char *e = getenv("FT_EMU_TRACE"); trace = e && *e == '1';
  e = getenv("FT_EMU_CONV"); conv_mode = e ? atoi(e) : 0;
  e = getenv("FT_EMU_FRAMES");
  if (e) { FILE *f = fopen(e, "rb"); if (f) { fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
      nframes = n / FRAME_PIX; frames = malloc(n); if (fread(frames, 1, n, f) != (size_t)n) nframes = 0; fclose(f); } }
}

/* ---- control API for the test client (found via dlsym(RTLD_DEFAULT, ...)) ---- */
int ft_emu_nframes(void) { return nframes; }
void ft_emu_push(int idx) { pthread_mutex_lock(&mu); if (qn < 1024) q[qn++] = idx; last_act = now(); pthread_mutex_unlock(&mu); }
void ft_emu_clear(void) { pthread_mutex_lock(&mu); qn = qh = 0; st = 0; scan_active = fdt_scan = 0; work_flag = 0; img_off = 0; cur = -1; native_lift_pending = 0; last_act = now(); pthread_mutex_unlock(&mu); }
int ft_emu_queue_left(void) { pthread_mutex_lock(&mu); int r = qn - qh; pthread_mutex_unlock(&mu); return r; }
int ft_emu_frames_read(void) { return frames_read; }
double ft_emu_idle_s(void) { return now() - last_act; }

static void load_img(void) {
  if (cur < 0 || cur >= nframes) { memset(img, 0, sizeof img); return; }
  const uint8_t *f = frames + (size_t)cur * FRAME_PIX;
  for (int i = 0; i < FRAME_PIX; i++) {
    unsigned p = f[i]; if (conv_mode == 1) p = 255 - p;
    unsigned w = p << 4;                 /* 12-bit ADC word, big-endian: what the vendor 16-bit pipeline expects */
    img[2 * i] = w >> 8; img[2 * i + 1] = w & 0xff;
  }
  frames_read++; last_act = now();
  T("FRAME load idx=%d (#%d)", cur, frames_read);
}
static void serve_img(uint8_t *out, size_t rx, size_t req) {
  if (img_off == 0) {
    if (qh < qn)
      cur = q[qh++];
    load_img();
  }
  if (img_off >= 10240) img_off = 0;
  if (img_off + req > 10240) req = 10240 - img_off;
  memset(out, 0, rx); memcpy(out, img + img_off, req); img_off += req;
}

static void serve_native_img(uint8_t *out, size_t rx) {
  if (rx < FRAME_PIX) {
    memset(out, 0, rx);
    return;
  }
  if (native_lift_pending) {
    native_lift_pending = 0;
    memset(out, 0, rx);
    return;
  }
  if (qh >= qn || q[qh] < 0 || q[qh] >= nframes) {
    memset(out, 0, rx);
    return;
  }
  cur = q[qh++];
  memset(out, 0, rx);
  memcpy(out, frames + (size_t)cur * FRAME_PIX, FRAME_PIX);
  native_lift_pending = 1;
  frames_read++;
  last_act = now();
  T("NATIVE FRAME load idx=%d (#%d)", cur, frames_read);
}
static void maybe_trigger(void) {
  if (work_flag == 0 && st == 0 && qh < qn && now() - ack_time > 0.05) {
    cur = q[qh++]; st = 1; stage++; work_flag = 2; T("TOUCH trigger frame idx=%d stage=%d", cur, stage);
  }
}

static ssize_t emu_read(uint8_t *buf, size_t n) {
  if (n < 5) return -1;
  unsigned txl = buf[1] | buf[2] << 8, rxl = buf[3] | buf[4] << 8;
  if (n < 5 + txl) return -1;
  uint8_t tx[64] = {0}; memcpy(tx, buf + 5, txl < 64 ? txl : 64);
  uint8_t out[16384]; if (rxl > sizeof out) rxl = sizeof out;
  memset(out, 0, rxl);
  pthread_mutex_lock(&mu);
  if (txl == 7 && tx[0] == 0x91 && tx[1] == 0x80 && rxl == 32) {
    static const uint8_t info[32] = {
      0x00,0x00,0xff,0x00,0x00,0x00,0x00,0x00,
      0x00,0x00,0x00,0x5f,0x21,0x07,0x00,0x20,
      0x22,0x07,0x29,0x93,0x68,0x11,0xaa,0x40,
      0x50,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    };
    memcpy(out, info, sizeof(info));
  } else if (txl == 7 && tx[0] == 0x90 && tx[1] == 0x80 && rxl == FRAME_PIX) {
    serve_native_img(out, rxl);
  } else if (txl == 4 && tx[0] == 0x08 && tx[1] == 0xF7 && rxl >= 1) {
    uint8_t r = tx[2];
    if (r == 0xC6) out[0] = shadow[0xC6] ? shadow[0xC6] : 1;
    else if (r == 0x80) out[0] = (scan_active || st == 3) ? 0x54 : 0x50;
    else if (r == 0xFE) out[0] = shadow[0xFE] ? shadow[0xFE] : 0x7F;
    else if (r == 0xFD) out[0] = shadow[0xFD] ? shadow[0xFD] : 0x0A;
    else out[0] = shadow[r];
  } else if (txl == 6 && tx[0] == 0x04 && tx[1] == 0xFB && rxl >= 2) {
    unsigned a = ((tx[2] & 0x7F) << 8) | tx[3], b = ((tx[3] & 0x7F) << 8) | tx[2];
    if (a == 0x1A8B || b == 0x1A8B) { out[0] = 0x93; out[1] = 0x65; }
    else if (a == 0x1A82 || b == 0x1A82) {
      if (fdt_scan) { out[1] = 0x08; T("INTSTAT fdt-ready"); }
      else if (st == 1 || st == 3) { out[1] = 0x22; T("INTSTAT touch|frame 0x22"); }
      else if (st == 2) { out[1] = 0x04; st = 0; T("INTSTAT release 0x04"); }
    }
    else if (a == 0x1A05 || b == 0x1A05) serve_img(out, rxl, rxl);
    else if (a == 0x00B8 || b == 0x00B8 || a == 0x00E8 || b == 0x00E8) {
      memcpy(out, fdt_base, (rxl > 2 ? rxl - 2 : rxl) < 8 ? (rxl > 2 ? rxl - 2 : rxl) : 8);
      st = 0; scan_active = 0;
    }
    else if (a == 0x1080 || b == 0x1080 || a == 0x0090 || b == 0x0090 || (tx[2] == 0x90 && tx[3] == 0x80))
      serve_img(out, rxl, rxl > 2 ? rxl - 2 : rxl);
    else T("UNHANDLED Read16 a=%04x b=%04x rx=%u", a, b, rxl);
  } else if (txl == 6 && tx[0] == 0x06 && tx[1] == 0xF9) {
    unsigned a = ((tx[2] & 0x7F) << 8) | tx[3], b = ((tx[3] & 0x7F) << 8) | tx[2];
    if (a == 0x1A05 || b == 0x1A05) serve_img(out, rxl, rxl);
    else T("UNHANDLED Bulk a=%04x b=%04x rx=%u", a, b, rxl);
  } else T("UNHANDLED read tx=%u [%02x %02x %02x %02x] rx=%u", txl, tx[0], tx[1], tx[2], tx[3], rxl);
  pthread_mutex_unlock(&mu);
  memcpy(buf, out, rxl);
  return n;
}

static ssize_t emu_write(const uint8_t *buf, size_t n) {
  if (n < 5) return n;
  if (buf[0] == 0xB9) return n;           /* SPI_BACK_DATA */
  const uint8_t *p = buf + 5; size_t wl = n - 5;
  pthread_mutex_lock(&mu);
  if (wl >= 4 && p[0] == 0x09 && p[1] == 0xF6) shadow[p[2]] = p[3];
  if (wl >= 2 && p[0] == 0xC4 && p[1] == 0x3B) scan_active = 1;
  if (wl >= 2 && p[0] == 0xC8 && p[1] == 0x37) scan_active = 1;
  if (wl >= 2 && p[0] == 0xC0 && p[1] == 0x3F) { scan_active = 0; st = 0; work_flag = 0; }
  if (wl >= 4 && p[0] == 0x05 && p[1] == 0xFA) {
    unsigned a = ((p[2] & 0x7F) << 8) | p[3], b = ((p[3] & 0x7F) << 8) | p[2];
    if (a == 0x1885 || b == 0x1885) { fdt_scan = 1; T("FDT manual scan start"); }
    if (a == 0x00B0 || b == 0x00B0 || a == 0x00E0 || b == 0x00E0) {
      size_t bl = wl > 6 ? wl - 6 : 0; if (bl > sizeof fdt_base) bl = sizeof fdt_base; if (bl) memcpy(fdt_base, p + 6, bl);
    }
    if (a == 0x1A84 || b == 0x1A84) {
      int c = st; unsigned clr = wl >= 8 ? (p[6] << 8 | p[7]) : 0;
      T("CLEAR 0x1A84 clr=%04x state=%d fdt=%d off=%zu", clr, c, fdt_scan, img_off);
      if (fdt_scan && (clr & 0x0008)) { fdt_scan = 0; st = 2; scan_active = 0; }
      else if (clr & 0x0008) fdt_scan = 0;
      if (((clr & 0x0020) || (clr & 0x002f) || clr == 0xffff || img_off >= 10240) && (c != 0 || img_off > 0)) {
        st = 0; scan_active = 0; img_off = 0; work_flag = 0; ack_time = now(); T("FRAME ACK -> idle");
      } else if (c == 1) { st = 3; scan_active = 1; }
      else if (c == 2) st = 0;
    }
  }
  pthread_mutex_unlock(&mu);
  return n;
}

#define ISEMU(fd) ((fd) >= 0 && (fd) == emu_fd)
int open(const char *path, int flags, ...) {
  mode_t m = 0; if (flags & O_CREAT) { va_list ap; va_start(ap, flags); m = va_arg(ap, mode_t); va_end(ap); }
  static int (*r)(const char *, int, ...); if (!r) r = dlsym(RTLD_NEXT, "open");
  if (path && !strcmp(path, DEVPATH) && frames) { int fd = r("/dev/null", O_RDWR); emu_fd = fd; T("OPEN emu fd=%d", fd); return fd; }
  return r(path, flags, m);
}
int open64(const char *path, int flags, ...) {
  mode_t m = 0; if (flags & O_CREAT) { va_list ap; va_start(ap, flags); m = va_arg(ap, mode_t); va_end(ap); }
  static int (*r)(const char *, int, ...); if (!r) r = dlsym(RTLD_NEXT, "open64");
  if (path && !strcmp(path, DEVPATH) && frames) { int fd = r("/dev/null", O_RDWR); emu_fd = fd; T("OPEN64 emu fd=%d", fd); return fd; }
  return r(path, flags, m);
}
int close(int fd) { static int (*r)(int); if (!r) r = dlsym(RTLD_NEXT, "close"); if (ISEMU(fd)) { T("CLOSE"); emu_fd = -1; } return r(fd); }
ssize_t read(int fd, void *buf, size_t n) { static ssize_t (*r)(int, void *, size_t); if (!r) r = dlsym(RTLD_NEXT, "read"); return ISEMU(fd) ? emu_read(buf, n) : r(fd, buf, n); }
ssize_t write(int fd, const void *buf, size_t n) { static ssize_t (*r)(int, const void *, size_t); if (!r) r = dlsym(RTLD_NEXT, "write"); return ISEMU(fd) ? emu_write(buf, n) : r(fd, buf, n); }
int ioctl(int fd, unsigned long req, ...) {
  va_list ap; va_start(ap, req); void *arg = va_arg(ap, void *); va_end(ap);
  static int (*r)(int, unsigned long, ...); if (!r) r = dlsym(RTLD_NEXT, "ioctl");
  if (!ISEMU(fd)) return r(fd, req, arg);
  pthread_mutex_lock(&mu);
  if (req == 0x808b) { work_flag = (int)(intptr_t)arg; T("IOCTL RELEASE_POLL %d", work_flag); }
  else if (req == 0x8086) { st = 0; scan_active = fdt_scan = 0; img_off = 0; T("IOCTL RESET"); }
  pthread_mutex_unlock(&mu);
  return 0;
}
int poll(struct pollfd *fds, nfds_t nfds, int timeout) {
  static int (*r)(struct pollfd *, nfds_t, int); if (!r) r = dlsym(RTLD_NEXT, "poll");
  int has = 0; for (nfds_t i = 0; i < nfds; i++) if (ISEMU(fds[i].fd)) has = 1;
  if (!has) return r(fds, nfds, timeout);
  double dl = timeout < 0 ? 1e18 : now() + timeout / 1000.0;
  for (;;) {
    int rc = 0;
    for (nfds_t i = 0; i < nfds; i++) fds[i].revents = 0;
    pthread_mutex_lock(&mu); maybe_trigger();
    int ev = work_flag > 0; if (ev) work_flag = 0;
    pthread_mutex_unlock(&mu);
    for (nfds_t i = 0; i < nfds; i++) if (ISEMU(fds[i].fd) && ev && (fds[i].events & POLLIN)) { fds[i].revents = POLLIN; rc++; }
    if (rc) { T("POLL -> POLLIN"); return rc; }
    if (nfds > 1) { struct pollfd o[16]; nfds_t k = 0, idx[16];
      for (nfds_t i = 0; i < nfds && k < 16; i++) if (!ISEMU(fds[i].fd)) { o[k] = fds[i]; idx[k++] = i; }
      int x = r(o, k, 0); if (x > 0) { for (nfds_t j = 0; j < k; j++) fds[idx[j]].revents = o[j].revents; return x; } }
    if (now() >= dl) return 0;
    usleep(2000);
  }
}
