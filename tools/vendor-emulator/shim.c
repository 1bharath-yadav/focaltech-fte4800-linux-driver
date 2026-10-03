// LD_PRELOAD shim between the vendor libfprint and /dev/focal_moh_spi.
// Mode via FT_SHIM_MODE: "log" (pass-through + trace). Trace goes to FT_SHIM_LOG (default /tmp/br/shim.log).
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

#define DEVPATH "/dev/focal_moh_spi"
static int shim_fd = -1;
static FILE *lf;
static double t0;

static double now(void) { struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts); return ts.tv_sec + ts.tv_nsec * 1e-9; }
static void logf_(const char *fmt, ...) {
  if (!lf) { const char *p = getenv("FT_SHIM_LOG"); lf = fopen(p ? p : "/tmp/br/shim.log", "a"); t0 = now(); setvbuf(lf, NULL, _IOLBF, 0); }
  va_list ap; va_start(ap, fmt); fprintf(lf, "%8.3f ", now() - t0); vfprintf(lf, fmt, ap); va_end(ap);
}
static void hex(char *o, size_t cap, const uint8_t *b, size_t n, size_t max) {
  size_t k = n < max ? n : max, w = 0;
  for (size_t i = 0; i < k && w + 4 < cap; i++) w += snprintf(o + w, cap - w, "%02x ", b[i]);
  if (n > k && w + 4 < cap) snprintf(o + w, cap - w, "..(%zu)", n);
  else o[w] = 0;
}

#define REAL(name, ...) static typeof(name) *real_##name; if (!real_##name) real_##name = dlsym(RTLD_NEXT, #name)

int open(const char *path, int flags, ...) {
  mode_t m = 0; if (flags & O_CREAT) { va_list ap; va_start(ap, flags); m = va_arg(ap, mode_t); va_end(ap); }
  static int (*r)(const char *, int, ...); if (!r) r = dlsym(RTLD_NEXT, "open");
  int fd = r(path, flags, m);
  if (fd >= 0 && path && !strcmp(path, DEVPATH)) { shim_fd = fd; logf_("OPEN %s -> fd %d\n", path, fd); }
  return fd;
}
int open64(const char *path, int flags, ...) {
  mode_t m = 0; if (flags & O_CREAT) { va_list ap; va_start(ap, flags); m = va_arg(ap, mode_t); va_end(ap); }
  static int (*r)(const char *, int, ...); if (!r) r = dlsym(RTLD_NEXT, "open64");
  int fd = r(path, flags, m);
  if (fd >= 0 && path && !strcmp(path, DEVPATH)) { shim_fd = fd; logf_("OPEN64 %s -> fd %d\n", path, fd); }
  return fd;
}
int close(int fd) {
  static int (*r)(int); if (!r) r = dlsym(RTLD_NEXT, "close");
  if (fd == shim_fd) { logf_("CLOSE fd %d\n", fd); shim_fd = -1; }
  return r(fd);
}
ssize_t read(int fd, void *buf, size_t n) {
  static ssize_t (*r)(int, void *, size_t); if (!r) r = dlsym(RTLD_NEXT, "read");
  if (fd != shim_fd) return r(fd, buf, n);
  uint8_t req[64]; size_t k = n < sizeof req ? n : sizeof req; memcpy(req, buf, k);
  ssize_t rc = r(fd, buf, n);
  char hx[256], hr[256];
  hex(hx, sizeof hx, req, k, 24);
  uint16_t txl = req[1] | req[2] << 8, rxl = req[3] | req[4] << 8;
  hex(hr, sizeof hr, buf, rc > 0 ? (size_t)rxl : 0, 24);
  logf_("READ  type=%02x tx=%u rx=%u rc=%zd req[%s] -> [%s]\n", req[0], txl, rxl, rc, hx, hr);
  return rc;
}
ssize_t write(int fd, const void *buf, size_t n) {
  static ssize_t (*r)(int, const void *, size_t); if (!r) r = dlsym(RTLD_NEXT, "write");
  if (fd != shim_fd) return r(fd, buf, n);
  char hx[256]; hex(hx, sizeof hx, buf, n, 32);
  ssize_t rc = r(fd, buf, n);
  logf_("WRITE n=%zu rc=%zd [%s]\n", n, rc, hx);
  return rc;
}
int ioctl(int fd, unsigned long req, ...) {
  va_list ap; va_start(ap, req); void *arg = va_arg(ap, void *); va_end(ap);
  static int (*r)(int, unsigned long, ...); if (!r) r = dlsym(RTLD_NEXT, "ioctl");
  int rc = r(fd, req, arg);
  if (fd == shim_fd) logf_("IOCTL 0x%lx arg=%p rc=%d\n", req, arg, rc);
  return rc;
}
int poll(struct pollfd *fds, nfds_t nfds, int timeout) {
  static int (*r)(struct pollfd *, nfds_t, int); if (!r) r = dlsym(RTLD_NEXT, "poll");
  int rc = r(fds, nfds, timeout);
  for (nfds_t i = 0; i < nfds; i++) if (fds[i].fd == shim_fd && (rc != 0 || timeout != 0)) logf_("POLL timeout=%d rc=%d revents=0x%x\n", timeout, rc, fds[i].revents);
  return rc;
}
