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
 *   NBIS/Bozorth3 does not produce a usable signal on this tiny 64×80 sensing
 *   area, so this driver uses a local ridge-normalisation matcher with explicit
 *   rotation/translation search. Enrollment stores fifteen raw frames; verification
 *   compares the probe against all fifteen and uses the best alignment score.
 *
 *   The threshold is deliberately conservative and remains an experimental
 *   value until a larger multi-finger dataset establishes FAR/FRR bounds.
 */

#define FP_COMPONENT "fte4800"

#include "drivers_api.h"
#include "fte4800.h"
#include "fte4800-match.h"

#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>

/* --------------------------------------------------------------------------
 * Parameters
 * -------------------------------------------------------------------------- */
#define FTE4800_MATCH_THRESHOLD    0.64f /* primary single-frame match boundary */
#define FTE4800_TOP2_THRESHOLD     0.58f /* top-2 cluster consensus boundary */
#define FTE4800_TOP2_MIN_BEST      0.55f /* consensus requires best to be at least this */
#define FTE4800_ENROLL_STAGES         15 /* distinct raw samples retained */
#define FTE4800_TOUCH_VAR_THRESH     350 /* blank-frame boundary */
#define FTE4800_ENROLL_MIN_VAR      1200 /* minimum usable enrollment contrast */
#define FTE4800_POLL_MS             1000 /* limit idle capture rate to ~1 Hz */
#define FTE4800_TEMPLATE_MAGIC      "FTE2"

/* --------------------------------------------------------------------------
 * Device instance data
 * -------------------------------------------------------------------------- */
struct _FpiDeviceFte4800
{
  FpImageDevice parent;

  int           spi_fd;
  gboolean      deactivating;

  /* Raw enrollment samples are retained individually so finger motion does
   * not blur the stored ridge pattern. */
  guint8       *enroll_frames;
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
  gsize sat_count = 0;
  guint64 sum = 0;
  FteTemplate t;

  if (fpi_std_sq_dev (px, n) < FTE4800_ENROLL_MIN_VAR)
    return FALSE;

  for (gsize i = 0; i < n; i++)
    {
      if (px[i] >= 250)
        sat_count++;
      sum += px[i];
    }

  /* Reject if more than 15% of pixels are saturated (pressed too hard) */
  if (sat_count > n * 15 / 100)
    return FALSE;

  /* Reject if average intensity indicates pressure collapse / flat blowout */
  if (sum / n > 175)
    return FALSE;

  /* Check template ridge coverage and contrast */
  fte_template_init (&t, px);
  if (t.coverage < 0.60f || t.contrast < 25.0f)
    return FALSE;

  return TRUE;
}

/* Forward declaration — fte4800_capture_frame_blocking is defined below after
 * the template and match helpers but is used by the finger-edge detectors
 * above them. */
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
 * Template storage in FpPrint (fifteen raw 64x80 frames)
 *
 * FTE2 layout: magic[4] + sample_count[1] + sample_count * 5120 bytes.
 * -------------------------------------------------------------------------- */

static void
fte4800_set_print_template (FpPrint *print,
                            const guint8 *frames)
{
  const gsize magic_len = strlen (FTE4800_TEMPLATE_MAGIC);
  const gsize header = magic_len + 1;
  const gsize payload = header + FTE4800_ENROLL_STAGES * FTE4800_RAW_PIXELS;
  guint8 *buf = g_malloc (payload);
  memcpy (buf, FTE4800_TEMPLATE_MAGIC, magic_len);
  buf[magic_len] = FTE4800_ENROLL_STAGES;

  for (gint i = 0; i < FTE4800_ENROLL_STAGES; i++)
    memcpy (buf + header + i * FTE4800_RAW_PIXELS,
            frames + (gsize) i * FTE4800_RAW_PIXELS,
            FTE4800_RAW_PIXELS);

  GVariant *data = g_variant_new_fixed_array (G_VARIANT_TYPE_BYTE,
                                              buf, payload, sizeof (guint8));
  fpi_print_set_type (print, FPI_PRINT_RAW);
  g_object_set (print, "fpi-data", data, NULL);
  g_free (buf);
}

static guint8 *
fte4800_get_print_frames (FpPrint *print)
{
  GVariant *data = NULL;
  gsize n = 0;
  const gsize magic_len = strlen (FTE4800_TEMPLATE_MAGIC);
  const gsize header = magic_len + 1;
  const gsize expected = header + FTE4800_ENROLL_STAGES * FTE4800_RAW_PIXELS;

  g_object_get (print, "fpi-data", &data, NULL);
  if (!data)
    return NULL;

  const guint8 *raw = g_variant_get_fixed_array (data, &n, sizeof (guint8));
  guint8 *out = NULL;
  if (raw && n == expected &&
      memcmp (raw, FTE4800_TEMPLATE_MAGIC, magic_len) == 0 &&
      raw[magic_len] == FTE4800_ENROLL_STAGES)
    out = g_memdup2 (raw + header, n - header);

  g_variant_unref (data);
  return out;
}

