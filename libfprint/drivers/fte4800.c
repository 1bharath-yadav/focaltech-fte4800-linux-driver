/*
 * FocalTech FTE4800 / FT9368 SPI Image Driver for libfprint
 * Copyright (C) 2026
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * Matching strategy:
 *   Enrollment and verification are delegated to FocalTech's native WinBio
 *   engine adapter, executed directly on Linux by vendor-engine.c. The engine
 *   consumes the sensor's native 64×80 grayscale frame and stores an opaque
 *   vendor template in the FpPrint payload.
 */

#define FP_COMPONENT "fte4800"

#include "drivers_api.h"
#include "fte4800.h"
#include "vendor-engine.h"

#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>

/* --------------------------------------------------------------------------
 * Parameters
 * -------------------------------------------------------------------------- */
#define FTE4800_ENROLL_STAGES         12 /* FocalTech engine maximum enrollment samples */
#define FTE4800_TOUCH_VAR_THRESH     350
#define FTE4800_ENROLL_MIN_VAR      1200
#define FTE4800_POLL_MS             250
#define FTE4800_VENDOR_MAGIC       "FTV1"
#define FTE4800_VENDOR_HEADER       8
#define FTE4800_VENDOR_MAX_TEMPLATE (1024 * 1024)
#define FTE4800_VENDOR_DLL         "/usr/local/lib/fte4800/ftWbioEngineAdapter.dll"

/* --------------------------------------------------------------------------
 * Device instance data
 * -------------------------------------------------------------------------- */
struct _FpiDeviceFte4800
{
  FpImageDevice parent;

  int           spi_fd;
  gboolean      deactivating;

  gint          enroll_count;
};

G_DECLARE_FINAL_TYPE (FpiDeviceFte4800, fpi_device_fte4800, FPI, DEVICE_FTE4800, FpImageDevice);
G_DEFINE_TYPE (FpiDeviceFte4800, fpi_device_fte4800, FP_TYPE_IMAGE_DEVICE);

/* --------------------------------------------------------------------------
 * Low-level SPI helpers
 * -------------------------------------------------------------------------- */

/*
 * Send tx_buf / receive rx_len bytes via the focal_spi kernel misc device.
 * Header format: [0xA5, tx_len_lo, tx_len_hi, rx_len_lo, rx_len_hi, <tx_bytes>]
 * The kernel driver returns rx_len bytes starting at offset 0 of the same buf.
 */
static int
fte4800_spi_transfer (int fd, const guint8 *tx, gsize tx_len,
                      guint8 *rx, gsize rx_len)
{
  gsize buf_len = MAX (5 + tx_len, rx_len);
  g_autofree guint8 *buf = g_malloc0 (buf_len);

  buf[0] = 0xA5;
  buf[1] = (guint8) (tx_len & 0xFF);
  buf[2] = (guint8) ((tx_len >> 8) & 0xFF);
  buf[3] = (guint8) (rx_len & 0xFF);
  buf[4] = (guint8) ((rx_len >> 8) & 0xFF);
  if (tx && tx_len)
    memcpy (buf + 5, tx, tx_len);

  ssize_t n = read (fd, buf, buf_len);
  if (n < 0)
    return -errno;
  if ((gsize) n < rx_len)
    return -EIO;
  if (rx && rx_len)
    memcpy (rx, buf, rx_len);
  return 0;
}

/* Read one 64×80 raw grayscale frame. */
static int
fte4800_write (int fd, const guint8 *tx, gsize tx_len)
{
  gsize buf_len = 5 + tx_len;
  guint8 *buf = g_malloc0 (buf_len);

  buf[0] = 0xA5;
  buf[1] = (guint8) (tx_len & 0xFF);
  buf[2] = (guint8) ((tx_len >> 8) & 0xFF);
  buf[3] = 0;
  buf[4] = 0;
  if (tx_len)
    memcpy (buf + 5, tx, tx_len);

  ssize_t n = write (fd, buf, buf_len);
  g_free (buf);
  if (n < 0)
    return -errno;
  return ((gsize) n == buf_len) ? 0 : -EIO;
}

