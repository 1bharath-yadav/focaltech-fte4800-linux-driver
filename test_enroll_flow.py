#!/usr/bin/env python3
import dbus, dbus.mainloop.glib
from gi.repository import GLib
import os, sys, time

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
bus = dbus.SystemBus()

# Find device
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

def on_enroll_status(result, done):
    print(f"==> EnrollStatus: result='{result}', done={done}")
    if done:
        print("ENROLLMENT FULLY COMPLETED!")
        loop.quit()

bus.add_signal_receiver(on_enroll_status, dbus_interface="net.reactivated.Fprint.Device", signal_name="EnrollStatus")

# Start enrollment for right-index-finger
print("Claiming device...")
dev.Claim("")
print("Starting enrollment for right-index-finger...")
dev.EnrollStart("right-index-finger")

def trigger_touches():
    # Loop through stages and simulate finger touch pulses if needed
    for stg in range(1, 14):
        time.sleep(0.4)
        print(f"Triggering touch for stage {stg}...")
        try:
            with open("/sys/module/focal_spi/parameters/touch_trigger", "w") as f:
                f.write("1\n")
        except Exception as e:
            print(f"touch trigger error: {e}")
        time.sleep(0.3)
        try:
            with open("/sys/module/focal_spi/parameters/touch_trigger", "w") as f:
                f.write("0\n")
        except Exception:
            pass
    return False

GLib.timeout_add(800, trigger_touches)

try:
    loop.run()
finally:
    try:
        dev.EnrollStop()
        dev.Release()
    except Exception:
        pass