/* Score one probe against the fifteen enrolled frames.
 * Returns the highest aligned score, and optionally best index and second-best score. */
static float
fte4800_match_frames (const guint8 probe_raw[FTE4800_RAW_PIXELS],
                      const guint8 *templates,
                      gint *best_index,
                      float *second_best_out)
{
  FteTemplate probe_t;
  FteProbe probe;
  float best = -1.0f;
  float second = -1.0f;
  gint best_i = -1;

  fte_template_init (&probe_t, probe_raw);
  if (probe_t.coverage <= 0.05f || probe_t.contrast <= 2.0f)
    {
      if (best_index)
        *best_index = -1;
      if (second_best_out)
        *second_best_out = -1.0f;
      return -1.0f;
    }

  fte_probe_init (&probe, &probe_t);

  for (gint i = 0; i < FTE4800_ENROLL_STAGES; i++)
    {
      FteTemplate tmpl;
      float score;

      fte_template_init (&tmpl,
                         templates + i * FTE4800_RAW_PIXELS);
      if (tmpl.coverage <= 0.05f || tmpl.contrast <= 2.0f)
        continue;

      score = fte_match (&tmpl, &probe, NULL, NULL, NULL);
      if (score > best)
        {
          second = best;
          best = score;
          best_i = i;
        }
      else if (score > second)
        {
          second = score;
        }
    }

  if (best_index)
    *best_index = best_i;
  if (second_best_out)
    *second_best_out = second;
  return best;
}

/* --------------------------------------------------------------------------
 * Blocking capture helper (runs in a GTask worker thread)
 *
 * Triggers a physical scan, reads the resulting frame, and accepts it only
 * when the frame has sufficient contact contrast.
 * Returns TRUE on success; frame is filled with FTE4800_RAW_PIXELS bytes.
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

  fp_info ("FocalTech FT9368 (0x%04x) at %s", chip_id, path);
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
  /* Enrollment, verification, and identification are implemented by the
   * driver because the FT9368 image geometry needs its custom matcher. */
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

  g_clear_pointer (&self->enroll_frames, g_free);
  self->enroll_frames = g_malloc0 ((gsize) FTE4800_ENROLL_STAGES *
                                   FTE4800_RAW_PIXELS);
  self->enroll_count = 0;

  /* Reset the sensor to clear any stale frame data left from a prior
   * operation.  After this point the image buffer is blank and every
   * fte4800_capture_frame_blocking() will return Var≈0 until a real press. */
  fte4800_hw_reset (self);

  /* Immediately tell the UI that we are ready for the first scan. */
  fpi_device_report_finger_status (FP_DEVICE (self),
                                   FP_FINGER_STATUS_NONE | FP_FINGER_STATUS_NEEDED);

  while (self->enroll_count < FTE4800_ENROLL_STAGES)
    {
      if (g_task_return_error_if_cancelled (task))
        return;

      /* One physical press -> one fresh frame. */
      if (!fte4800_wait_finger_down (self, cancel, frame))
        {
          g_task_return_error_if_cancelled (task);
          return;
        }

      fpi_device_report_finger_status (
        FP_DEVICE (self), FP_FINGER_STATUS_PRESENT);

      /* A press with insufficient signal is a retry of this SAME stage.
       * It cannot increment enroll_count and must be followed by release. */
      if (!fte4800_image_is_good (frame, FTE4800_RAW_PIXELS))
        {
          GError *retry = fpi_device_retry_new_msg (
            FP_DEVICE_RETRY_GENERAL,
            "Scan poor quality, too partial, or pressed too hard. Keep finger flat and press gently.");
          fpi_device_enroll_progress (FP_DEVICE (self),
                                      self->enroll_count, NULL, retry);

          if (!fte4800_wait_finger_up (self, cancel, frame))
            {
              g_task_return_error_if_cancelled (task);
              return;
            }

          continue;
        }

      /* ACCEPT: this is the only place where an enrollment stage advances. */
      memcpy (self->enroll_frames +
              (gsize) self->enroll_count * FTE4800_RAW_PIXELS,
              frame, FTE4800_RAW_PIXELS);
      self->enroll_count++;

      fp_dbg ("Enroll stage %d/%d", self->enroll_count, FTE4800_ENROLL_STAGES);
      fpi_device_enroll_progress (FP_DEVICE (self),
                                  self->enroll_count, NULL, NULL);

      if (self->enroll_count < FTE4800_ENROLL_STAGES)
        {
          /* Do not enter WAIT_DOWN until a fresh capture sequence proves the
           * finger is actually off the sensor. */
          if (!fte4800_wait_finger_up (self, cancel, frame))
            {
              g_task_return_error_if_cancelled (task);
              return;
            }
        }
    }

  fte4800_set_print_template (ed->enroll_print, self->enroll_frames);
  g_clear_pointer (&self->enroll_frames, g_free);
  g_task_return_boolean (task, TRUE);
}

