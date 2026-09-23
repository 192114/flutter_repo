#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 一键运行：自动启动 iOS / Android 模拟器并按环境执行 fvm flutter run。
#
# 用法（环境与平台参数顺序任意，均可省略）：
#   ./scripts/run.sh                        # macOS 缺省 iOS + dev 环境
#   ./scripts/run.sh staging                # staging + iOS
#   ./scripts/run.sh android                # dev + Android 模拟器
#   ./scripts/run.sh android staging        # Android + staging（顺序任意）
#   SIMULATOR="iPhone 16e" ./scripts/run.sh ios prod    # 覆盖 iOS 模拟器
#   AVD="Pixel_7_Pro" ./scripts/run.sh android dev      # 覆盖 Android AVD
#
# 流程：
#   1. 校验 fvm / 环境文件 / 目标设备；
#   2. iOS：simctl boot + bootstatus 阻塞等待就绪 + 打开 Simulator 窗口；
#      Android：emulator 后台启动 + adb 轮询 sys.boot_completed 等待就绪；
#   3. exec fvm flutter run -d <设备> --dart-define-from-file=env/<env>.json。
#
# 环境变量：
#   SIMULATOR  iOS 目标模拟器名（缺省 iPhone 17 Pro）
#   AVD        Android 目标 AVD 名（缺省取列表第一个）
# ─────────────────────────────────────────────────────────────
# sh 会忽略 shebang；macOS 的 sh 也可能是处于 POSIX 模式的 Bash。
if [ -z "${BASH_VERSION:-}" ] || [ -o posix ]; then
  exec bash "$0" "$@"
fi
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$project_root"

usage() {
  cat >&2 <<EOF
用法: ./scripts/run.sh [dev|staging|prod] [ios|android]
      环境与平台参数顺序任意、均可省略（环境缺省 dev，平台缺省 macOS 为 ios）
      SIMULATOR="<iOS 模拟器名>" ./scripts/run.sh [dev|staging|prod] [ios]
      AVD="<Android AVD 名>" ./scripts/run.sh [dev|staging|prod] android
EOF
}

# ── 参数解析：环境 / 平台关键字顺序任意，重复出现直接报错 ──
env_name=""
platform=""
for arg in "$@"; do
  case "$arg" in
    dev | staging | prod)
      [[ -n "$env_name" ]] && { echo "错误：环境参数只能出现一次" >&2; exit 1; }
      env_name="$arg"
      ;;
    ios | android)
      [[ -n "$platform" ]] && { echo "错误：平台参数只能出现一次" >&2; exit 1; }
      platform="$arg"
      ;;
    *)
      echo "错误：未知参数 '$arg'（环境仅支持 dev/staging/prod，平台仅支持 ios/android）" >&2
      usage
      exit 1
      ;;
  esac
