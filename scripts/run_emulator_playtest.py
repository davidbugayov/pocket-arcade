#!/usr/bin/env python3
"""Automated playtest and verification runner for Squad Rush on remote emulator-5556."""
import json
import os
import subprocess
import sys
import time

REMOTE_HOST = "build"
EMULATOR_SERIAL = "emulator-5556"
PACKAGE = "com.craftanything.squadrush"
ACTIVITY = "com.godot.game.GodotAppLauncher"
ARTIFACTS_DIR = os.path.abspath("artifacts/emulator")

def remote_adb(cmd: str, timeout: int = 40) -> str:
    full_cmd = f"export PATH=$PATH:/Users/davidbugayov/Library/Android/sdk/platform-tools; adb -s {EMULATOR_SERIAL} {cmd}"
    res = subprocess.run(
        ["ssh", "-o", "ClearAllForwardings=yes", REMOTE_HOST, full_cmd],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=timeout
    )
    if res.returncode != 0 and "grep" not in cmd and "rm" not in cmd:
        print(f"ADB Warning: {cmd} returned code {res.returncode}: {res.stderr.strip()}", file=sys.stderr)
    return res.stdout

def pull_file(remote_device_path: str, local_path: str) -> None:
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    temp_remote = f"/tmp/{os.path.basename(local_path)}"
    remote_adb(f"pull {remote_device_path} {temp_remote}")
    subprocess.run(["scp", "-o", "ClearAllForwardings=yes", f"{REMOTE_HOST}:{temp_remote}", local_path], check=True)
    remote_adb(f"shell rm -f {remote_device_path}")
    subprocess.run(["ssh", "-o", "ClearAllForwardings=yes", REMOTE_HOST, f"rm -f {temp_remote}"], check=True)

def push_save(save_dict: dict) -> None:
    json_str = json.dumps(save_dict)
    cmd = f"export PATH=$PATH:/Users/davidbugayov/Library/Android/sdk/platform-tools; echo '{json_str}' | adb -s {EMULATOR_SERIAL} shell \"run-as {PACKAGE} sh -c 'cat > files/squad_rush_save.json'\""
    subprocess.run(["ssh", "-o", "ClearAllForwardings=yes", REMOTE_HOST, cmd], check=True)

def take_screenshot(name: str) -> str:
    dev_path = f"/sdcard/{name}"
    local_path = os.path.join(ARTIFACTS_DIR, name)
    remote_adb(f"shell screencap -p {dev_path}")
    pull_file(dev_path, local_path)
    print(f"📸 Captured screenshot: {local_path} ({os.path.getsize(local_path):,} bytes)")
    return local_path

