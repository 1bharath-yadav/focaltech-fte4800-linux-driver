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
  rm -f /tmp/fte4800_raw_image /tmp/fte4800_raw_image.c
}
trap cleanup EXIT

CURRENT="$(basename "$(readlink "/sys/bus/spi/devices/$DEV/driver" 2>/dev/null || true)")"
if [ -n "$CURRENT" ]; then echo "$DEV" | sudo -n tee "/sys/bus/spi/drivers/$CURRENT/unbind" >/dev/null; fi
sudo -n modprobe -r spidev >/dev/null 2>&1 || true
sudo -n modprobe spidev bufsiz=8192
echo spidev | sudo -n tee "/sys/bus/spi/devices/$DEV/driver_override" >/dev/null
echo "$DEV" | sudo -n tee /sys/bus/spi/drivers/spidev/bind >/dev/null
sleep 1

cat > /tmp/fte4800_raw_image.c <<'EOF'
#include <fcntl.h>
#include <linux/spi/spidev.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

static void sleep_ms(unsigned ms){struct timespec t={ms/1000,(long)(ms%1000)*1000000L};nanosleep(&t,0);}
static int xfer(int fd, uint8_t *tx, uint8_t *rx, uint32_t len){
    struct spi_ioc_transfer x={0};
    x.tx_buf=(uintptr_t)tx; x.rx_buf=(uintptr_t)rx; x.len=len; x.speed_hz=1000000; x.bits_per_word=8;
    return ioctl(fd,SPI_IOC_MESSAGE(1),&x);
}
int main(void){
    int fd=open("/dev/spidev1.0",O_RDWR);
    uint32_t mode=0,speed=1000000;
    if(fd<0){perror("open");return 2;}
    ioctl(fd,SPI_IOC_WR_MODE32,&mode); ioctl(fd,SPI_IOC_WR_MAX_SPEED_HZ,&speed);

    uint8_t wake[4]={0xff,0,0,0}, wrx[4]={0};
    uint8_t *tx=calloc(1,5127), *rx=calloc(1,5127);
    if(!tx||!rx)return 3;
    tx[0]=0x90; tx[1]=0x80; tx[2]=0x14; tx[3]=0x00;
    if(xfer(fd,wake,wrx,4)<0){perror("wake");return 4;}
    sleep_ms(5);
    if(xfer(fd,tx,rx,5127)<0){perror("image");return 5;}
    size_t nz=0,uniq=0; unsigned seen[256]={0};
    for(size_t i=7;i<5127;i++){ if(rx[i])nz++; seen[rx[i]]=1; }
    for(int i=0;i<256;i++) if(seen[i])uniq++;
    printf("rx_first16:"); for(int i=0;i<16;i++)printf(" %02x",rx[i]); putchar('\n');
    printf("payload: len=%d min=%u max=%u nonzero=%zu unique=%zu\n",5120,
        255u,0u,nz,uniq);
    unsigned min=255,max=0;
    for(size_t i=7;i<5127;i++){if(rx[i]<min)min=rx[i];if(rx[i]>max)max=rx[i];}
    printf("payload-range: min=%u max=%u\n",min,max);
    FILE *f=fopen("/tmp/fte4800-raw-image.bin","wb"); fwrite(rx+7,1,5120,f); fclose(f);
    free(tx);free(rx);close(fd);return 0;
}
EOF
gcc -O2 -Wall -Wextra -o /tmp/fte4800_raw_image /tmp/fte4800_raw_image.c
sudo -n /tmp/fte4800_raw_image