/* Trigger one physical FT9368 scan.  The sensor populates its image FIFO
 * asynchronously; ~60 ms is the measured safe integration window. */
static int
fte4800_trigger_capture (int fd)
{
  static const guint8 tx[11] = {
    0x70, 0x07, 0xF8,
    0x00, 0x3B, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x00
  };

  int ret = fte4800_write (fd, tx, sizeof (tx));
  if (ret < 0)
    return ret;
  g_usleep (60 * 1000);
  return 0;
}

static int
fte4800_read_frame (int fd, guint8 *out)
{
  static const guint8 tx[7] = { 0x90, 0x80, 0x14, 0x00, 0x00, 0x00, 0x00 };
  return fte4800_spi_transfer (fd, tx, sizeof (tx), out, FTE4800_RAW_PIXELS);
}

/* Verify sensor identity (retries until chip-ID 0x9368 appears). */
static gboolean
fte4800_read_chip_id (int fd, guint16 *id_out)
{
  static const guint8 tx[7] = { 0x91, 0x80, 0x00, 0x20, 0x00, 0x00, 0x00 };
  guint8 rx[32];

  for (int i = 0; i < 6; i++)
    {
      if (fte4800_spi_transfer (fd, tx, sizeof (tx), rx, sizeof (rx)) == 0)
        {
          guint16 id = ((guint16) rx[0x13] << 8) | rx[0x14];
          if (id == 0x9368)
            {
              if (id_out) *id_out = id;
              return TRUE;
            }
        }
      g_usleep (50 * 1000);
    }
  return FALSE;
}

/* A freshly triggered FT9368 frame is the reliable signal source for
 * this implementation.
 *
 * HARDWARE EVIDENCE: The 0x9180 status register byte[1] reads 0x11 in
 * approximately 100% of polls regardless of whether a finger is present
 * (confirmed by dataset analysis: 1121/1337 polls = 83.8% always-on, with
 * the remaining variation being random noise — not correlated with touch).
 * byte[2] is 0x11 only 5/1337 times total. Neither byte reliably indicates
 * finger presence, so we do NOT use this register for touch detection.
 *
 * RELIABLE APPROACH: After a hardware reset (IOCTL 0x8086), the FT9368
 * image buffer is fully blanked. A subsequent triggered capture returns
 * Var=0.0 when no finger is present, and Var>>threshold when a finger is
 * pressed. This has been confirmed on the physical FT9368 sensor. */
static gboolean
fte4800_image_has_signal (const guint8 *px, gsize n)
{
  return fpi_std_sq_dev (px, n) > FTE4800_TOUCH_VAR_THRESH;
}

static gboolean
fte4800_image_is_good (const guint8 *px, gsize n)
{
  /*
   * Do not impose generic brightness/saturation heuristics here. Real FTE4800
   * captures have a high mean and a large saturated region, while the vendor
   * engine still classifies them as usable. The vendor engine is authoritative
   * for fingerprint quality; this gate only rejects blank/low-contrast frames.
   */
  return fpi_std_sq_dev (px, n) >= FTE4800_ENROLL_MIN_VAR;
}

/* Forward declaration for the blocking capture helper used by the
 * finger-edge detectors below. */
static gboolean
fte4800_capture_frame_blocking (FpiDeviceFte4800 *self, guint8 *frame);

/* Issue a hardware reset and wait for sensor firmware to boot.
 * This is mandatory before reliable finger-absent detection because the
 * FT9368 image buffer retains the last captured frame indefinitely after
 * finger removal — stale data reads as Var>>0 even with no finger present.
 * After reset the buffer is blank; the next trigger returns Var=0 or Var>thresh
 * according to actual sensor state. */
