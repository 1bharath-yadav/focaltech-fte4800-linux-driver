#include <fprint.h>
#include <stdio.h>
int main(void){
  GError *e = NULL;
  FpContext *c = fp_context_new();
  GPtrArray *d = fp_context_get_devices(c);
  if (!d || !d->len) { printf("no device\n"); return 1; }
  FpDevice *dev = g_ptr_array_index(d, 0);
  if (!fp_device_open_sync(dev, NULL, &e)) { printf("open failed: %s\n", e ? e->message : "?"); return 2; }
  printf("opened. is_open=%d\n", fp_device_is_open(dev));
  GPtrArray *prints = fp_device_list_prints_sync(dev, NULL, &e);
  printf("list_prints: %s n=%u\n", prints ? "ok" : (e ? e->message : "fail"), prints ? prints->len : 0);
  fp_device_close_sync(dev, NULL, NULL);
  printf("closed\n");
  return 0;
}
