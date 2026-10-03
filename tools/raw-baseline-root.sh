#!/usr/bin/env bash
set -euo pipefail
DEV="spi-FTE4800:00"
cleanup() {
  echo "$DEV" | sudo -n tee /sys/bus/spi/drivers/spidev/unbind >/dev/null 2>&1 || true
  sudo -n modprobe -r spidev >/dev/null 2>&1 || true
  echo "" | sudo -n tee "/sys/bus/spi/devices/$DEV/driver_override" >/dev/null 2>&1 || true
  sudo -n modprobe focal_spi >/dev/null 2>&1 || true
  echo "$DEV" | sudo -n tee /sys/bus/spi/drivers/focal-fte4800/bind >/dev/null 2>&1 || true
  sudo -n systemctl restart fprintd.service >/dev/null 2>&1 || true
  rm -f /tmp/fte4800_raw_baseline /tmp/fte4800_raw_baseline.c
}
trap cleanup EXIT

cat > /tmp/fte4800_raw_baseline.c <<'EOF'
#include <fcntl.h>
#include <linux/spi/spidev.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <time.h>

static int xfer(int fd, uint8_t *tx, uint8_t *rx, uint32_t len) {
    struct spi_ioc_transfer x = {0};
    x.tx_buf=(uintptr_t)tx; x.rx_buf=(uintptr_t)rx; x.len=len;
    x.speed_hz=1000000; x.bits_per_word=8;
    return ioctl(fd,SPI_IOC_MESSAGE(1),&x);
}
static void msleep(unsigned ms) {
    struct timespec t={.tv_sec=ms/1000,.tv_nsec=(long)(ms%1000)*1000000L};
    nanosleep(&t,0);
}
int main(void) {
    int fd=open("/dev/spidev1.0",O_RDWR);
    uint8_t wake[4]={0xff,0,0,0}, wrx[4]={0};
    uint8_t info[39]={0}, inforx[39]={0};
    uint32_t mode=0,speed=1000000;
    if(fd<0){perror("open");return 2;}
    if(ioctl(fd,SPI_IOC_WR_MODE32,&mode)<0){perror("mode");return 3;}
    if(ioctl(fd,SPI_IOC_WR_MAX_SPEED_HZ,&speed)<0){perror("speed");return 4;}
    if(xfer(fd,wake,wrx,4)<0){perror("wake");return 5;}
    msleep(5);
    info[0]=0x91; info[1]=0x80; info[3]=0x20;
    if(xfer(fd,info,inforx,39)<0){perror("info");return 6;}
    printf("wake-rx:"); for(int i=0;i<4;i++)printf(" %02x",wrx[i]); putchar('\n');
    printf("info-rx:"); for(int i=0;i<39;i++)printf(" %02x",inforx[i]); putchar('\n');
    printf("payload:"); for(int i=7;i<39;i++)printf(" %02x",inforx[i]); putchar('\n');
    close(fd); return 0;
}
EOF
gcc -O2 -Wall -Wextra -o /tmp/fte4800_raw_baseline /tmp/fte4800_raw_baseline.c
sudo -n systemctl stop fprintd.service || true
CURRENT="$(basename "$(readlink "/sys/bus/spi/devices/$DEV/driver" 2>/dev/null || true)")"
if [ -n "$CURRENT" ]; then echo "$DEV" | sudo -n tee "/sys/bus/spi/drivers/$CURRENT/unbind" >/dev/null; fi
sudo -n modprobe spidev
printf '%s\n' spidev | sudo -n tee "/sys/bus/spi/devices/$DEV/driver_override" >/dev/null
echo "$DEV" | sudo -n tee /sys/bus/spi/drivers/spidev/bind >/dev/null
sleep 1
sudo -n /tmp/fte4800_raw_baseline