static void
fte4800_hw_reset (FpiDeviceFte4800 *self)
{
  guint8 throwaway[2];

  if (ioctl (self->spi_fd, FTE4800_IOCTL_RESET, 0) < 0)
    fp_warn ("hw-reset ioctl failed: %s", g_strerror (errno));

  /* Kernel driver already waits 350ms for chip auto-boot during IOCTL_RESET.
   * Discard the first post-reset read to clear SPI shift-register residue. */
  fte4800_spi_transfer (self->spi_fd,
                        (const guint8[]) { 0x91, 0x80, 0x00, 0x02, 0x00, 0x00, 0x00 },
                        7, throwaway, sizeof (throwaway));
}

/* WAIT_DOWN: poll with fresh triggered captures until the sensor reports
 * a real contact signal.  Called immediately after fte4800_hw_reset(), so
 * the image buffer is blank and any Var>threshold is a genuine new press. */
static gboolean
fte4800_wait_finger_down (FpiDeviceFte4800 *self,
                          GCancellable *cancel,
                          guint8 *frame)
{
  for (;;)
    {
      if (g_cancellable_is_cancelled (cancel))
        return FALSE;

      /* Trigger + read.  After a reset this reliably returns Var=0 when no
       * finger is present. */
      if (!fte4800_capture_frame_blocking (self, frame))
        {
          g_usleep (FTE4800_POLL_MS * 1000);
          continue;
        }

      if (fte4800_image_has_signal (frame, FTE4800_RAW_PIXELS))
        return TRUE;

      g_usleep (FTE4800_POLL_MS * 1000);
    }
}

/* WAIT_UP: reset the hardware buffer, then poll until a fresh capture
 * returns no signal (Var <= threshold).  The reset is the key step: without
 * it the FT9368 returns stale finger-image data for an indefinite time after
 * the finger is lifted, making release detection impossible via variance alone.
 *
 * This wait is intentionally unbounded and only completes on confirmed release
 * or cancellation. */
static gboolean
fte4800_wait_finger_up (FpiDeviceFte4800 *self,
                        GCancellable *cancel,
                        guint8 *frame)
{
  for (;;)
    {
      if (g_cancellable_is_cancelled (cancel))
        return FALSE;

      /* Reset the hardware buffer on every check so finger absence reliably
       * produces a blank frame. Without reset between checks, FT9368's internal
       * SRAM retains the prior frame if the finger was still pressed during
       * the previous capture. */
      fte4800_hw_reset (self);

      if (!fte4800_capture_frame_blocking (self, frame))
        {
          g_usleep (FTE4800_POLL_MS * 1000);
          continue;
        }

      if (!fte4800_image_has_signal (frame, FTE4800_RAW_PIXELS))
        {
          /* No signal — finger is absent. Report NONE + NEEDED now that
           * finger is confirmed physically released. */
          fpi_device_report_finger_status (FP_DEVICE (self),
                                           FP_FINGER_STATUS_NONE | FP_FINGER_STATUS_NEEDED);
          return TRUE;
        }

      /* Signal still present — user is still holding the finger. */
      fpi_device_report_finger_status (FP_DEVICE (self),
                                       FP_FINGER_STATUS_PRESENT);
      g_usleep (FTE4800_POLL_MS * 1000);
    }
}

/* --------------------------------------------------------------------------
 * Vendor template storage in FpPrint
 *
 * FTV1 layout:
 *   magic[4] + vendor_template_size_le32[4] + opaque vendor blob
 * The vendor engine owns the internal fingerprint representation; libfprint
 * stores it without interpreting or rewriting the template.
 * -------------------------------------------------------------------------- */

static gboolean
fte4800_engine_available (void)
{
  const gchar *path = g_getenv ("FTE4800_ENGINE_DLL");

  return path && *path
         ? g_file_test (path, G_FILE_TEST_IS_REGULAR)
         : g_file_test (FTE4800_VENDOR_DLL, G_FILE_TEST_IS_REGULAR);
}

