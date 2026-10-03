#!/bin/bash
cd /tmp/vend
for k in "$@"; do for t in 0 1; do for v in 0 1; do
  FRAMES=/tmp/vend/fr_$k.bin PAIRS=1 ./h $t $v 8 1 2>&1 | grep -E "^PAIR" > p_${k}_t${t}_v${t}${v}.txt &
done; done; wait; done
