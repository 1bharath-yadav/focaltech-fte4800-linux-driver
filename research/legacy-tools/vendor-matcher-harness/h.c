// Offline harness: drive FocalTech's matcher inside the vendor libfprint .so with captured FT9368 frames.
// Entry points are by file offset (stripped lib). Original (unpatched) .so, sha256 5639bda2...
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include <sys/wait.h>

static uint8_t *B;
#define P(off) ((void *)(B + (off)))

static int quiet = 0;
static int g_score=-1, g_ovl=-1;
static void logfn(const char *fmt, ...)
{
  char buf[1024];
  va_list ap; va_start(ap, fmt); vsnprintf(buf, sizeof buf, fmt, ap); va_end(ap);
  { const char *p; int v;
    if ((p=strstr(buf,"FtVerifyTwoTemplate...leave, match score = ")) && sscanf(p+strlen("FtVerifyTwoTemplate...leave, match score = "),"%d",&v)==1 && v>g_score) g_score=v;
    if ((p=strstr(buf,"DeltaOverlap = ")) && sscanf(p+strlen("DeltaOverlap = "),"%d",&v)==1) g_ovl=v; }
  if (quiet == 1) return;
  if (quiet == 2) {
    const char *kw[] = {"atch", "core", "dentify", "erify", "verlap", "quality", "Score", "similar", "Thr", NULL};
    int ok = 0; for (int i = 0; kw[i]; i++) if (strstr(buf, kw[i])) ok = 1;
    if (!ok || strstr(buf, "FtInterp") || strstr(buf, "InitSub")) return;
  }
  printf("    [lib] %s", buf); if (!strchr(buf, '\n')) putchar('\n');
}

typedef int (*fn_init)(void);
typedef int (*fn_enroll)(int, int, uint8_t *);
typedef int (*fn_ident)(uint8_t *, int, uint8_t *, uint8_t *);

#define W0 64
#define H0 80
static uint8_t frames[64][W0 * H0];
static int labels[64], nframes;

static void load(void)
{
  FILE *f = fopen(getenv("FRAMES") ? getenv("FRAMES") : "/home/archer/projects/zerobook-focaltech-driver/tools/vendor-matcher-harness/frames.bin", "rb");
  while (nframes < 64 && fread(frames[nframes], 1, W0 * H0, f) == W0 * H0) nframes++;
  fclose(f);
  f = fopen("/home/archer/projects/zerobook-focaltech-driver/tools/vendor-matcher-harness/labels.txt", "r");
  for (int i = 0; i < nframes; i++) if (fscanf(f, "%d", &labels[i]) != 1) break;
  fclose(f);
}

static void transform(const uint8_t *in, uint8_t *out, int transpose, int invert)
{
  if (!transpose) memcpy(out, in, W0 * H0);
  else for (int y = 0; y < H0; y++) for (int x = 0; x < W0; x++) out[x * H0 + y] = in[y * W0 + x]; // 80-wide x 64-high
  if (invert) for (int i = 0; i < W0 * H0; i++) out[i] = 255 - out[i];
}

int main(int argc, char **argv)
{
  const char *so = "/home/archer/projects/zerobook-focaltech-driver/reference/backup-proprietary/libfprint-2.so.2.0.0.orig";
  int transpose = argc > 1 ? atoi(argv[1]) : 0, invert = argc > 2 ? atoi(argv[2]) : 0;
  int nenroll = argc > 3 ? atoi(argv[3]) : 8;
  quiet = argc > 4 ? atoi(argv[4]) : 0;
  void *h = dlopen(so, RTLD_LAZY | RTLD_LOCAL);
  if (!h) { fprintf(stderr, "dlopen: %s\n", dlerror()); return 1; }
  void *anchor = dlsym(h, "fp_device_enroll");
  B = (uint8_t *)anchor - 0x16cd0;
  printf("base=%p\n", (void *)B);

  // enable the library's own logging via callback (type 2)
  *(uint8_t *)P(0x30bd3d9) = 2;
  *(void **)P(0x30bd3d0) = (void *)logfn;
  *(uint32_t *)P(0x209398) = 0;

  int r = ((fn_init)P(0x66b20))();
  printf("SensorResourceCreate -> %d\n", r);
  uint8_t *cfg = *(uint8_t **)P(0x30bd288);
  printf("cfg=%p w=%d h=%d qthr=%d tips=%d\n", (void *)cfg, cfg ? *(int *)cfg : -1, cfg ? *(int *)(cfg + 4) : -1,
         cfg ? *(uint16_t *)(cfg + 0x26) : -1, cfg ? *(int *)(cfg + 0x10) : -1);
  if (!cfg) return 2;
  cfg[0x26] = 40; cfg[0x27] = 0;   // QualityThreshold 90->40 (as in earlier vendor patch)
  r = ((fn_init)P(0x67f40))();
  printf("InitFpAlg -> %d\n", r);

  load();

  if (getenv("PAIRS")) {
    int maxj = getenv("PAIRS_MAX") ? atoi(getenv("PAIRS_MAX")) : nframes;
    for (int i = 0; i < maxj; i++) for (int j = i+1; j < maxj; j++) {
      fflush(stdout);
      pid_t pid = fork();
      if (pid == 0) {
        uint8_t a[W0*H0], b[W0*H0];
        transform(frames[i], a, transpose, invert); transform(frames[j], b, transpose, invert);
        ((fn_enroll)P(0x70700))(0, 1, a);
        g_score = -1; g_ovl = -1;
        int r2 = ((fn_enroll)P(0x70700))(0, 2, b);
        printf("PAIR %d %d %d %d %d %d %d\n", i, j, labels[i], labels[j], g_score, g_ovl, r2);
        fflush(stdout); _exit(0);
      }
      int st; waitpid(pid, &st, 0);
    }
    return 0;
  }
  if (getenv("SELF")) {
    int W = transpose ? H0 : W0, H = transpose ? W0 : H0;
    int fi = atoi(getenv("SELF"));
    uint8_t a[W0*H0], b[W0*H0];
    transform(frames[fi], a, transpose, invert);
    int shifts[] = {0, 2, 5, 10, 20};
    for (int k = 0; k < 5; k++) {
      int sx = shifts[k];
      for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) { int xs = x + sx; b[y*W+x] = xs < W ? a[y*W+xs] : 128; }
      printf("== shift %d px: self frame %d\n", sx, fi);
      int r1 = ((fn_enroll)P(0x70700))(0, 1, a);
      int r2 = ((fn_enroll)P(0x70700))(0, 2, b);
      printf("   ret1=%d ret2=%d\n", r1, r2);
    }
    // frame vs. a different A frame and a B frame
    int other = atoi(getenv("OTHER") ? getenv("OTHER") : "5");
    transform(frames[other], b, transpose, invert);
    printf("== frame %d (label %d) vs frame %d (label %d)\n", fi, labels[fi], other, labels[other]);
    ((fn_enroll)P(0x70700))(0, 1, a); ((fn_enroll)P(0x70700))(0, 2, b);
    return 0;
  }
  printf("frames=%d\n", nframes);
  uint8_t img[W0 * H0];
  int stage = 0;
  for (int i = 0, k = 0; i < nframes && k < nenroll * 3; i++) {
    if (labels[i] != 0) continue;
    transform(frames[i], img, transpose, invert);
    int rr = ((fn_enroll)P(0x70700))(0, stage + 1, img);
    uint64_t *res = (uint64_t *)P(0x30ebd80);
    printf("enroll frame %2d (A) stage_arg=%d -> ret=%d  res=[%lld %lld %lld]\n", i, stage + 1, rr,
           (long long)res[0], (long long)res[1], (long long)res[2]);
    if (rr == 0) stage++;
    k++;
    if (stage >= nenroll) break;
  }
  printf("accepted enroll stages: %d\n", stage);
  if (!getenv("NOFINISH")) { int vr = ((int(*)(int))P(0xb4820))(0); printf("FtSetTplValidFlag(0) -> %d\n", vr); }
  int used = 0; // frames of A consumed by enrollment
  for (int i = 0, c = 0; i < nframes; i++) if (labels[i] == 0) { c++; if (c <= nenroll) used = i + 1; }
  printf("--- identify (enrolled A frames 0..%d) ---\n", used - 1);
  for (int i = 0; i < nframes; i++) {
    if (!getenv("INCL") && i < used && labels[i] == 0) continue;
    transform(frames[i], img, transpose, invert);
    uint8_t finger = 0xee, upd = 0xee;
    int rr = ((fn_ident)P(0x87e20))(img, 2, &finger, &upd);
    printf("IDENT frame %2d (%c) -> ret=%d finger=%d update=%d\n", i, labels[i] ? 'B' : 'A', rr, finger, upd);
  }
  return 0;
}