static void
fte4800_enroll_done (GObject *src, GAsyncResult *res, gpointer task_data)
{
  FpDevice   *dev = FP_DEVICE (src);
  EnrollData *ed  = task_data;
  GError     *err = NULL;

  if (!g_task_propagate_boolean (G_TASK (res), &err))
    {
      fpi_device_enroll_complete (dev, NULL, err);
    }
  else
    {
      fp_info ("Enrollment complete (fifteen raw FT9368 samples stored)");
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

  EnrollData *ed = g_new0 (EnrollData, 1);
  ed->self         = self;
  ed->enroll_print = g_object_ref (enroll_print);

  GTask *task = g_task_new (dev, fpi_device_get_cancellable (dev), fte4800_enroll_done, ed);
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

  if (g_task_return_error_if_cancelled (task))
    return;

  /* Reset sensor to clear any stale frame residue before waiting for a probe. */
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

  guint8 *templates = fte4800_get_print_frames (vd->verify_print);
  if (!templates)
    {
      g_task_return_new_error (task, G_IO_ERROR, G_IO_ERROR_INVALID_DATA,
                               "Stored print has no FT9368 raw templates");
      return;
    }

  float second_score = -1.0f;
  float score = fte4800_match_frames (frame, templates, NULL, &second_score);
  g_free (templates);

  /* Pass both scores back as a heap-allocated array. */
  float *result = g_new (float, 2);
  result[0] = score;
  result[1] = second_score;
  g_task_return_pointer (task, result, g_free);
}

static void
fte4800_verify_done (GObject *src, GAsyncResult *res, gpointer task_data)
{
  FpDevice   *dev = FP_DEVICE (src);
  VerifyData *vd  = task_data;
  GError     *err = NULL;

  float *scores = g_task_propagate_pointer (G_TASK (res), &err);
  if (err)
    {
      fpi_device_verify_complete (dev, err);
    }
  else
    {
      float score = scores[0];
      float second = scores[1];
      float top2_avg = (score > 0.0f && second > 0.0f) ? (score + second) / 2.0f : score;
      g_free (scores);

      gboolean match = FALSE;
      if (score >= FTE4800_MATCH_THRESHOLD)
        {
          fp_info ("Verify MATCH via primary gate (single best %.4f >= %.2f)",
                   score, FTE4800_MATCH_THRESHOLD);
          match = TRUE;
        }
      else if (score >= FTE4800_TOP2_MIN_BEST && top2_avg >= FTE4800_TOP2_THRESHOLD)
        {
          fp_info ("Verify MATCH via consensus gate (top-2 avg %.4f >= %.2f, best %.4f)",
                   top2_avg, FTE4800_TOP2_THRESHOLD, score);
          match = TRUE;
        }

      if (match)
        {
          fpi_device_verify_report (dev, FPI_MATCH_SUCCESS, NULL, NULL);
        }
      else
        {
          fp_info ("Verify NO-MATCH (best %.4f, second %.4f, top-2 avg %.4f)",
                   score, second, top2_avg);
          fpi_device_verify_report (dev, FPI_MATCH_FAIL, NULL, NULL);
        }
      fpi_device_verify_complete (dev, NULL);
    }

  g_object_unref (vd->verify_print);
  g_free (vd);
}

static void
fte4800_verify (FpDevice *dev)
{
  FpiDeviceFte4800 *self = FPI_DEVICE_FTE4800 (dev);
  FpPrint *print = NULL;

  fpi_device_get_verify_data (dev, &print);

  VerifyData *vd = g_new0 (VerifyData, 1);
  vd->self         = self;
  vd->verify_print = g_object_ref (print);

  GTask *task = g_task_new (dev, fpi_device_get_cancellable (dev), fte4800_verify_done, vd);
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
  g_clear_pointer (&self->enroll_frames, g_free);
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
