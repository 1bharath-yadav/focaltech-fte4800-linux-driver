#!/bin/bash
# Enable GLib debug output for fprintd (reversible: rm the drop-in + daemon-reload)
set -e
sudo -n mkdir -p /etc/systemd/system/fprintd.service.d
printf '[Service]\nEnvironment=G_MESSAGES_DEBUG=all\n' | sudo -n tee /etc/systemd/system/fprintd.service.d/debug.conf >/dev/null
sudo -n systemctl daemon-reload
sudo -n systemctl restart fprintd
sleep 1
systemctl show fprintd -p Environment
systemctl is-active fprintd
date '+marker: %H:%M:%S'