static const gchar *
fte4800_engine_path (void)
{
  const gchar *path = g_getenv ("FTE4800_ENGINE_DLL");
  return path && *path ? path : FTE4800_VENDOR_DLL;
}

static gboolean
fte4800_set_print_template (FpPrint *print,
                            const guint8 *template,
                            gsize template_len)
{
  gsize payload;
  guint8 *buf;
  GVariant *data;

  if (!template || template_len == 0 || template_len > FTE4800_VENDOR_MAX_TEMPLATE)
    return FALSE;

  payload = FTE4800_VENDOR_HEADER + template_len;
  buf = g_malloc (payload);
  memcpy (buf, FTE4800_VENDOR_MAGIC, 4);
  buf[4] = (guint8) (template_len & 0xff);
  buf[5] = (guint8) ((template_len >> 8) & 0xff);
  buf[6] = (guint8) ((template_len >> 16) & 0xff);
  buf[7] = (guint8) ((template_len >> 24) & 0xff);
  memcpy (buf + FTE4800_VENDOR_HEADER, template, template_len);

  data = g_variant_new_fixed_array (G_VARIANT_TYPE_BYTE,
                                     buf, payload, sizeof (guint8));
  fpi_print_set_type (print, FPI_PRINT_RAW);
  g_object_set (print, "fpi-data", data, NULL);
  g_free (buf);
  return TRUE;
}

static guint8 *
fte4800_get_print_template (FpPrint *print, gsize *template_len_out)
{
  GVariant *data = NULL;
  const guint8 *raw;
  gsize n = 0;
  gsize len;

  if (template_len_out)
    *template_len_out = 0;

  g_object_get (print, "fpi-data", &data, NULL);
  if (!data)
    return NULL;

  raw = g_variant_get_fixed_array (data, &n, sizeof (guint8));
  if (!raw || n < FTE4800_VENDOR_HEADER ||
      memcmp (raw, FTE4800_VENDOR_MAGIC, 4) != 0)
    {
      g_variant_unref (data);
      return NULL;
    }

  len = (gsize) raw[4] |
        ((gsize) raw[5] << 8) |
        ((gsize) raw[6] << 16) |
        ((gsize) raw[7] << 24);

  if (len == 0 || len > FTE4800_VENDOR_MAX_TEMPLATE ||
      n != FTE4800_VENDOR_HEADER + len)
    {
      g_variant_unref (data);
      return NULL;
    }

  guint8 *out = g_memdup2 (raw + FTE4800_VENDOR_HEADER, len);
  g_variant_unref (data);
  if (template_len_out)
    *template_len_out = len;
  return out;
}

/* --------------------------------------------------------------------------
 * Blocking capture helper (runs in a GTask worker thread)
 *
 * Triggers a physical scan, reads the resulting frame, and accepts it only
 * when the frame has sufficient contact contrast.
 * -------------------------------------------------------------------------- */
static gboolean
fte4800_capture_frame_blocking (FpiDeviceFte4800 *self, guint8 *frame)
{
  if (fte4800_trigger_capture (self->spi_fd) != 0)
    return FALSE;

  return fte4800_read_frame (self->spi_fd, frame) == 0;
}

/* --------------------------------------------------------------------------
 * Open / Close / Activate / Deactivate (standard FpImageDevice plumbing)
 * -------------------------------------------------------------------------- */
