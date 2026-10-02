savedcmd_focal_spi.mod := printf '%s\n'   focal_spi.o | awk '!x[$$0]++ { print("./"$$0) }' > focal_spi.mod