done
env_name="${env_name:-dev}"
if [[ -z "$platform" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then platform="ios"; else platform="auto"; fi
fi

env_file="env/${env_name}.json"

# ── 前置检查：fvm 与环境文件 ──
command -v fvm >/dev/null 2>&1 || {
  echo "错误：未找到 fvm 命令，请先安装 FVM（https://fvm.app/）" >&2
  exit 1
}
[[ -f "$env_file" ]] || {
  echo "错误：环境文件 $env_file 不存在" >&2
  exit 1
}

# ── iOS：依赖 xcrun simctl ──
run_ios() {
  if [[ "$(uname)" != "Darwin" ]]; then
    echo "错误：ios 平台需要 macOS（xcrun simctl），当前系统 $(uname)" >&2
    exit 1
  fi
  local device="${SIMULATOR:-iPhone 17 Pro}"

  # 目标模拟器存在性校验（"设备名 (" 固定串匹配，避免 17 Pro 误中 17 Pro Max）
  if ! xcrun simctl list devices available | grep -Fq "$device ("; then
    echo "错误：未找到模拟器 '$device'，当前可用设备：" >&2
    xcrun simctl list devices available | grep " (" >&2
    exit 1
  fi

  # 已启动则跳过 boot；未启动则 boot 并阻塞等待系统就绪
  if xcrun simctl list devices booted | grep -Fq "$device ("; then
    echo "模拟器已启动：$device"
  else
    echo "正在启动模拟器：$device ..."
    xcrun simctl boot "$device"
    xcrun simctl bootstatus "$device" -b
    echo "模拟器就绪：$device"
  fi

  # 确保模拟器窗口可见（设备可能已 boot 但窗口被关闭）
  open -a Simulator

  echo "运行：fvm flutter run -d \"$device\" --dart-define-from-file=$env_file"
  exec fvm flutter run -d "$device" --dart-define-from-file="$env_file"
}

# ── Android：依赖 emulator + adb ──

# 依次探测 ANDROID_HOME / ANDROID_SDK_ROOT / 常见默认路径
android_sdk_root() {
  local root
  for root in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Library/Android/sdk" "$HOME/Android/Sdk"; do
    if [[ -n "$root" && -x "$root/emulator/emulator" && -x "$root/platform-tools/adb" ]]; then
      printf '%s\n' "$root"
      return 0
    fi
  done
  return 1
}

# 找到指定 AVD 对应的已运行模拟器 serial（adb emu avd name 反查），无则返回非 0
android_serial_for_avd() {
  local avd="$1" serial name
  while IFS= read -r serial; do
    [[ -n "$serial" ]] || continue
    # emulator console 输出为 CRLF，需剥掉行尾 \r 再比较
    name="$("$ADB_BIN" -s "$serial" emu avd name 2>/dev/null | awk 'NR==1' | tr -d '\r')"
    if [[ "$name" == "$avd" ]]; then
      printf '%s\n' "$serial"
      return 0
    fi
  done < <("$ADB_BIN" devices | awk '$1 ~ /^emulator-/ && $2 == "device" {print $1}')
  return 1
}

android_boot_completed() {
  "$ADB_BIN" -s "$1" shell getprop sys.boot_completed 2>/dev/null | tr -d '[:space:]'
}

android_wait_boot() { # $1=serial $2=超时秒数
  local serial="$1" timeout="$2" elapsed=0
  while [[ "$(android_boot_completed "$serial")" != "1" ]]; do
    if (( elapsed >= timeout )); then
      return 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
}

run_android() {
  local sdk_root avd_list avd serial elapsed emu_pid stat emu_log=""
  if sdk_root="$(android_sdk_root)"; then
    EMU_BIN="$sdk_root/emulator/emulator"
    ADB_BIN="$sdk_root/platform-tools/adb"
  elif command -v emulator >/dev/null 2>&1 && command -v adb >/dev/null 2>&1; then
    EMU_BIN="$(command -v emulator)"
    ADB_BIN="$(command -v adb)"
  else
    echo "错误：未找到 Android SDK 工具（emulator / adb），请安装 Android SDK 或设置 ANDROID_HOME" >&2
    exit 1
  fi

  avd_list="$("$EMU_BIN" -list-avds 2>/dev/null || true)"
  if [[ -z "$avd_list" ]]; then
    echo "错误：未找到任何 AVD，请先用 Android Studio 或 avdmanager 创建" >&2
    exit 1
  fi
  if [[ -n "${AVD:-}" ]]; then
    if ! grep -Fxq "$AVD" <<<"$avd_list"; then
      echo "错误：未找到 AVD '$AVD'，当前可用：" >&2
      printf '%s\n' "$avd_list" >&2
      exit 1
    fi
    avd="$AVD"
  else
    avd="$(printf '%s\n' "$avd_list" | head -n1)"
    echo "未指定 AVD，使用第一个可用 AVD：${avd}（可用 AVD=\"<名称>\" 覆盖）"
  fi

  # adb server 可能恰好在重启（客户端版本切换会 kill 重建，设备短暂下线），
  # 轮询 10s 确认真的未在运行，避免误判后对同一 AVD 重复启动（emulator 会直接 FATAL）
  elapsed=0
  until serial="$(android_serial_for_avd "$avd")"; do
    if (( elapsed >= 10 )); then
      break
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done

  if [[ -n "${serial:-}" ]]; then
    echo "模拟器已启动：${avd}（${serial}）"
  else
    emu_log="$(mktemp /tmp/run_sh_emulator.XXXXXX)"
    echo "正在启动模拟器：${avd}（日志：${emu_log}）..."
    "$EMU_BIN" -avd "$avd" >"$emu_log" 2>&1 &
    emu_pid=$!

    # 阶段一：等待模拟器在 adb 中出现（console 就绪）；进程提前退出（如 AVD 被占用）立即报错
    elapsed=0
    until serial="$(android_serial_for_avd "$avd")"; do
      stat="$(ps -p "$emu_pid" -o stat= 2>/dev/null || true)"
      if [[ -z "$stat" || "$stat" == Z* ]]; then
        echo "错误：模拟器进程已提前退出，emulator 日志末尾：" >&2
        tail -n 20 "$emu_log" >&2 || true
        exit 1
      fi
      if (( elapsed >= 90 )); then
        echo "错误：等待模拟器 '$avd' 出现超时（90s），emulator 日志末尾：" >&2
        tail -n 20 "$emu_log" >&2 || true
        exit 1
      fi
      sleep 2
      elapsed=$((elapsed + 2))
    done
  fi

  # 阶段二：等待系统完成启动（已启动的模拟器立即返回）
  echo "等待系统完成启动（sys.boot_completed）..."
  if ! android_wait_boot "$serial" 300; then
    echo "错误：等待模拟器 '$avd' 完成启动超时（300s），emulator 日志末尾：" >&2
    [[ -n "$emu_log" ]] && tail -n 20 "$emu_log" >&2 || true
    exit 1
  fi
  echo "模拟器就绪：${avd}（${serial}）"

  echo "运行：fvm flutter run -d \"$serial\" --dart-define-from-file=$env_file"
  exec fvm flutter run -d "$serial" --dart-define-from-file="$env_file"
}

# ── 平台分发 ──
case "$platform" in
  auto)
    echo "提示：非 macOS 系统且未指定平台，跳过模拟器启动，由 flutter 自动选择已连接设备"
    exec fvm flutter run --dart-define-from-file="$env_file"
    ;;
  ios)
    run_ios
    ;;
  android)
    run_android
    ;;
esac