static void
fte4800_open (FpImageDevice *imgdev)
{
  FpiDeviceFte4800 *self = FPI_DEVICE_FTE4800 (imgdev);
  guint16 chip_id = 0;
  GError *err = NULL;
  const gchar *path;
  int fd;

  G_DEBUG_HERE ();

  path = fpi_device_get_udev_data (FP_DEVICE (imgdev), FPI_DEVICE_UDEV_SUBTYPE_MISC);
  if (!path)
    path = "/dev/focal_moh_spi";

  fd = open (path, O_RDWR | O_CLOEXEC);
  if (fd < 0)
    {
      err = fpi_device_error_new_msg (FP_DEVICE_ERROR_GENERAL,
                                      "open(%s): %s", path, g_strerror (errno));
      fpi_image_device_open_complete (imgdev, err);
      return;
    }

  if (ioctl (fd, FTE4800_IOCTL_RESET, 0) < 0)
    fp_warn ("Reset ioctl failed: %s", g_strerror (errno));

  /* Discard the first post-reset read: FT9368 can return SPI shift-register
   * residue before application firmware has produced a stable response. */
  {
    guint8 throwaway[2];
    if (fte4800_spi_transfer (fd,
                              (const guint8[]) { 0x91, 0x80, 0x00, 0x02, 0x00, 0x00, 0x00 },
                              7, throwaway, sizeof (throwaway)) != 0)
      fp_warn ("post-reset throwaway read failed: %s", g_strerror (errno));
  }

  if (!fte4800_read_chip_id (fd, &chip_id))
    {
      close (fd);
      err = fpi_device_error_new_msg (FP_DEVICE_ERROR_NOT_SUPPORTED,
                                      "%s: FT9368 not detected", path);
      fpi_image_device_open_complete (imgdev, err);
      return;
    }

  if (!fte4800_engine_available ())
    {
      close (fd);
      err = fpi_device_error_new_msg (
        FP_DEVICE_ERROR_NOT_SUPPORTED,
        "FocalTech vendor engine not found at %s (set FTE4800_ENGINE_DLL to override)",
        fte4800_engine_path ());
      fpi_image_device_open_complete (imgdev, err);
      return;
    }

  if (ft_engine_open (fte4800_engine_path ()) != 0)
    {
      close (fd);
      err = fpi_device_error_new_msg (
        FP_DEVICE_ERROR_GENERAL,
        "FocalTech vendor engine failed to initialize");
      fpi_image_device_open_complete (imgdev, err);
      return;
    }

  fp_info ("FocalTech FT9368 (0x%04x) at %s; vendor engine ready", chip_id, path);
  self->spi_fd = fd;

  fpi_image_device_open_complete (imgdev, NULL);
}

static void
fte4800_close (FpImageDevice *imgdev)
{
  FpiDeviceFte4800 *self = FPI_DEVICE_FTE4800 (imgdev);

  G_DEBUG_HERE ();

  if (self->spi_fd >= 0)
    {
      close (self->spi_fd);
      self->spi_fd = -1;
    }
  fpi_image_device_close_complete (imgdev, NULL);
}

static void
fte4800_activate (FpImageDevice *imgdev)
{
  G_DEBUG_HERE ();
  FPI_DEVICE_FTE4800 (imgdev)->deactivating = FALSE;
  fpi_image_device_activate_complete (imgdev, NULL);
}

static void
fte4800_deactivate (FpImageDevice *imgdev)
{
  G_DEBUG_HERE ();
  FPI_DEVICE_FTE4800 (imgdev)->deactivating = TRUE;
  fpi_image_device_deactivate_complete (imgdev, NULL);
}

static void
fte4800_change_state (FpImageDevice *imgdev, FpiImageDeviceState state)
{
  /* Enrollment and verification are implemented by the driver because the
   * FT9368 uses the native FocalTech WinBio engine. */
  G_DEBUG_HERE ();
}

/* --------------------------------------------------------------------------
 * Custom Enroll
 * -------------------------------------------------------------------------- */
typedef struct {
  FpiDeviceFte4800 *self;
  FpPrint          *enroll_print;
} EnrollData;

