from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "focal_spi.c"

def function_bounds(text, signature):
    start = text.find(signature)
    if start < 0:
        raise RuntimeError(f"missing signature: {signature}")
    brace = text.find("{", start)
    if brace < 0:
        raise RuntimeError(f"missing body: {signature}")
    depth = 0
    for i in range(brace, len(text)):
        ch = text[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                if end < len(text) and text[end] == "\n":
                    end += 1
                return start, end
    raise RuntimeError(f"unbalanced body: {signature}")

def replace_function(text, signature, replacement):
    start, end = function_bounds(text, signature)
    return text[:start] + replacement + text[end:]

def remove_function(text, signature):
    return replace_function(text, signature, "")

s = SRC.read_text()
for sig in (
    "static int focal_capture_native_frame",
    "static int focal_compat_read16",
):
    s = remove_function(s, sig)

s = replace_function(s, "static int focal_compat_read8", """static int focal_compat_read8(struct focal_fp_data *data,
                                  u8 reg, size_t rx_len, u8 *out)
{
    u8 tx[FTE4800_INFO_HEADER_BYTES + FTE4800_INFO_PAYLOAD_BYTES] = {
        FTE4800_INFO_REG, FTE4800_INFO_FLAG, 0x00,
        FTE4800_INFO_PAYLOAD_BYTES, 0x00, 0x00, 0x00,
    };
    u8 rx[FTE4800_INFO_HEADER_BYTES + FTE4800_INFO_PAYLOAD_BYTES] = { 0 };
    struct spi_transfer xfer = {
        .tx_buf = tx,
        .rx_buf = rx,
        .len = sizeof(tx),
    };
    struct spi_message message;
    int ret;

    if (reg != FTE4800_INFO_REG || rx_len != FTE4800_INFO_PAYLOAD_BYTES)
        return -EOPNOTSUPP;

    spi_message_init(&message);
    spi_message_add_tail(&xfer, &message);
    ret = spi_sync(data->spi, &message);
    if (ret)
        return ret;

    if (rx[FTE4800_INFO_HEADER_BYTES + FTE4800_INFO_CHIP_OFFSET] !=
            (FTE4800_CHIP_ID >> 8) ||
        rx[FTE4800_INFO_HEADER_BYTES + FTE4800_INFO_CHIP_OFFSET + 1] !=
            (FTE4800_CHIP_ID & 0xff))
        return -ENODEV;

    memcpy(out, rx + FTE4800_INFO_HEADER_BYTES,
           FTE4800_INFO_PAYLOAD_BYTES);
    return 0;
}
""")

s = replace_function(s, "static int focal_compat_write", """static int focal_compat_write(struct focal_fp_data *data,
                                 const u8 *buf, size_t len)
{
    return -EOPNOTSUPP;
}
""")
old_alloc = """    data->wr_buf = devm_kzalloc(&spi->dev, MAX_BUFF_SIZE, GFP_KERNEL);
    data->rd_buf = devm_kzalloc(&spi->dev, MAX_BUFF_SIZE, GFP_KERNEL);
    data->sensor_init_data = devm_kzalloc(&spi->dev, MAX_BUFF_SIZE, GFP_KERNEL);
    data->native_tx = devm_kzalloc(&spi->dev,
                           FTE4800_IMAGE_HEADER_BYTES + FTE4800_NATIVE_IMAGE_BYTES,
                           GFP_KERNEL);
    data->native_rx = devm_kzalloc(&spi->dev,
                           FTE4800_IMAGE_HEADER_BYTES + FTE4800_NATIVE_IMAGE_BYTES,
                           GFP_KERNEL);
    data->compat_frame = devm_kzalloc(&spi->dev, FTE4800_COMPAT_IMAGE_BYTES,
                         GFP_KERNEL);
    if (!data->wr_buf || !data->rd_buf || !data->sensor_init_data ||
        !data->native_tx || !data->native_rx || !data->compat_frame)
        return -ENOMEM;
"""
new_alloc = """    data->wr_buf = devm_kzalloc(&spi->dev, MAX_BUFF_SIZE, GFP_KERNEL);
    data->rd_buf = devm_kzalloc(&spi->dev, FTE4800_INFO_PAYLOAD_BYTES, GFP_KERNEL);
    if (!data->wr_buf || !data->rd_buf)
        return -ENOMEM;
"""
if s.count(old_alloc) != 1:
    raise RuntimeError("allocation block count != 1")
s = s.replace(old_alloc, new_alloc)

for token in ("focal_native_xfer", "focal_native_wakeup", "FTE4800_IMAGE_",
              "FTE4800_NATIVE_IMAGE_BYTES", "FTE4800_COMPAT_IMAGE",
              "FTE4800_COMPAT_WRITE", "FTE4800_COMPAT_INT"):
    if token in s:
        raise RuntimeError(f"unverified token remains: {token}")

SRC.write_text(s)
