#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 一键运行：自动启动 iOS 模拟器并按环境执行 fvm flutter run。
#
# 用法：
#   ./scripts/run.sh              # dev 环境（缺省）
#   ./scripts/run.sh staging      # staging / prod 同理
#   SIMULATOR="iPhone 16e" ./scripts/run.sh prod   # 覆盖目标模拟器
#
# 流程：
#   1. 校验 fvm / 环境文件 / 目标模拟器；
#   2. 模拟器未启动则 boot + bootstatus 阻塞等待就绪 + 打开 Simulator 窗口；
#   3. exec fvm flutter run -d <模拟器> --dart-define-from-file=env/<env>.json。
#
# 环境变量：
#   SIMULATOR  目标模拟器名（缺省 iPhone 17 Pro）
# ─────────────────────────────────────────────────────────────
set -euo pipefail

env_name="${1:-dev}"
device="${SIMULATOR:-iPhone 17 Pro}"
env_file="env/${env_name}.json"

usage() {
  cat >&2 <<EOF
用法: ./scripts/run.sh [dev|staging|prod]
      SIMULATOR="<模拟器名>" ./scripts/run.sh [dev|staging|prod]
EOF
}

# 环境参数白名单校验（拼错直接报错，不静默回落）
case "$env_name" in
  dev | staging | prod) ;;
  *)
    echo "错误：未知环境 '$env_name'（仅支持 dev / staging / prod）" >&2
    usage
    exit 1
    ;;
esac

# 前置检查：fvm 与环境文件
command -v fvm >/dev/null 2>&1 || {
  echo "错误：未找到 fvm 命令，请先安装 FVM（https://fvm.app/）" >&2
  exit 1
}
[[ -f "$env_file" ]] || {
  echo "错误：环境文件 $env_file 不存在" >&2
  exit 1
}

# 非 macOS 无法管理 iOS 模拟器：降级为不指定设备直接运行
if [[ "$(uname)" != "Darwin" ]]; then
  echo "提示：非 macOS 系统，跳过模拟器启动，由 flutter 自动选择已连接设备"
  exec fvm flutter run --dart-define-from-file="$env_file"
fi

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
