#include <fprint.h>
#include <stdio.h>
int main(void){
  FpContext *c = fp_context_new();
  GPtrArray *d = fp_context_get_devices(c);
  printf("devices: %u\n", d ? d->len : 0);
  for (guint i=0; d && i<d->len; i++) {
    FpDevice *dev = g_ptr_array_index(d,i);
    printf("  [%u] driver=%s id=%s name=%s nr_enroll_stages=%d scan_type=%d\n", i,
      fp_device_get_driver(dev), fp_device_get_device_id(dev), fp_device_get_name(dev),
      fp_device_get_nr_enroll_stages(dev), fp_device_get_scan_type(dev));
  }
  return 0;
}
