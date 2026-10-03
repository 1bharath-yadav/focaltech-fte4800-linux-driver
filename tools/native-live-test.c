#include <fprint.h>
#include <glib.h>
#include <stdio.h>

static void progress(FpDevice *dev, gint done, FpPrint *print, gpointer user_data, GError *error)
{
    (void)dev;
    (void)print;
    (void)user_data;
    printf("  enroll stage %d/5%s%s\n", done,
           error ? ": " : "",
           error ? error->message : "");
    fflush(stdout);
}

static FpDevice *get_device(FpContext **ctx_out)
{
    FpContext *ctx = fp_context_new();
    GPtrArray *devices = fp_context_get_devices(ctx);
    if (!devices || devices->len == 0) {
        fprintf(stderr, "No libfprint device found.\n");
        g_object_unref(ctx);
        return NULL;
    }

    printf("libfprint devices: %u\n", devices->len);
    for (guint i = 0; i < devices->len; i++) {
        FpDevice *d = g_ptr_array_index(devices, i);
        printf("  [%u] %s | driver=%s | scan=%d\n",
               i, fp_device_get_name(d),
               fp_device_get_driver(d),
               fp_device_get_scan_type(d));
    }
    fflush(stdout);
    *ctx_out = ctx;
    return g_object_ref(g_ptr_array_index(devices, 0));
}

int main(void)
{
    FpContext *ctx = NULL;
    FpDevice *dev = get_device(&ctx);
    if (!dev)
        return 2;

    GError *error = NULL;
    if (!fp_device_open_sync(dev, NULL, &error)) {
        fprintf(stderr, "OPEN FAILED: %s\n", error ? error->message : "unknown");
        g_clear_error(&error);
        g_object_unref(dev);
        g_object_unref(ctx);
        return 3;
    }

    FpPrint *enroll_template = fp_print_new(dev);
    fp_print_set_finger(enroll_template, FP_FINGER_RIGHT_INDEX);
    fp_print_set_username(enroll_template, "live-test");

    GError *enroll_error = NULL;
    GCancellable *cancel = g_cancellable_new();

    printf("\n=== ENROLL ===\n");
    printf("Place the same finger when prompted, then lift it completely between stages.\n");
    fflush(stdout);

    FpPrint *enrolled = fp_device_enroll_sync(
        dev, enroll_template, cancel, progress, NULL, &enroll_error);

    if (!enrolled) {
        fprintf(stderr, "ENROLL FAILED: %s\n",
                enroll_error ? enroll_error->message : "unknown");
        g_clear_error(&enroll_error);
        g_object_unref(enroll_template);
        g_object_unref(cancel);
        fp_device_close_sync(dev, NULL, NULL);
        g_object_unref(dev);
        g_object_unref(ctx);
        return 4;
    }

    printf("ENROLL OK. Stored native FT9368 template.\n");
    fflush(stdout);

    int matches = 0;
    for (int attempt = 1; attempt <= 3; attempt++) {
        gboolean match = FALSE;
        FpPrint *new_print = NULL;
        GError *verify_error = NULL;

        printf("\n=== VERIFY SAME FINGER %d/3 ===\n", attempt);
        printf("Place the enrolled finger.\n");
        fflush(stdout);

        gboolean ok = fp_device_verify_sync(
            dev, enrolled, cancel, NULL, NULL, &match, &new_print, &verify_error);

        if (!ok) {
            printf("VERIFY ERROR: %s\n",
                   verify_error ? verify_error->message : "unknown");
            g_clear_error(&verify_error);
            continue;
        }

        printf("VERIFY RESULT: %s\n", match ? "MATCH" : "NO-MATCH");
        if (match)
            matches++;
        if (new_print)
            g_object_unref(new_print);
    }

    printf("\n=== LIVE RESULT ===\n");
    printf("same-finger matches: %d/3\n", matches);

    g_object_unref(enrolled);
    g_object_unref(enroll_template);
    g_object_unref(cancel);
    fp_device_close_sync(dev, NULL, NULL);
    g_object_unref(dev);
    g_object_unref(ctx);

    return matches == 3 ? 0 : 10;
}
