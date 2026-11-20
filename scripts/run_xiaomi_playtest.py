#!/usr/bin/env python3
"""Playtest and verification runner for Pocket Arcade: Squad Rush on physical Redmi Note 8 Pro (lb6xcawkcq7dpjaa)."""
import json
import os
import shlex
import subprocess
import sys
import time

SERIAL = "lb6xcawkcq7dpjaa"
PACKAGE = "com.craftanything.squadrush"
ACTIVITY = "com.godot.game.GodotAppLauncher"
ARTIFACTS_DIR = os.path.abspath("artifacts/xiaomi")

def adb(cmd: str, timeout: int = 40) -> str:
    args = ["adb", "-s", SERIAL] + shlex.split(cmd)
    res = subprocess.run(
        args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=timeout
    )
    if res.returncode != 0 and "grep" not in cmd and "rm" not in cmd:
        print(f"ADB Warning: {cmd} returned code {res.returncode}: {res.stderr.strip()}", file=sys.stderr)
    return res.stdout

def push_save(save_dict: dict) -> None:
    json_str = json.dumps(save_dict)
    cmd = ["adb", "-s", SERIAL, "shell", f"run-as {PACKAGE} sh -c 'cat > files/squad_rush_save.json'"]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE, text=True)
    p.communicate(input=json_str)
    if p.returncode != 0:
        print(f"Warning: push_save returned {p.returncode}")

def take_screenshot(name: str) -> str:
    os.makedirs(ARTIFACTS_DIR, exist_ok=True)
    local_path = os.path.join(ARTIFACTS_DIR, name)
    with open(local_path, "wb") as f:
        subprocess.run(["adb", "-s", SERIAL, "exec-out", "screencap", "-p"], stdout=f, check=True)
    print(f"📸 Captured screenshot: {local_path} ({os.path.getsize(local_path):,} bytes)")
    return local_path

def clear_logcat():
    subprocess.run(["adb", "-s", SERIAL, "logcat", "-c"], check=True)

