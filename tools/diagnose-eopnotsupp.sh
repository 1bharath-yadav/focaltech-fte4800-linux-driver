#!/usr/bin/env bash
set -u
echo '--- LAST KERNEL LOG ---'
sudo -n dmesg | tail -160 | grep -Ei 'focal|spi|pxa|EOPNOTSUPP|unsupported' || true
echo '--- PXA SOURCE ERRORS ---'
grep -Rni -E 'EOPNOTSUPP|unsupported|can_dma|dma' /usr/lib/modules/$(uname -r)/build/drivers/spi/spi-pxa2xx.c /usr/lib/modules/$(uname -r)/build/drivers/spi 2>/dev/null | grep -E 'pxa2xx|EOPNOTSUPP' | head -160 || true