static void
fte4800_enroll_thread (GTask *task, gpointer src,
                       gpointer task_data, GCancellable *cancel)
{
  EnrollData *ed = task_data;
  FpiDeviceFte4800 *self = ed->self;
  guint8 frame[FTE4800_RAW_PIXELS];

  ft_engine_enroll_begin ();
  fte4800_hw_reset (self);

  fpi_device_report_finger_status (FP_DEVICE (self),
                                   FP_FINGER_STATUS_NONE | FP_FINGER_STATUS_NEEDED);

  while (self->enroll_count < FTE4800_ENROLL_STAGES)
    {
      if (g_task_return_error_if_cancelled (task))
        return;

      if (!fte4800_wait_finger_down (self, cancel, frame))
        {
          g_task_return_error_if_cancelled (task);
          return;
        }

      fpi_device_report_finger_status (FP_DEVICE (self), FP_FINGER_STATUS_PRESENT);

      if (!fte4800_image_is_good (frame, FTE4800_RAW_PIXELS))
        {
          GError *retry = fpi_device_retry_new_msg (
            FP_DEVICE_RETRY_GENERAL,
            "Scan quality is too low. Keep finger flat and press gently.");
          fpi_device_enroll_progress (FP_DEVICE (self),
                                      self->enroll_count, NULL, retry);

          if (!fte4800_wait_finger_up (self, cancel, frame))
            {
              g_task_return_error_if_cancelled (task);
              return;
            }
          continue;
        }

      guint32 accept_hr = ft_engine_accept (frame, FTE4800_RAW_WIDTH,
                                            FTE4800_RAW_HEIGHT, 4);
      if (accept_hr != 0)
        {
          fp_warn ("FocalTech engine rejected enrollment capture: 0x%08x",
                   accept_hr);
          GError *retry = fpi_device_retry_new_msg (
            FP_DEVICE_RETRY_GENERAL,
            "Fingerprint capture rejected. Reposition your finger and try again.");
          fpi_device_enroll_progress (FP_DEVICE (self),
                                      self->enroll_count, NULL, retry);

          if (!fte4800_wait_finger_up (self, cancel, frame))
            {
              g_task_return_error_if_cancelled (task);
              return;
            }
          continue;
        }

      gint update = ft_engine_enroll_update ();
      if (update == 2)
        {
          fp_dbg ("FocalTech engine rejected enrollment sample");
          GError *retry = fpi_device_retry_new_msg (
            FP_DEVICE_RETRY_GENERAL,
            "Fingerprint sample was too similar or unsuitable. Lift and try again.");
          fpi_device_enroll_progress (FP_DEVICE (self),
                                      self->enroll_count, NULL, retry);
        }
      else
        {
          self->enroll_count++;
          fp_dbg ("Vendor enrollment sample %d/%d",
                  self->enroll_count, FTE4800_ENROLL_STAGES);
          fpi_device_enroll_progress (FP_DEVICE (self),
                                      self->enroll_count, NULL, NULL);
        }

      if (update == 0)
        {
          if (!fte4800_wait_finger_up (self, cancel, frame))
            {
              g_task_return_error_if_cancelled (task);
              return;
            }
          break;
        }

      if (!fte4800_wait_finger_up (self, cancel, frame))
        {
          g_task_return_error_if_cancelled (task);
          return;
        }
    }

  guint8 *vendor_template = NULL;
  size_t vendor_template_len = 0;
  if (ft_engine_enroll_commit (&vendor_template, &vendor_template_len) != 0 ||
      !fte4800_set_print_template (ed->enroll_print,
                                    vendor_template, vendor_template_len))
    {
      g_free (vendor_template);
      g_task_return_new_error (
        task, G_IO_ERROR, G_IO_ERROR_FAILED,
        "FocalTech vendor enrollment could not be committed");
      return;
    }

  g_free (vendor_template);
  g_task_return_boolean (task, TRUE);
}

static void
fte4800_enroll_done (GObject *src, GAsyncResult *res, gpointer task_data)
{
  FpDevice   *dev = FP_DEVICE (src);
  EnrollData *ed  = task_data;
  GError     *err = NULL;

  if (!g_task_propagate_boolean (G_TASK (res), &err))
    fpi_device_enroll_complete (dev, NULL, err);
  else
    {
      fp_info ("Enrollment complete using native FocalTech vendor template");
      fpi_device_enroll_complete (dev, g_object_ref (ed->enroll_print), NULL);
    }

  g_object_unref (ed->enroll_print);
  g_free (ed);
}

