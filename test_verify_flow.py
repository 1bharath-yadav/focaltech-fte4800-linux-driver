#!/usr/bin/env python3
import dbus, dbus.mainloop.glib
from gi.repository import GLib
import os, sys, time

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
bus = dbus.SystemBus()

manager = dbus.Interface(bus.get_object("net.reactivated.Fprint", "/net/reactivated/Fprint/Manager"), "net.reactivated.Fprint.Manager")
devices = manager.GetDevices()
if not devices:
    print("No devices found!")
    sys.exit(1)

dev_path = devices[0]
print(f"Using device: {dev_path}")
dev_obj = bus.get_object("net.reactivated.Fprint", dev_path)
dev = dbus.Interface(dev_obj, "net.reactivated.Fprint.Device")

loop = GLib.MainLoop()

def on_verify_status(result, done):
    print(f"==> VerifyStatus: result='{result}', done={done}")
    if done:
        print("VERIFICATION COMPLETED!")
        loop.quit()

bus.add_signal_receiver(on_verify_status, dbus_interface="net.reactivated.Fprint.Device", signal_name="VerifyStatus")

print("Claiming device...")
dev.Claim("")
print("Starting verification for right-index-finger...")
dev.VerifyStart("right-index-finger")

def trigger_touch():
    print("Simulating/triggering touch for verification...")
    try:
        with open("/sys/module/focal_spi/parameters/touch_trigger", "w") as f:
            f.write("1\n")
    except Exception as e:
        print(f"touch trigger error: {e}")
    return False

GLib.timeout_add(1000, trigger_touch)

# Timeout after 8 seconds if nothing happens
GLib.timeout_add(8000, loop.quit)

try:
    loop.run()
finally:
    try:
        dev.VerifyStop()
        dev.Release()
    except Exception:
        pass
