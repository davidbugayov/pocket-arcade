#!/usr/bin/env bash
# scripts/build_squad_rush.sh
# Remote Godot 4.6.2 build runner for Squad Rush on MacBook M1 Pro (build.lan)
set -eo pipefail

REMOTE_HOST="build"
LOCAL_GAME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/games/squad-rush"
REMOTE_GAME_DIR="~/StudioProject/gym/games/squad-rush"
LOCAL_ARTIFACTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/artifacts"
REMOTE_BUILD_DIR="~/StudioProject/gym/games/squad-rush/build"
OUTPUT_APK_NAME="squad-rush-debug.apk"
PACKAGE_NAME="com.craftanything.squadrush"
LAUNCH_ACTIVITY="com.godot.game.GodotAppLauncher"
TARGET_DEVICE="${TARGET_DEVICE:-emulator-5556}"
REMOTE_ADB="/Users/davidbugayov/Library/Android/sdk/platform-tools/adb"

DO_INSTALL=0
DO_RUN=0

for arg in "$@"; do
    case "$arg" in
        --install|-i)
            DO_INSTALL=1
            ;;
        --run|-r)
            DO_INSTALL=1
            DO_RUN=1
            ;;
    esac
done

echo "========================================================"
echo "Pocket Arcade — Squad Rush Remote Build Pipeline"
echo "========================================================"
echo "Host: $REMOTE_HOST (192.168.1.190)"
echo "Local source:  $LOCAL_GAME_DIR"
echo "Remote target: $REMOTE_GAME_DIR"
echo "Target device: $TARGET_DEVICE"

# 1. Check SSH
if ! ssh -o ConnectTimeout=3 -o ClearAllForwardings=yes "$REMOTE_HOST" "true" >/dev/null 2>&1; then
    echo "❌ Ошибка: Удаленный MacBook ($REMOTE_HOST) недоступен по SSH." >&2
    exit 1
fi

# 2. Ensure remote directory exists
ssh -o ClearAllForwardings=yes "$REMOTE_HOST" "mkdir -p $REMOTE_GAME_DIR $REMOTE_BUILD_DIR"

# 3. Synchronize game sources to remote Mac
echo "🔄 Синхронизация исходников Squad Rush на удаленный Mac..."
rsync -az --delete \
    --exclude '.git' \
    --exclude 'build' \
    --exclude '.godot' \
    --exclude '.DS_Store' \
    -e "ssh -o ClearAllForwardings=yes" \
    "$LOCAL_GAME_DIR/" "$REMOTE_HOST:$REMOTE_GAME_DIR/"

# 4. Announce directory and command
REMOTE_EXPORT_CMD="cd $REMOTE_GAME_DIR && mkdir -p build && godot --headless --export-debug Android build/$OUTPUT_APK_NAME"
echo "⚡ [REMOTE BUILD] Запуск сборки на удаленном Mac:"
echo "   Удаленная директория: $REMOTE_GAME_DIR"
echo "   Команда: $REMOTE_EXPORT_CMD"

# 5. Execute remote export
ssh -o ClearAllForwardings=yes "$REMOTE_HOST" "$REMOTE_EXPORT_CMD"

# 6. Download APK to local artifacts
mkdir -p "$LOCAL_ARTIFACTS_DIR"
echo "📦 Загрузка собранного APK с удаленного Mac..."
scp -o ClearAllForwardings=yes "$REMOTE_HOST:$REMOTE_BUILD_DIR/$OUTPUT_APK_NAME" "$LOCAL_ARTIFACTS_DIR/$OUTPUT_APK_NAME"

echo "✅ APK успешно получен: $LOCAL_ARTIFACTS_DIR/$OUTPUT_APK_NAME"
ls -lh "$LOCAL_ARTIFACTS_DIR/$OUTPUT_APK_NAME"

# 7. Install and launch if requested
if [ "$DO_INSTALL" -eq 1 ]; then
    echo "📲 Установка $OUTPUT_APK_NAME на $TARGET_DEVICE..."
    ssh -o ClearAllForwardings=yes "$REMOTE_HOST" "$REMOTE_ADB -s $TARGET_DEVICE wait-for-device && $REMOTE_ADB -s $TARGET_DEVICE install -r $REMOTE_BUILD_DIR/$OUTPUT_APK_NAME"
    echo "✅ Установлено!"

    if [ "$DO_RUN" -eq 1 ]; then
        echo "🚀 Запуск $PACKAGE_NAME/$LAUNCH_ACTIVITY на $TARGET_DEVICE..."
        ssh -o ClearAllForwardings=yes "$REMOTE_HOST" "$REMOTE_ADB -s $TARGET_DEVICE shell am start -n $PACKAGE_NAME/$LAUNCH_ACTIVITY"
        echo "🎮 Игра запущена на $TARGET_DEVICE!"
    fi
fi
