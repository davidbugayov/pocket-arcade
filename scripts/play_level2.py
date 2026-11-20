#!/usr/bin/env python3
import subprocess
import time
import os

SERIAL = "lb6xcawkcq7dpjaa"

def swipe(x1, y1, x2, y2, duration=250):
    subprocess.run(["adb", "-s", SERIAL, "shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(duration)], check=True)

def tap(x, y):
    subprocess.run(["adb", "-s", SERIAL, "shell", "input", "tap", str(x), str(y)], check=True)

def capture(name):
    path = os.path.join("artifacts/xiaomi", name)
    with open(path, "wb") as f:
        subprocess.run(["adb", "-s", SERIAL, "exec-out", "screencap", "-p"], stdout=f, check=True)
    print(f"Captured: {path}")

print("--- Starting Level 2 Run on Redmi Note 8 Pro ---")

# Step 1: Advance towards Gate 1 (t=0 to 3.5s)
time.sleep(1.5)
# Steer right into +8 risky gate (x = 2.0)
swipe(540, 1600, 780, 1600, 200)
time.sleep(2.0)
capture("level2_03_gate1_passed.png")

# Step 2: Steer left towards Rescue Barrel (-110.0) and Gate 2 (t=3.5 to 8s)
swipe(780, 1600, 300, 1600, 350)
time.sleep(3.0)
capture("level2_04_rescue_barrel_and_gate2.png")

# Step 3: Steer right towards Plasma Minigun (-165.0) and Gate 3 (t=8 to 14s)
swipe(300, 1600, 800, 1600, 350)
time.sleep(3.0)
capture("level2_05_plasma_minigun_pickup.png")

# Step 4: Advance through Gate 4 towards Heavy War Tank (t=14 to 20s)
swipe(800, 1600, 540, 1600, 250)
time.sleep(5.0)
capture("level2_06_tank_boss_engaged.png")

# Step 5: Duel Heavy War Tank (dodge cannon blasts by swiping left/right)
print("Engaging Heavy War Tank...")
for i in range(5):
    # Dodge left
    swipe(540, 1600, 320, 1600, 200)
    time.sleep(1.2)
    # Dodge right
    swipe(320, 1600, 760, 1600, 200)
    time.sleep(1.2)

capture("level2_07_tank_combat_telegraph.png")
time.sleep(3.0)
capture("level2_08_level2_victory.png")
print("--- Level 2 Playtest Complete ---")