static void
fte4800_enroll (FpDevice *dev)
{
  FpiDeviceFte4800 *self = FPI_DEVICE_FTE4800 (dev);
  FpPrint *enroll_print = NULL;

  fpi_device_get_enroll_data (dev, &enroll_print);

  self->enroll_count = 0;

  EnrollData *ed = g_new0 (EnrollData, 1);
  ed->self = self;
  ed->enroll_print = g_object_ref (enroll_print);

  GTask *task = g_task_new (dev, fpi_device_get_cancellable (dev),
                            fte4800_enroll_done, ed);
  g_task_set_task_data (task, ed, NULL);
  g_task_run_in_thread (task, fte4800_enroll_thread);
  g_object_unref (task);
}

/* --------------------------------------------------------------------------
 * Custom Verify
 * -------------------------------------------------------------------------- */
typedef struct {
  FpiDeviceFte4800 *self;
  FpPrint          *verify_print;
} VerifyData;

static void
fte4800_verify_thread (GTask *task, gpointer src,
                       gpointer task_data, GCancellable *cancel)
{
  VerifyData *vd = task_data;
  FpiDeviceFte4800 *self = vd->self;
  guint8 frame[FTE4800_RAW_PIXELS];
  gsize template_len = 0;
  g_autofree guint8 *vendor_template =
    fte4800_get_print_template (vd->verify_print, &template_len);

  if (!vendor_template)
    {
      g_task_return_new_error (
        task, G_IO_ERROR, G_IO_ERROR_INVALID_DATA,
        "Stored print is not an FTE4800 vendor template");
      return;
    }

  if (g_task_return_error_if_cancelled (task))
    return;

  fte4800_hw_reset (self);
  fpi_device_report_finger_status (
    FP_DEVICE (self), FP_FINGER_STATUS_NONE | FP_FINGER_STATUS_NEEDED);

  if (!fte4800_wait_finger_down (self, cancel, frame))
    {
      g_task_return_error_if_cancelled (task);
      return;
    }

  fpi_device_report_finger_status (
    FP_DEVICE (self), FP_FINGER_STATUS_PRESENT);

  guint32 accept_hr = ft_engine_accept (frame, FTE4800_RAW_WIDTH,
                                         FTE4800_RAW_HEIGHT, 1);
  if (accept_hr != 0)
    {
      fp_warn ("FocalTech engine rejected verification capture: 0x%08x",
               accept_hr);
      g_task_return_new_error (
        task, G_IO_ERROR, G_IO_ERROR_FAILED,
        "Fingerprint capture rejected by FocalTech engine");
      return;
    }

  gboolean match = ft_engine_verify (vendor_template, template_len);
  if (!fte4800_wait_finger_up (self, cancel, frame))
    {
      g_task_return_error_if_cancelled (task);
      return;
    }

  g_task_return_boolean (task, match);
}

static void
fte4800_verify_done (GObject *src, GAsyncResult *res, gpointer task_data)
{
  FpDevice   *dev = FP_DEVICE (src);
  VerifyData *vd  = task_data;
  GError     *err = NULL;
  gboolean match = g_task_propagate_boolean (G_TASK (res), &err);

  if (err)
    fpi_device_verify_complete (dev, err);
  else
    {
      fp_info ("Verify %s via native FocalTech vendor engine",
               match ? "MATCH" : "NO-MATCH");
      fpi_device_verify_report (
        dev, match ? FPI_MATCH_SUCCESS : FPI_MATCH_FAIL, NULL, NULL);
      fpi_device_verify_complete (dev, NULL);
    }

  g_object_unref (vd->verify_print);
  g_free (vd);
}