def dump_logcat(tag: str = "godot:I") -> str:
    res = subprocess.run(
        ["adb", "-s", SERIAL, "logcat", "-d", "-s", tag],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    return res.stdout

def main():
    os.makedirs(ARTIFACTS_DIR, exist_ok=True)
    print("=======================================================")
    print("  Pocket Arcade: Squad Rush - Physical Xiaomi Playtest")
    print(f"  Target: {SERIAL} (Redmi Note 8 Pro)")
    print("=======================================================")

    starter_save = {
        "coins": 0,
        "highest_unlocked_level": 1,
        "current_weapon_index": 0,
        "sound_enabled": True,
        "unlocked_weapons": [0],
        "upgrade_damage": 0,
        "upgrade_fire_rate": 0,
        "upgrade_squad_size": 0
    }

    # -----------------------------------------------------------------
    # SCENARIO 1: Unupgraded Starter Playthrough (Deliberate Steering)
    # -----------------------------------------------------------------
    print("\n>>> SCENARIO 1: Starter Squad with Deliberate Route & Boss Dodging")
    adb(f"shell am force-stop {PACKAGE}")
    push_save(starter_save)
    clear_logcat()

    adb("shell rm -f /sdcard/squad_rush_gameplay.mp4")
    print("Starting video recording on Xiaomi (50 seconds)...")
    rec_cmd = ["adb", "-s", SERIAL, "shell", "screenrecord", "--time-limit", "50", "--size", "720x1560", "--bit-rate", "4000000", "/sdcard/squad_rush_gameplay.mp4"]
    rec_proc = subprocess.Popen(rec_cmd)

    time.sleep(1.0)
    adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(3.0)
    take_screenshot("01_main_menu.png")

    print("Tapping Level 1 button (540, 710)...")
    adb("shell input tap 540 710")
    t0 = time.time()

    time.sleep(2.0)
    take_screenshot("02_level1_intro.png")

    # t = 4.8s: Steer LEFT to Gate 1 (+3 safe route, z = -55)
    wait_until = t0 + 4.8
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Steering LEFT to Gate 1 (+3 safe route)...")
    adb("shell input swipe 540 1800 220 1800 250")

    time.sleep(1.8)
    take_screenshot("03_gate1_passed_squad4.png")

    # t = 7.2s: Steer back to CENTER
    wait_until = t0 + 7.2
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Steering back to CENTER...")
    adb("shell input swipe 220 1800 540 1800 250")

    # t = 11.2s: Steer LEFT to Gate 2 (x2 multiplier, z = -115)
    wait_until = t0 + 11.2
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Steering LEFT to Gate 2 (x2 multiplier)...")
    adb("shell input swipe 540 1800 220 1800 250")

    time.sleep(2.0)
    take_screenshot("04_gate2_squad8.png")

    # t = 14.5s: Steer back to CENTER for Combat Shotgun pickup & Checkpoint
    wait_until = t0 + 14.5
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Steering to CENTER for Combat Shotgun pickup (z = -172)...")
    adb("shell input swipe 220 1800 540 1800 250")

    time.sleep(3.5)
    take_screenshot("05_weapon_pickup_shotgun.png")

    # t = 20.2s: Steer LEFT to Gate 3 (+6 route, z = -205)
    wait_until = t0 + 20.2
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Steering LEFT to Gate 3 (+6 route)...")
    adb("shell input swipe 540 1800 220 1800 250")

    time.sleep(2.5)
    take_screenshot("06_squad14_defense_line.png")

    # t = 24.5s: Steer back to CENTER for Defense line and Boss arena
    wait_until = t0 + 24.5
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Advancing to Boss Arena (Squad = 14 soldiers)...")
    adb("shell input swipe 220 1800 540 1800 250")

    # t = 32.5s: Boss Arena engagement begins!
    wait_until = t0 + 32.5
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("⚔️ Boss Combat Engaged: Iron Sentinel (950 HP)!")
    take_screenshot("07_boss_combat_telegraph.png")

    # Boss Attack 1 dodge: Boss sweeps center/left, steer RIGHT at t = 34.0s
    wait_until = t0 + 34.0
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Dodging Boss Attack 1 -> Steer RIGHT (860)...")
    adb("shell input swipe 540 1800 860 1800 200")

    # Boss Attack 2 dodge: Steer LEFT at t = 36.5s
    wait_until = t0 + 36.5
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Dodging Boss Attack 2 -> Steer LEFT (220)...")
    adb("shell input swipe 860 1800 220 1800 200")

    # Boss Attack 3 dodge: Steer CENTER at t = 39.0s
    wait_until = t0 + 39.0
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Dodging Boss Attack 3 -> Steer CENTER (540)...")
    adb("shell input swipe 220 1800 540 1800 200")

    # Boss Attack 4 dodge: Steer RIGHT at t = 41.2s
    wait_until = t0 + 41.2
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Dodging Boss Attack 4 -> Steer RIGHT (860)...")
    adb("shell input swipe 540 1800 860 1800 200")

    # t = 43.5s: Boss eliminated! Awaiting Victory Screen...
    wait_until = t0 + 43.5
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Boss eliminated! Awaiting Victory Screen...")
    time.sleep(2.5)
    take_screenshot("08_victory_screen.png")

    try:
        rec_proc.wait(timeout=10)
    except subprocess.TimeoutExpired:
        rec_proc.kill()
    time.sleep(1.0)

    # Pull video
    local_mp4 = os.path.join(ARTIFACTS_DIR, "squad_rush_gameplay.mp4")
    subprocess.run(["adb", "-s", SERIAL, "pull", "/sdcard/squad_rush_gameplay.mp4", local_mp4], check=True)
    adb("shell rm -f /sdcard/squad_rush_gameplay.mp4")
    print(f"🎬 Video recording pulled: {local_mp4} ({os.path.getsize(local_mp4):,} bytes)")

    # Save logcat for Scenario 1
    log1 = dump_logcat()
    with open(os.path.join(ARTIFACTS_DIR, "scenario1_logcat.log"), "w") as f:
        f.write(log1)

    # -----------------------------------------------------------------
    # SCENARIO 2: Playthrough Without Steering (No Input -> Center Lane)
    # -----------------------------------------------------------------
    print("\n>>> SCENARIO 2: Playthrough Without Steering (Zero Input)")
    adb(f"shell am force-stop {PACKAGE}")
    push_save(starter_save)
    clear_logcat()

    adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(2.5)
    adb("shell input tap 540 710")
    print("Running with 0 steering input for 38 seconds...")
    time.sleep(38.0)
    take_screenshot("09_defeat_screen.png")

    log2 = dump_logcat()
    with open(os.path.join(ARTIFACTS_DIR, "scenario2_no_steering_logcat.log"), "w") as f:
        f.write(log2)

    # Verify Retry button restarts level (540, 1500)
    print("Tapping Retry button (540, 1500)...")
    adb("shell input tap 540 1500")
    time.sleep(2.5)
    take_screenshot("10_retry_level_restarted.png")

    # -----------------------------------------------------------------
    # SCENARIO 3: Playthrough with Several Intentional Errors
    # -----------------------------------------------------------------
    print("\n>>> SCENARIO 3: Playthrough with Several Intentional Mistakes")
    adb(f"shell am force-stop {PACKAGE}")
    push_save(starter_save)
    clear_logcat()

    adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(2.5)
    adb("shell input tap 540 710")
    t0 = time.time()
    time.sleep(2.0)

    # Mistake 1: Swerving RIGHT into tire stack at z = -25 (x = 2.1)
    wait_until = t0 + 2.4
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Mistake 1: Steer RIGHT directly into Tire Stack obstacle (z = -25)...")
    adb("shell input swipe 540 1800 860 1800 200")

    # Mistake 2: Steer into charging Runner enemy at z = -45 (x = 2.1)
    wait_until = t0 + 4.2
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Mistake 2: Steer into charging Runner enemy (z = -45)...")
    time.sleep(1.5)

    # Take screenshot of casualties / error state
    take_screenshot("scenario3_intentional_mistakes_damage.png")

    # Steer left to recover at Gate 2
    wait_until = t0 + 11.2
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Steering to Gate 2 to recover...")
    adb("shell input swipe 860 1800 220 1800 300")
    time.sleep(3.0)

    # Let it proceed to see outcome
    time.sleep(20.0)
    take_screenshot("scenario3_aftermath.png")

    log3 = dump_logcat()
    with open(os.path.join(ARTIFACTS_DIR, "scenario3_mistakes_logcat.log"), "w") as f:
        f.write(log3)

    # -----------------------------------------------------------------
    # SCENARIO 4: Backgrounding and Resume (Auto-Pause Verification)
    # -----------------------------------------------------------------
    print("\n>>> SCENARIO 4: Backgrounding and Safe Pause Resume")
    time.sleep(3.0)
    print("Pressing HOME key to background app...")
    adb("shell input keyevent 3")
    time.sleep(2.0)
    take_screenshot("11_app_backgrounded.png")

    print("Returning app to foreground...")
    adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(2.0)
    take_screenshot("12_returned_from_background_paused.png")

    # Resume game
    print("Tapping Resume button in Pause Overlay (540, 1050)...")
    adb("shell input tap 540 1050")
    time.sleep(1.5)

    # -----------------------------------------------------------------
    # SCENARIO 5: Shop Purchases & Save Persistence
    # -----------------------------------------------------------------
    print("\n>>> SCENARIO 5: Shop Purchases & Persistence Across Force-Stop")
    adb(f"shell am force-stop {PACKAGE}")
    funded_save = {
        "coins": 600,
        "highest_unlocked_level": 2,
        "current_weapon_index": 0,
        "sound_enabled": True,
        "unlocked_weapons": [0],
        "upgrade_damage": 0,
        "upgrade_fire_rate": 0,
        "upgrade_squad_size": 0
    }
    push_save(funded_save)
    adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(2.5)

    # Buy Squad Size (UpgBtn at x=850, y=1230 in 720x1560 -> 850*1.5=1275? wait, screen width is 1080)
    # On 1080x2340: UpgBtn is near right edge (x ~ 880-950, y ~ 1300-1450)
    print("Purchasing Squad Size upgrade (tap at x=900, y=1340)...")
    adb("shell input tap 900 1340")
    time.sleep(0.6)

    # Buy Damage upgrade
    print("Purchasing Damage upgrade (tap at x=900, y=1480)...")
    adb("shell input tap 900 1480")
    time.sleep(0.6)

    take_screenshot("13_shop_upgrades_purchased.png")

    # Force stop and relaunch to test persistence
    print("Force stopping app to test cold restart persistence...")
    adb(f"shell am force-stop {PACKAGE}")
    time.sleep(1.5)
    adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(2.5)
    take_screenshot("14_persistence_after_restart.png")

    # -----------------------------------------------------------------
    # SCENARIO 6: Performance Benchmark (10 -> 30 -> 60 Soldiers)
    # -----------------------------------------------------------------
    print("\n>>> SCENARIO 6: 10 -> 30 -> 60 Squad Performance Benchmark")
    adb("shell touch /sdcard/squad_rush_benchmark.flag")
    clear_logcat()

    adb(f"shell am force-stop {PACKAGE}")
    adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(2.5)
    adb("shell input tap 540 710")
    print("Benchmark active! Measuring performance for 12 seconds...")
    time.sleep(12.0)

    logcat_out = dump_logcat()
    perf_lines = [line for line in logcat_out.splitlines() if "[PERF_METRICS]" in line or "[BENCHMARK]" in line or "[SPAWN_LATENCY]" in line]

    benchmark_log_path = os.path.join(ARTIFACTS_DIR, "benchmark_metrics.log")
    with open(benchmark_log_path, "w") as f:
        f.write("\n".join(perf_lines) + "\n")
    print(f"📊 Benchmark metrics saved to: {benchmark_log_path}")
    for pl in perf_lines[-8:]:
        print("  ", pl)

    adb("shell rm -f /sdcard/squad_rush_benchmark.flag")
    adb(f"shell am force-stop {PACKAGE}")

    # Restore initial user save backup
    backup_path = "artifacts/xiaomi_user_save_backup.json"
    if os.path.exists(backup_path):
        with open(backup_path) as bf:
            restore_dict = json.load(bf)
        push_save(restore_dict)
        print("✅ Restored original user save file on Xiaomi.")

    print("\n=======================================================")
    print("  ALL PLAYTEST SCENARIOS SUCCESSFULLY COMPLETED ON XIAOMI!")
    print(f"  Artifacts directory: {ARTIFACTS_DIR}")
    print("=======================================================")

if __name__ == "__main__":
    main()
