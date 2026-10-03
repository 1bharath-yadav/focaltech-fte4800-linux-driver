#include <fcntl.h>
#include <linux/ioctl.h>
#include <stdio.h>
#include <unistd.h>

int main(void)
{
    int fd = open("/dev/focal_moh_spi", O_RDWR);
    if (fd < 0) {
        perror("open");
        return 2;
    }
    unsigned int cmd = 0x8090;
    if (ioctl(fd, cmd, 0) < 0)
        perror("ioctl");
    close(fd);
    return 0;
}