static void
fte4800_verify (FpDevice *dev)
{
  FpPrint *print = NULL;
  fpi_device_get_verify_data (dev, &print);

  VerifyData *vd = g_new0 (VerifyData, 1);
  vd->self = FPI_DEVICE_FTE4800 (dev);
  vd->verify_print = g_object_ref (print);

  GTask *task = g_task_new (dev, fpi_device_get_cancellable (dev),
                            fte4800_verify_done, vd);
  g_task_set_task_data (task, vd, NULL);
  g_task_run_in_thread (task, fte4800_verify_thread);
  g_object_unref (task);
}

/* --------------------------------------------------------------------------
 * GObject lifecycle
 * -------------------------------------------------------------------------- */
static void
fpi_device_fte4800_init (FpiDeviceFte4800 *self)
{
  self->spi_fd      = -1;
  self->deactivating = FALSE;
}

static void
fpi_device_fte4800_finalize (GObject *obj)
{
  FpiDeviceFte4800 *self = FPI_DEVICE_FTE4800 (obj);

  if (self->spi_fd >= 0)
    {
      close (self->spi_fd);
      self->spi_fd = -1;
    }
  G_OBJECT_CLASS (fpi_device_fte4800_parent_class)->finalize (obj);
}

static void
fpi_device_fte4800_class_init (FpiDeviceFte4800Class *klass)
{
  GObjectClass       *obj_class = G_OBJECT_CLASS (klass);
  FpDeviceClass      *dev_class = FP_DEVICE_CLASS (klass);
  FpImageDeviceClass *img_class = FP_IMAGE_DEVICE_CLASS (klass);

  obj_class->finalize = fpi_device_fte4800_finalize;

  dev_class->id             = "fte4800";
  dev_class->full_name      = "FocalTech FTE4800 / FT9368 Fingerprint Sensor";
  dev_class->type           = FP_DEVICE_TYPE_UDEV;
  dev_class->id_table       = fte4800_id_table;
  dev_class->scan_type      = FP_SCAN_TYPE_PRESS;
  dev_class->nr_enroll_stages = FTE4800_ENROLL_STAGES;

  /* Driver-specific matching for the FT9368's 64x80 image geometry.
   * Identify is intentionally NOT registered here: fprintd uses
   * FP_DEVICE_FEATURE_IDENTIFY to run a silent duplicate-check before
   * enrollment.  Advertising this feature causes fprintd to silently wait
   * for a touch+lift cycle before showing any "Place your finger" prompt,
   * making the enrollment UI appear frozen.  Verify is sufficient for the
   * normal PAM/polkit use-case.
   *
   * IMPORTANT: FpImageDevice base class sets identify = fp_image_device_start_capture_action
   * and calls fpi_device_class_auto_initialize_features() which sets FP_DEVICE_FEATURE_IDENTIFY
   * because identify is non-NULL at that point.  We must explicitly NULL the vfunc AND
   * clear the feature bit here (our class_init runs after the parent's). */
  dev_class->enroll   = fte4800_enroll;
  dev_class->verify   = fte4800_verify;
  dev_class->identify = NULL;    /* clear parent's fp_image_device_start_capture_action */
  dev_class->capture  = NULL;    /* not used — we run our own thread */
  dev_class->features &= ~(FP_DEVICE_FEATURE_IDENTIFY | FP_DEVICE_FEATURE_CAPTURE);

  /* The FT9368 is a passive always-on sensor; there is no thermal throttle
   * risk during the 15-stage enrollment loop.  Without this flag the default
   * libfprint temperature model fires after ~20 s and returns
   * FP_DEVICE_ERROR_BUSY ("enroll-disconnected"). */
  dev_class->temp_hot_seconds = -1;

  /* Standard image-device plumbing for open/close/activate/deactivate. */
  img_class->img_open     = fte4800_open;
  img_class->img_close    = fte4800_close;
  img_class->activate     = fte4800_activate;
  img_class->deactivate   = fte4800_deactivate;
  img_class->change_state = fte4800_change_state;
  img_class->img_width    = FTE4800_RAW_WIDTH;
  img_class->img_height   = FTE4800_RAW_HEIGHT;
}
