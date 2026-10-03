# Out-of-tree build of the FTE4800 / FT9368 SPI transport driver (focal_spi.ko).
# Used directly (`make`) and by DKMS (see dkms.conf).
KERNEL_VERSION ?= $(shell uname -r)
KERNELDIR ?= /lib/modules/$(KERNEL_VERSION)/build

obj-m += focal_spi.o

all modules:
	$(MAKE) -C $(KERNELDIR) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KERNELDIR) M=$(CURDIR) clean

.PHONY: all modules clean
