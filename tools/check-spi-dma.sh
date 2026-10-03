#!/usr/bin/env bash
set -u
printf '%s\n' '=== controller dynamic debug ==='
grep -E 'spi-pxa2xx|pxa2xx_spi_transfer_one' /sys/kernel/debug/dynamic_debug/control 2>/dev/null | head -30 || true
printf '%s\n' '=== relevant kernel config ==='
for k in CONFIG_SPI_PXA2XX CONFIG_SPI_PXA2XX_DMA CONFIG_DYNAMIC_DEBUG; do grep "^$k=" /boot/config-$(uname -r) 2>/dev/null || true; done
printf '%s\n' '=== recent pxa/spi logs ==='
dmesg | grep -Ei 'pxa2xx|spi.*DMA|DMA.*spi|spi.*PIO' | tail -80 || true
printf '%s\n' '=== spi statistics ==='
for f in messages transfers errors bytes bytes_rx bytes_tx transfers_split_maxsize; do printf '%s=' "$f"; cat "/sys/bus/spi/devices/spi-FTE4800:00/statistics/$f" 2>/dev/null || echo NA; done
