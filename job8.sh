#!/bin/bash
# job8: capture fw9369 init trace (which Read16/Read8 regs the blob hits and what we return)
cd /home/archer/projects/zerobook-focaltech-driver
OUT=job8-out.txt
: > $OUT
sudo dmesg -C
sudo systemctl restart fprintd.service
sleep 2
timeout 20 fprintd-enroll -f right-index-finger "$USER" > job8-enroll.txt 2>&1 < /dev/null
sudo dmesg > job8-dmesg-full.txt
sudo journalctl -u fprintd.service --no-pager -n 400 > job8-journal.txt
{
  echo "== srcversion"; cat /sys/module/focal_spi/srcversion
  echo "== enroll output"; head -20 job8-enroll.txt
  echo "== unhandled reads (count)"
  grep -o "UNHANDLED Read[0-9]* addr=0x[0-9a-f]*" job8-dmesg-full.txt | sort | uniq -c | sort -rn
  echo "== first 150 XLAT lines"
  grep "XLAT" job8-dmesg-full.txt | head -150
  echo "== journal tail"
  tail -60 job8-journal.txt
} >> $OUT 2>&1
echo done
