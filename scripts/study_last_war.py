#!/usr/bin/env python3
"""Clean-room study runner for Last War: Survival on physical Redmi Note 8 Pro (lb6xcawkcq7dpjaa)."""
import os
import subprocess
import time

SERIAL = "lb6xcawkcq7dpjaa"
PACKAGE = "com.fun.lastwar.gp"
ACTIVITY = "com.im30.aps.debug.UnityPlayerActivityCustom"
OUTPUT_DIR = os.path.abspath("references/last-war/screenshots")

def adb(cmd: list) -> str:
    res = subprocess.run(["adb", "-s", SERIAL] + cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return res.stdout

def take_shot(name: str):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    path = os.path.join(OUTPUT_DIR, name)
    with open(path, "wb") as f:
        subprocess.run(["adb", "-s", SERIAL, "exec-out", "screencap", "-p"], stdout=f, check=True)
    print(f"📸 Captured Last War frame: {path} ({os.path.getsize(path):,} bytes)")

def main():
    print("==================================================")
    print("  Clean-Room Study: Last War: Survival")
    print("==================================================")
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Launch app
    print("Launching Last War on Xiaomi...")
    adb(["shell", "am", "start", "-n", f"{PACKAGE}/{ACTIVITY}"])
    
    # Observe loading and first runner tutorial sequence
    for i in range(1, 8):
        time.sleep(3.0)
        take_shot(f"lastwar_frame_{i:02d}.png")
        # Tap center or 'tap to continue' area if prompt appears
        if i >= 3:
            adb(["shell", "input", "tap", "540", "1800"])

    print("Stopping Last War...")
    adb(["shell", "am", "force-stop", PACKAGE])
    print("✅ Last War clean-room visual study complete!")

if __name__ == "__main__":
    main()
