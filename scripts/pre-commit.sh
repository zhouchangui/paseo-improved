#!/usr/bin/env bash
# 本地 pre-commit hook: 在每次 commit 前运行 upaseo skill suite validate.sh。
# 安装方式: cp scripts/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
# 或在仓库根执行: git config core.hooksPath scripts/hooks  (见 scripts/hooks/)
#
# 行为: 运行 validate.sh；若存在硬失败（非符号链接类）则阻断 commit。
# 符号链接类失败（~/.agents/skills、~/.gemini/config/skills）属于本机部署态，
# 不应阻断他人或 CI 的 commit，因此只警告不阻断。

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [ ! -f "$ROOT/scripts/validate.sh" ]; then
  echo "[pre-commit] scripts/validate.sh 不存在，跳过校验" >&2
  exit 0
fi

echo "[pre-commit] 运行 upaseo skill suite validate.sh ..."
output="$(bash "$ROOT/scripts/validate.sh" 2>&1 || true)"

echo "$output" | tail -5 >&2

if echo "$output" | grep "❌" | grep -v "符号链接\|链接无效或不存在" > /tmp/precommit_hard_fails 2>/dev/null; then
  if [ -s /tmp/precommit_hard_fails ]; then
    echo "[pre-commit] ❌ 存在硬失败，commit 被阻断：" >&2
    cat /tmp/precommit_hard_fails >&2
    rm -f /tmp/precommit_hard_fails
    exit 1
  fi
fi

# 符号链接类失败仅警告
if echo "$output" | grep "❌" | grep "符号链接\|链接无效或不存在" > /tmp/precommit_link_fails 2>/dev/null; then
  if [ -s /tmp/precommit_link_fails ]; then
    echo "[pre-commit] ⚠️  存在符号链接类失败（本机部署态，不阻断 commit）：" >&2
    cat /tmp/precommit_link_fails >&2
  fi
fi

rm -f /tmp/precommit_hard_fails /tmp/precommit_link_fails
echo "[pre-commit] ✅ 无硬失败，允许 commit"
exit 0
