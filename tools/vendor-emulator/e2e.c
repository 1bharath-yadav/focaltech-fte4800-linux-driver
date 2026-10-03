// e2e.c -- end-to-end enroll/verify of recorded REAL frames through the vendor libfprint + emu.so
// usage: ./e2e <labels.txt> <ntrain>   (env: FT_EMU_FRAMES, LD_PRELOAD=emu.so, LD_LIBRARY_PATH=origlib)
#define _GNU_SOURCE
#include <fprint.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>

static void (*emu_push)(int), (*emu_clear)(void);
static int (*emu_left)(void), (*emu_nframes)(void), (*emu_read_cnt)(void);
static double (*emu_idle)(void);
static GCancellable *canc; static volatile int active;

static void *watchdog(void *x) {
  (void)x;
  for (;;) { usleep(100000);
    if (active && emu_left() == 0 && emu_idle() > 2.0) g_cancellable_cancel(canc); }
  return NULL;
}
static void progress(FpDevice *d, gint done, FpPrint *p, gpointer u, GError *err) {
  (void)d; (void)p; (void)u;
  printf("   enroll progress: %d/12 frames_read=%d queue_left=%d %s%s\n", done, emu_read_cnt(), emu_left(),
         err ? "retry/err: " : "", err ? err->message : "");
}

int main(int argc, char **argv) {
  emu_push = dlsym(RTLD_DEFAULT, "ft_emu_push"); emu_clear = dlsym(RTLD_DEFAULT, "ft_emu_clear");
  emu_left = dlsym(RTLD_DEFAULT, "ft_emu_queue_left"); emu_nframes = dlsym(RTLD_DEFAULT, "ft_emu_nframes");
  emu_idle = dlsym(RTLD_DEFAULT, "ft_emu_idle_s"); emu_read_cnt = dlsym(RTLD_DEFAULT, "ft_emu_frames_read");
  if (!emu_push || argc < 3) { fprintf(stderr, "need emu.so preloaded; usage: e2e labels ntrain\n"); return 1; }
  int n = emu_nframes(); char lab[256] = {0}; FILE *f = fopen(argv[1], "r");
  for (int i = 0; i < n && f; i++) { char s[8]; if (!fgets(s, sizeof s, f)) break; lab[i] = s[0]; } if (f) fclose(f);
  int ntrain = atoi(argv[2]);
  int trainA[64], nt = 0, testA[64], nta = 0, testB[64], ntb = 0;
  for (int i = 0; i < n; i++) { if (lab[i] == 'A') { if (nt < ntrain) trainA[nt++] = i; else testA[nta++] = i; } else if (lab[i] == 'B') testB[ntb++] = i; }
  printf("frames=%d  train(A)=%d  test genuine(A)=%d  impostor(B)=%d\n", n, nt, nta, ntb);

  GError *e = NULL; FpContext *c = fp_context_new(); GPtrArray *d = fp_context_get_devices(c);
  if (!d || !d->len) { printf("no device\n"); return 2; }
  FpDevice *dev = g_ptr_array_index(d, 0);
  if (!fp_device_open_sync(dev, NULL, &e)) { printf("open failed: %s\n", e->message); return 3; }
  canc = g_cancellable_new(); pthread_t th; pthread_create(&th, NULL, watchdog, NULL);

  FpPrint *tpl = fp_print_new(dev); fp_print_set_finger(tpl, FP_FINGER_RIGHT_INDEX); fp_print_set_username(tpl, "emu");
  emu_clear(); for (int i = 0; i < nt; i++) emu_push(trainA[i]);
  printf("== ENROLL with %d real A frames\n", nt);
  active = 1; g_cancellable_reset(canc); e = NULL;
  FpPrint *enr = fp_device_enroll_sync(dev, tpl, canc, progress, NULL, &e);
  active = 0;
  if (!enr) { printf("ENROLL FAILED: %s (frames_read=%d queue_left=%d)\n", e ? e->message : "?", emu_read_cnt(), emu_left()); fp_device_close_sync(dev, NULL, NULL); return 4; }
  printf("ENROLL OK (frames_read=%d, unused=%d)\n", emu_read_cnt(), emu_left());

  int ga = 0, ia = 0, retryG = 0, retryI = 0;
  for (int pass = 0; pass < 2; pass++) {
    int *L = pass ? testB : testA, cnt = pass ? ntb : nta;
    printf("== VERIFY %s frames\n", pass ? "IMPOSTOR (B)" : "GENUINE (A, held-out)");
    for (int k = 0; k < cnt; k++) {
      emu_clear(); emu_push(L[k]); gboolean match = FALSE; FpPrint *np = NULL; e = NULL;
      g_cancellable_reset(canc); active = 1;
      gboolean ok = fp_device_verify_sync(dev, enr, canc, NULL, NULL, &match, &np, &e); active = 0;
      const char *r = ok ? (match ? "MATCH" : "no-match") : "ERR";
      printf("   frame %2d (%c): %-8s %s\n", L[k], lab[L[k]], r, (!ok && e) ? e->message : "");
      if (ok && match) { if (pass) ia++; else ga++; }
      if (!ok || !ok) { if (pass) retryI++; else retryG++; }
      if (e) g_clear_error(&e);
    }
  }
  printf("\nRESULT: genuine accepted %d/%d (errors/retry %d) | impostor accepted %d/%d (errors/retry %d)\n", ga, nta, retryG, ia, ntb, retryI);
  fp_device_close_sync(dev, NULL, NULL);
  return 0;
}
