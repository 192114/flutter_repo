#!/usr/bin/env bash
# 一键检查：手写 Dart 格式（只读）、静态分析、全量测试；任一步失败即停止。
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$project_root"

if (( $# == 1 )) && [[ "$1" == "-h" || "$1" == "--help" ]]; then
  printf '%s\n' '用法: ./scripts/check.sh' '依次执行格式检查（不写文件）、静态分析和测试。'
  exit 0
fi
if (( $# > 0 )); then
  printf '错误：不支持的参数 %s（使用 --help 查看用法）\n' "$*" >&2
  exit 1
fi

command -v fvm >/dev/null 2>&1 || {
  printf '%s\n' '错误：未找到 fvm 命令，请先安装 FVM（https://fvm.app/）' >&2
  exit 1
}

find lib test -type f -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' -print0 |
  xargs -0 fvm dart format --output=none --set-exit-if-changed
fvm dart analyze --fatal-infos
fvm flutter test
