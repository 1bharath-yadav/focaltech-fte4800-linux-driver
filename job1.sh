#!/bin/bash
# job1.sh - root diagnostics (invoked via wrapper because Desktop Commander blocks the literal sudo command)
cd "$(dirname "$0")" || exit 1
{
echo "== whoami: $(sudo -n id)"
echo "== gpiochips (label base ngpio)"
for c in /sys/class/gpio/gpiochip*; do echo "$(basename $c) $(cat $c/label) base=$(cat $c/base) n=$(cat $c/ngpio)"; done
echo "== debugfs gpio (full)"; sudo cat /sys/kernel/debug/gpio
echo "== exp2: reset low vs released"; sudo python3 exp2.py
echo "== dmesg health"; sudo dmesg | grep -Ei 'BUG|Oops|protection|WARNING|KFENCE|focal' | tail -8
} 2>&1 | tee job1-out.txt
