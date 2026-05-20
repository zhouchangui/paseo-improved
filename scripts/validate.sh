#!/usr/bin/env bash
# upaseo skill suite - 一致性验证脚本
# 用法: bash scripts/validate.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "  ✅ $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

SKILLS=(upaseo upaseo-advisor upaseo-brainstorm upaseo-committee upaseo-handoff upaseo-loop upaseo-reviewer upaseo-simplify upaseo-ship upaseo-init)
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
grep -q "story-updater" "$roles" && pass "story-updater 角色规程" || fail "story-updater 角色规程缺失"

echo ""
echo "=== 7. 开发故事与历史资产目录机制校验 ==="
for t in stories data_models apis modules; do
  if [ -f "$ROOT/using-paseo/references/${t}_template.md" ] || [ -f "$ROOT/upaseo-init/references/templates/${t}.md" ]; then pass "模板 $t 存在"; else fail "缺失模板 ${t}_template.md"; fi
done
if grep -q "mkdir -p.*\/story\|mkdir -p.*\.paseo\/story" "$ROOT/using-paseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 story 目录初始化"; else fail "SKILL.md 缺失 story 目录创建"; fi
if grep -q "story-updater" "$ROOT/using-paseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 story-updater 自动更新资产机制"; else fail "SKILL.md 缺失 story-updater 机制"; fi
if grep -q "stories.md" "$ROOT/using-paseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 stories 资产历史强注入"; else fail "SKILL.md 缺失 stories 资产强注入"; fi
if grep -q "data_models.md" "$ROOT/using-paseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 data_models 资产历史强注入"; else fail "SKILL.md 缺失 data_models 资产强注入"; fi

echo ""
echo "=== 8. upaseo-ship 核心发布规程校验 ==="
ship_roles="$ROOT/upaseo-ship/references/roles.md"
ship_skill="$ROOT/upaseo-ship/SKILL.md"
grep -q "release-auditor" "$ship_roles" 2>/dev/null && pass "角色 release-auditor 存在" || fail "角色 release-auditor 缺失"
grep -q "cleaner" "$ship_roles" 2>/dev/null && pass "角色 cleaner 存在" || fail "角色 cleaner 缺失"
grep -q "编译与测试阻断" "$ship_skill" 2>/dev/null && pass "SKILL.md 包含编译校验与阻断" || fail "SKILL.md 缺失编译与测试阻断"
grep -q "global-learnings.jsonl" "$ship_skill" 2>/dev/null && pass "SKILL.md 包含全局教训同步共享" || fail "SKILL.md 缺失 learnings 全局同步"

echo ""
echo "=== 9. upaseo-init 核心初始化与逆向规程校验 ==="
init_roles="$ROOT/upaseo-init/references/roles.md"
init_skill="$ROOT/upaseo-init/SKILL.md"
grep -q "story-architect" "$init_roles" 2>/dev/null && pass "角色 story-architect 存在" || fail "角色 story-architect 缺失"
grep -q "asset-reverse-engineer" "$init_roles" 2>/dev/null && pass "角色 asset-reverse-engineer 存在" || fail "角色 asset-reverse-engineer 缺失"
grep -q "目录" "$init_skill" 2>/dev/null && pass "SKILL.md 包含目录自愈初始化步骤" || fail "SKILL.md 缺失目录自愈初始化"
grep -q "扫描\|逆向" "$init_skill" 2>/dev/null && pass "SKILL.md 包含 codebase 逆向扫描步骤" || fail "SKILL.md 缺失 codebase 逆向扫描"
grep -q "stories.md.*data_models.md.*apis.md.*modules.md" "$init_skill" 2>/dev/null && pass "SKILL.md 包含四大资产写入规程" || fail "SKILL.md 缺失四大资产写入规程"

echo ""
echo "========================================"
echo "结果: $PASS 通过, $FAIL 失败"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi


