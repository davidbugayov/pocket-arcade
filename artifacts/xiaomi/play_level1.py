#!/usr/bin/env python3
import subprocess
import time
import os
import threading

SERIAL = "lb6xcawkcq7dpjaa"

def adb(cmd):
    return subprocess.check_output(f"adb -s {SERIAL} {cmd}", shell=True).decode()

print("Starting Level 1 Playthrough on Xiaomi...")

# 1. Clean previous video on sdcard
adb("shell rm -f /sdcard/squad_rush_gameplay.mp4")

# 2. Start screenrecord in background
rec_proc = subprocess.Popen(
    f"adb -s {SERIAL} shell screenrecord --time-limit 35 --size 720x1560 --bit-rate 4000000 /sdcard/squad_rush_gameplay.mp4",
    shell=True
)
print("Screen recording started...")
time.sleep(1.0)

# 3. Tap Level 1 button from Main Menu (540, 630)
print("Tapping Level 1 button (540, 630)...")
adb("shell input tap 540 630")
start_time = time.time()

# Background screenshot thread for tutorial prompt at t=1.2s
def capture_tutorial():
    time.sleep(1.2)
    print("Capturing 06_tutorial_active.png...")
    adb("shell screencap -p /sdcard/06_tutorial_active.png")

t_thread = threading.Thread(target=capture_tutorial)
t_thread.start()

# Steering schedule
# t = 3.6s: Steer LEFT for Gate 1 (+5)
time.sleep(max(0, 3.6 - (time.time() - start_time)))
print("Steering LEFT to Gate 1 (+5)...")
adb("shell input swipe 540 1600 320 1600 200")

# t = 6.4s: Passed Gate 1. Steer back to CENTER
time.sleep(max(0, 6.4 - (time.time() - start_time)))
print("Steering back to CENTER...")
adb("shell input swipe 320 1600 540 1600 200")

# t = 9.2s: Steer LEFT for Gate 2 (x2)
time.sleep(max(0, 9.2 - (time.time() - start_time)))
print("Steering LEFT to Gate 2 (x2)...")
adb("shell input swipe 540 1600 320 1600 200")

# t = 11.6s: Passed Gate 2. Steer back to CENTER for Weapon Pickup (Shotgun)
time.sleep(max(0, 11.6 - (time.time() - start_time)))
print("Steering to CENTER for Weapon Pickup (Shotgun)...")
adb("shell input swipe 320 1600 540 1600 200")

# t = 16.0s: Steer RIGHT for Gate 3 (x2)
time.sleep(max(0, 16.0 - (time.time() - start_time)))
print("Steering RIGHT to Gate 3 (x2)...")
adb("shell input swipe 540 1600 760 1600 200")

# t = 18.6s: Passed Gate 3. Steer back to CENTER for Barrels and Boss
time.sleep(max(0, 18.6 - (time.time() - start_time)))
print("Steering to CENTER for Boss...")
adb("shell input swipe 760 1600 540 1600 200")

# t = 26.5s: Boss destroyed, Level Complete, Victory!
time.sleep(max(0, 26.5 - (time.time() - start_time)))
print("Capturing 07_victory.png...")
adb("shell screencap -p /sdcard/07_victory.png")

t_thread.join()
rec_proc.wait(timeout=15)
print("Screen recording finished.")

# Pull artifacts
os.makedirs("/Users/dsbugaev/StudioProject/gym/artifacts/xiaomi", exist_ok=True)
adb("pull /sdcard/06_tutorial_active.png /Users/dsbugaev/StudioProject/gym/artifacts/xiaomi/06_tutorial_active.png")
adb("pull /sdcard/07_victory.png /Users/dsbugaev/StudioProject/gym/artifacts/xiaomi/07_victory.png")
adb("pull /sdcard/squad_rush_gameplay.mp4 /Users/dsbugaev/StudioProject/gym/artifacts/xiaomi/squad_rush_gameplay.mp4")

print("Playthrough complete and artifacts pulled successfully!")
