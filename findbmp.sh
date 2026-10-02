#!/bin/bash
sudo -n find /tmp -maxdepth 4 -name "*.bmp" -newermt "$(date +%Y-%m-%d) 14:50:00" 2>/dev/null | sort | head -40
echo "--- count:"
sudo -n find /tmp -maxdepth 4 -name "*.bmp" 2>/dev/null | wc -l
