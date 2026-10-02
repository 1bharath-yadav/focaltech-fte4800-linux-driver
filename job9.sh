#!/bin/bash
# job9: capture FULL init trace via journald (dmesg ring wraps), run fprintd as root so polkit authorizes
cd /home/archer/projects/zerobook-focaltech-driver
OUT=job9-out.txt
: > $OUT
sudo systemctl stop fprintd.service
sleep 1
START=$(date +"%Y-%m-%d %H:%M:%S")
sudo systemctl start fprintd.service
sleep 2
# root is always polkit-authorized; run 25s, nobody touching the sensor is fine for init capture
sudo timeout 25 fprintd-enroll -f right-index-finger archer > job9-enroll.txt 2>&1 < /dev/null
sudo journalctl -k --since "$START" --no-pager > job9-kernel.txt
sudo journalctl -u fprintd.service --since "$START" --no-pager > job9-fprintd.txt
{
  echo "== enroll output"; head -30 job9-enroll.txt
  echo "== kernel lines: $(wc -l < job9-kernel.txt)"
  echo "== chip id / init lines in fprintd journal"
  grep -i "chip\|width\|fw93\|sensor\|init\|error\|fail" job9-fprintd.txt | head -60
  echo "== unhandled reads (count)"
  grep -o "UNHANDLED Read[0-9]* addr=0x[0-9a-f]*" job9-kernel.txt | sort | uniq -c | sort -rn
  echo "== init-phase kernel trace (noise filtered, first 400)"
  grep "focal" job9-kernel.txt | grep -v "reg=0x80" | grep -v "tx\[08 f7 80 00\]" | head -400
} >> $OUT 2>&1
echo done