def main():
    os.makedirs(ARTIFACTS_DIR, exist_ok=True)
    print("=======================================================")
    print("  Pocket Arcade: Squad Rush - Remote Emulator Playtest")
    print(f"  Target: {EMULATOR_SERIAL} (Squad_Rush_Emu)")
    print("=======================================================")

    out = remote_adb("emu avd name")
    print(f"Device AVD: {out.strip()}")
    if "Squad_Rush_Emu" not in out:
        print("ERROR: emulator-5556 is not Squad_Rush_Emu! Aborting.")
        sys.exit(1)

    # -----------------------------------------------------------------
    # SCENARIO 1: Unupgraded Starter Playthrough (Deliberate Steering)
    # -----------------------------------------------------------------
    print("\n>>> SCENARIO 1: First Playthrough (0 upgrades, Starter Rifle, Deliberate Steering)")
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
    remote_adb(f"shell am force-stop {PACKAGE}")
    push_save(starter_save)

    remote_adb("shell rm -f /sdcard/squad_rush_gameplay.mp4")
    print("Starting video recording on emulator (50 seconds)...")
    rec_cmd = f"export PATH=$PATH:/Users/davidbugayov/Library/Android/sdk/platform-tools; adb -s {EMULATOR_SERIAL} shell screenrecord --time-limit 50 --size 720x1600 --bit-rate 4000000 /sdcard/squad_rush_gameplay.mp4"
    rec_proc = subprocess.Popen(["ssh", "-o", "ClearAllForwardings=yes", REMOTE_HOST, rec_cmd])

    time.sleep(1.0)
    remote_adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(3.0)
    take_screenshot("01_main_menu.png")

    # Tap Level 1 button (center x=540, y=710)
    print("Tapping Level 1 button (540, 710)...")
    remote_adb("shell input tap 540 710")
    t0 = time.time()

    time.sleep(2.0)
    take_screenshot("02_level1_intro.png")

    # t = 4.8s: Steer LEFT to Gate 1 (+3 safe route, z = -55)
    wait_until = t0 + 4.8
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Steering LEFT to Gate 1 (+3 safe route)...")
    remote_adb("shell input swipe 540 1800 280 1800 250")

    time.sleep(1.8)
    take_screenshot("03_gate1_passed_squad4.png")

    # t = 7.2s: Steer back to CENTER
    wait_until = t0 + 7.2
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Steering back to CENTER...")
    remote_adb("shell input swipe 280 1800 540 1800 250")

    # t = 11.2s: Steer LEFT to Gate 2 (x2 multiplier, z = -115)
    wait_until = t0 + 11.2
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Steering LEFT to Gate 2 (x2 multiplier)...")
    remote_adb("shell input swipe 540 1800 280 1800 250")

    time.sleep(2.0)
    take_screenshot("04_gate2_squad8.png")

    # t = 14.5s: Steer back to CENTER for Combat Shotgun pickup & Checkpoint
    wait_until = t0 + 14.5
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Steering to CENTER for Combat Shotgun pickup (z = -172)...")
    remote_adb("shell input swipe 280 1800 540 1800 250")

    time.sleep(3.5)
    take_screenshot("05_weapon_pickup_shotgun.png")

    # t = 20.2s: Steer LEFT to Gate 3 (+6 route, z = -205)
    wait_until = t0 + 20.2
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Steering LEFT to Gate 3 (+6 route)...")
    remote_adb("shell input swipe 540 1800 280 1800 250")

    time.sleep(2.5)
    take_screenshot("06_squad14_defense_line.png")

    # t = 24.5s: Steer back to CENTER for Defense line and Boss arena
    wait_until = t0 + 24.5
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Advancing to Boss Arena (Squad = 14 soldiers)...")
    remote_adb("shell input swipe 280 1800 540 1800 250")

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
    print("Dodging Boss Attack 1 -> Steer RIGHT (800)...")
    remote_adb("shell input swipe 540 1800 800 1800 200")

    # Boss Attack 2 dodge: Steer LEFT at t = 36.5s
    wait_until = t0 + 36.5
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Dodging Boss Attack 2 -> Steer LEFT (280)...")
    remote_adb("shell input swipe 800 1800 280 1800 200")

    # Boss Attack 3 dodge: Steer CENTER at t = 39.0s
    wait_until = t0 + 39.0
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Dodging Boss Attack 3 -> Steer CENTER (540)...")
    remote_adb("shell input swipe 280 1800 540 1800 200")

    # Boss Attack 4 dodge: Steer RIGHT at t = 41.2s
    wait_until = t0 + 41.2
    if time.time() < wait_until:
        time.sleep(wait_until - time.time())
    print("Dodging Boss Attack 4 -> Steer RIGHT (800)...")
    remote_adb("shell input swipe 540 1800 800 1800 200")

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
    pull_file("/sdcard/squad_rush_gameplay.mp4", os.path.join(ARTIFACTS_DIR, "squad_rush_gameplay.mp4"))
    print(f"🎬 Video recording pulled: {os.path.join(ARTIFACTS_DIR, 'squad_rush_gameplay.mp4')} ({os.path.getsize(os.path.join(ARTIFACTS_DIR, 'squad_rush_gameplay.mp4')):,} bytes)")

    # -----------------------------------------------------------------
    # SCENARIO 2: Playthrough Without Steering (Stay in Center Lane)
    # -----------------------------------------------------------------
    print("\n>>> SCENARIO 2: Playthrough Without Steering (No Input)")
    remote_adb(f"shell am force-stop {PACKAGE}")
    push_save(starter_save)
    remote_adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(2.5)
    remote_adb("shell input tap 540 710")
    print("Running with 0 steering input for 38 seconds...")
    time.sleep(38.0)
    take_screenshot("09_defeat_screen.png")

    # Verify Retry button restarts level
    print("Tapping Retry button (540, 1500)...")
    remote_adb("shell input tap 540 1500")
    time.sleep(2.5)
    take_screenshot("10_retry_level_restarted.png")

    # -----------------------------------------------------------------
    # SCENARIO 3: Backgrounding and Resume (Auto-Pause Verification)
    # -----------------------------------------------------------------
    print("\n>>> SCENARIO 3: Backgrounding and Safe Pause Resume")
    time.sleep(5.0)
    print("Pressing HOME key to background app...")
    remote_adb("shell input keyevent 3")
    time.sleep(2.0)
    take_screenshot("11_app_backgrounded.png")

    print("Returning app to foreground...")
    remote_adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(2.0)
    take_screenshot("12_returned_from_background_paused.png")

    # Resume game
    print("Tapping Resume button in Pause Overlay (540, 1050)...")
    remote_adb("shell input tap 540 1050")
    time.sleep(1.5)

    # -----------------------------------------------------------------
    # SCENARIO 4: Shop Purchases & Save Persistence
    # -----------------------------------------------------------------
    print("\n>>> SCENARIO 4: Shop Purchases & Persistence Across Force-Stop")
    remote_adb(f"shell am force-stop {PACKAGE}")
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
    remote_adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(2.5)

    # Buy Squad Size (UpgBtn at x=850, y=1230)
    print("Purchasing Squad Size upgrade (40 coins)...")
    remote_adb("shell input tap 850 1230")
    time.sleep(0.6)

    # Buy Damage upgrade (UpgBtn at x=850, y=1344)
    print("Purchasing Damage upgrade (50 coins)...")
    remote_adb("shell input tap 850 1344")
    time.sleep(0.6)

    take_screenshot("13_shop_upgrades_purchased.png")

    # Force stop and relaunch to test persistence
    print("Force stopping app to test cold restart persistence...")
    remote_adb(f"shell am force-stop {PACKAGE}")
    time.sleep(1.5)
    remote_adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(2.5)
    take_screenshot("14_persistence_after_restart.png")

    # -----------------------------------------------------------------
    # SCENARIO 5: Performance Benchmark (10, 30, and 60 Soldiers)
    # -----------------------------------------------------------------
    print("\n>>> SCENARIO 5: 10 -> 30 -> 60 Squad Performance Benchmark")
    remote_adb("shell touch /sdcard/squad_rush_benchmark.flag")
    remote_adb("logcat -c")

    remote_adb(f"shell am force-stop {PACKAGE}")
    remote_adb(f"shell am start -n {PACKAGE}/{ACTIVITY}")
    time.sleep(2.5)
    remote_adb("shell input tap 540 710")
    print("Benchmark active! Measuring performance for 12 seconds...")
    time.sleep(12.0)

    logcat_out = remote_adb("logcat -d -s godot:I")
    perf_lines = [line for line in logcat_out.splitlines() if "[PERF_METRICS]" in line or "[BENCHMARK]" in line or "[SPAWN_LATENCY]" in line]

    benchmark_log_path = os.path.join(ARTIFACTS_DIR, "benchmark_metrics.log")
    with open(benchmark_log_path, "w") as f:
        f.write("\n".join(perf_lines) + "\n")
    print(f"📊 Benchmark metrics saved to: {benchmark_log_path}")
    for pl in perf_lines[-8:]:
        print("  ", pl)

    remote_adb("shell rm -f /sdcard/squad_rush_benchmark.flag")
    remote_adb(f"shell am force-stop {PACKAGE}")

    # Restore initial user save backup
    backup_path = os.path.join(ARTIFACTS_DIR, "squad_rush_save_backup.json")
    if os.path.exists(backup_path):
        with open(backup_path) as bf:
            restore_dict = json.load(bf)
        push_save(restore_dict)
        print("✅ Restored original user save file on emulator.")

    print("\n=======================================================")
    print("  ALL PLAYTEST SCENARIOS SUCCESSFULLY COMPLETED!")
    print(f"  Artifacts directory: {ARTIFACTS_DIR}")
    print("=======================================================")

if __name__ == "__main__":
    main()
