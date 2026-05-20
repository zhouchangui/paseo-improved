#!/usr/bin/env bash
# upaseo skill suite - 一致性验证脚本
# 用法: bash scripts/validate.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "  ✅ $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

SKILLS=(upaseo upaseo-advisor upaseo-brainstorm upaseo-committee upaseo-handoff upaseo-loop upaseo-reviewer upaseo-simplify)
ALL_SKILLS=("${SKILLS[@]}" using-paseo)

echo "=== 1. YAML name 字段校验 ==="
for s in "${ALL_SKILLS[@]}"; do
  expected="$s"
  actual=$(grep "^name:" "$ROOT/$s/SKILL.md" 2>/dev/null | head -1 | sed 's/name: //')
  if [ "$actual" = "$expected" ]; then pass "$s"; else fail "$s: expected '$expected', got '$actual'"; fi
done

echo ""
echo "=== 2. 符号链接完整性 ==="
for s in "${ALL_SKILLS[@]}"; do
  target=$(readlink "$HOME/.agents/skills/$s" 2>/dev/null || echo "")
  if [ -d "$target" ] && [ -f "$target/SKILL.md" ]; then pass "$s -> $target"; else fail "$s: 链接无效或不存在"; fi
done

echo ""
echo "=== 3. learnings 读取覆盖率 ==="
for s in "${ALL_SKILLS[@]}"; do
  if grep -q "learnings" "$ROOT/$s/SKILL.md" 2>/dev/null; then pass "$s"; else fail "$s: 无 learnings 引用"; fi
done

echo ""
echo "=== 4. 外部技能引用残留检测 ==="
found=$(grep -rn "brainstorming\|code-simplify\|code-reviewer\|karpathy-guidelines" "$ROOT"/*/SKILL.md "$ROOT"/using-paseo/references/roles.md 2>/dev/null || true)
if [ -z "$found" ]; then pass "无外部技能引用残留"; else fail "发现外部引用: $found"; fi

echo ""
echo "=== 5. 计划文件路径一致性 ==="
bad_paths=$(grep -n '~/\.paseo/plans\|~/.paseo/plans' "$ROOT/using-paseo/SKILL.md" 2>/dev/null || true)
if [ -z "$bad_paths" ]; then pass "路径统一为 .paseo/plans/ (项目根目录)"; else fail "发现 ~/.paseo/plans 引用: $bad_paths"; fi

echo ""
echo "=== 6. roles.md 关键规程检查 ==="
roles="$ROOT/using-paseo/references/roles.md"
grep -q "内联摘要\|按需读取" "$roles" && pass "精简传递策略" || fail "精简传递策略缺失"
grep -q "合规检查" "$roles" && pass "合规检查规程" || fail "合规检查规程缺失"
grep -q "完工通知\|Completion" "$roles" && pass "完工通知规程" || fail "完工通知规程缺失"

echo ""
echo "========================================"
echo "结果: $PASS 通过, $FAIL 失败"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
