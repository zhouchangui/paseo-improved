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
ALL_SKILLS=("${SKILLS[@]}" using-upaseo)

echo "=== 1. YAML name 字段校验 ==="
for s in "${ALL_SKILLS[@]}"; do
  expected="$s"
  actual=$(grep "^name:" "$ROOT/$s/SKILL.md" 2>/dev/null | head -1 | sed 's/name: //')
  if [ "$actual" = "$expected" ]; then pass "$s"; else fail "$s: expected '$expected', got '$actual'"; fi
done

echo ""
echo "=== 2. 符号链接完整性 ==="
echo "--- 2.1 ~/.agents/skills/ 符号链接 ---"
for s in "${ALL_SKILLS[@]}"; do
  target=$(readlink "$HOME/.agents/skills/$s" 2>/dev/null || echo "")
  if [ -d "$target" ] && [ -f "$target/SKILL.md" ]; then pass "$s -> $target"; else fail "$s: ~/.agents/skills/ 链接无效或不存在"; fi
done
echo "--- 2.2 ~/.gemini/config/skills/ 符号链接 ---"
for s in "${ALL_SKILLS[@]}"; do
  target=$(readlink "$HOME/.gemini/config/skills/$s" 2>/dev/null || echo "")
  if [ -d "$target" ] && [ -f "$target/SKILL.md" ]; then pass "$s -> $target"; else fail "$s: ~/.gemini/config/skills/ 链接无效或不存在"; fi
done

echo ""
echo "=== 3. learnings 读取覆盖率 ==="
for s in "${ALL_SKILLS[@]}"; do
  if grep -q "learnings" "$ROOT/$s/SKILL.md" 2>/dev/null; then pass "$s"; else fail "$s: 无 learnings 引用"; fi
done

echo ""
echo "=== 4. 外部技能引用残留检测 ==="
found=$(grep -rn "brainstorming\|code-simplify\|code-reviewer\|karpathy-guidelines" "$ROOT"/*/SKILL.md "$ROOT"/using-upaseo/references/roles.md 2>/dev/null || true)
if [ -z "$found" ]; then pass "无外部技能引用残留"; else fail "发现外部引用: $found"; fi

echo ""
echo "=== 5. 计划文件路径一致性 ==="
bad_paths=$(grep -n '~/\.paseo/plans\|~/.paseo/plans' "$ROOT/using-upaseo/SKILL.md" 2>/dev/null || true)
if [ -z "$bad_paths" ]; then pass "路径统一为 .paseo/plans/ (项目根目录)"; else fail "发现 ~/.paseo/plans 引用: $bad_paths"; fi

echo ""
echo "=== 5.1 upaseo 与 using-upaseo 职责边界 ==="
grep -q "Foundation Reference" "$ROOT/upaseo/SKILL.md" && pass "upaseo 明确为底层基座参考" || fail "upaseo 未明确基座参考定位"
grep -q "not a user-facing development workflow\|not the product development workflow entrypoint" "$ROOT/upaseo/SKILL.md" && pass "upaseo 明确不是完整开发入口" || fail "upaseo 未声明非完整开发入口"
grep -q "唯一的完整开发工作流入口" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 明确为唯一完整开发入口" || fail "using-upaseo 未声明唯一完整开发入口"
grep -q "不得静默创建软链接" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 遵守 CLI 软链接需用户确认" || fail "using-upaseo 仍可能静默创建 CLI 软链接"

echo ""
echo "=== 6. roles.md 关键规程检查 ==="
roles="$ROOT/using-upaseo/references/roles.md"
grep -q "内联摘要\|按需读取" "$roles" && pass "精简传递策略" || fail "精简传递策略缺失"
grep -q "合规检查" "$roles" && pass "合规检查规程" || fail "合规检查规程缺失"
grep -q "完工通知\|Completion" "$roles" && pass "完工通知规程" || fail "完工通知规程缺失"
grep -q "story-updater" "$roles" && pass "story-updater 角色规程" || fail "story-updater 角色规程缺失"
grep -q "architecture-designer" "$roles" && pass "architecture-designer 计划评审角色" || fail "architecture-designer 计划评审角色缺失"
grep -q "feature-designer" "$roles" && pass "feature-designer 计划评审角色" || fail "feature-designer 计划评审角色缺失"
grep -q "test-strategist" "$roles" && pass "test-strategist 验收评审角色" || fail "test-strategist 验收评审角色缺失"

echo ""
echo "=== 7. 开发故事与历史资产目录机制校验 ==="
for t in stories data_models apis modules architecture_constraints coding_standards; do
  if [ -f "$ROOT/using-upaseo/references/${t}_template.md" ] || [ -f "$ROOT/upaseo-init/references/templates/${t}.md" ]; then pass "模板 $t 存在"; else fail "缺失模板 ${t}_template.md"; fi
done
if grep -q "mkdir -p.*\/story\|mkdir -p.*\.paseo\/story" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 story 目录初始化"; else fail "SKILL.md 缺失 story 目录创建"; fi
if grep -q "story-updater" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 story-updater 自动更新资产机制"; else fail "SKILL.md 缺失 story-updater 机制"; fi
if grep -q "stories.md" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 stories 资产历史强注入"; else fail "SKILL.md 缺失 stories 资产强注入"; fi
if grep -q "data_models.md" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 data_models 资产历史强注入"; else fail "SKILL.md 缺失 data_models 资产强注入"; fi
if grep -q "architecture_constraints.md" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 architecture_constraints 资产历史强注入"; else fail "SKILL.md 缺失 architecture_constraints 资产强注入"; fi
if grep -q "coding_standards.md" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 coding_standards 资产历史强注入"; else fail "SKILL.md 缺失 coding_standards 资产强注入"; fi
if grep -q "硬性读取顺序.*architecture_constraints.md.*coding_standards.md" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 明确子 Agent 必读架构约束与编码规范"; else fail "SKILL.md 缺失子 Agent 必读架构约束与编码规范"; fi
if grep -q "早期 tool call.*architecture_constraints.md.*coding_standards.md" "$ROOT/upaseo-loop/SKILL.md" 2>/dev/null; then pass "upaseo-loop verifier 检查架构约束与编码规范读取"; else fail "upaseo-loop 缺失架构约束与编码规范读取合规检查"; fi
if grep -q "迭代计划评审会" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null && grep -q "Design Council Log" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含迭代计划评审会与会议记录门槛"; else fail "SKILL.md 缺失迭代计划评审会或会议记录门槛"; fi
echo "--- 7.1 运行时 story 资产文件存在性 ---"
for t in stories data_models apis modules architecture_constraints coding_standards; do
  if [ -f "$ROOT/.paseo/story/${t}.md" ]; then pass ".paseo/story/${t}.md 存在"; else fail "缺失 .paseo/story/${t}.md"; fi
done

echo ""
echo "=== 7.2 quick/full 与 checkpoint 规程一致性 ==="
grep -q "最小主计划" "$ROOT/using-upaseo/SKILL.md" && grep -q "最小主计划" "$ROOT/using-upaseo/references/quick-mode.md" && pass "quick 模式创建最小主计划" || fail "quick 模式未明确创建最小主计划"
grep -q "轻量 upaseo-loop\|轻量 Loop" "$ROOT/using-upaseo/references/quick-mode.md" && ! grep -q "Agent 自行修改" "$ROOT/using-upaseo/references/quick-mode.md" && pass "quick 模式强制轻量 loop" || fail "quick 模式仍允许绕过 upaseo-loop"
grep -q "checkpoint commit" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 包含迭代 checkpoint commit" || fail "using-upaseo 缺失 checkpoint commit 规程"
grep -q "iter_<N>_design.md" "$ROOT/using-upaseo/SKILL.md" && pass "恢复流程兼容旧版 iter_N_design.md" || fail "恢复流程缺失旧计划文件兼容"

echo ""
echo "=== 8. upaseo-ship 核心发布规程校验 ==="
ship_roles="$ROOT/upaseo-ship/references/roles.md"
ship_skill="$ROOT/upaseo-ship/SKILL.md"
grep -q "release-auditor" "$ship_roles" 2>/dev/null && pass "角色 release-auditor 存在" || fail "角色 release-auditor 缺失"
grep -q "cleaner" "$ship_roles" 2>/dev/null && pass "角色 cleaner 存在" || fail "角色 cleaner 缺失"
grep -q "编译与测试阻断" "$ship_skill" 2>/dev/null && pass "SKILL.md 包含编译校验与阻断" || fail "SKILL.md 缺失编译与测试阻断"
grep -q "global-learnings.jsonl" "$ship_skill" 2>/dev/null && pass "SKILL.md 包含全局教训同步共享" || fail "SKILL.md 缺失 learnings 全局同步"
grep -q "PR 已经合并" "$ship_skill" 2>/dev/null && pass "SKILL.md 明确 ship 在 PR 合并后执行" || fail "SKILL.md 未明确 ship 在 PR 合并后执行"
grep -q "Release metadata commit" "$ship_skill" 2>/dev/null && pass "SKILL.md 包含 release metadata commit" || fail "SKILL.md 缺失 release metadata commit"
grep -q "不负责发起 feature 分支合并" "$ship_skill" 2>/dev/null && pass "SKILL.md 不在 ship 阶段发起 feature merge" || fail "SKILL.md 仍可能在 ship 阶段合并 feature 分支"

echo ""
echo "=== 9. upaseo-init 核心初始化与逆向规程校验 ==="
init_roles="$ROOT/upaseo-init/references/roles.md"
init_skill="$ROOT/upaseo-init/SKILL.md"
grep -q "story-architect" "$init_roles" 2>/dev/null && pass "角色 story-architect 存在" || fail "角色 story-architect 缺失"
grep -q "asset-reverse-engineer" "$init_roles" 2>/dev/null && pass "角色 asset-reverse-engineer 存在" || fail "角色 asset-reverse-engineer 缺失"
grep -q "目录" "$init_skill" 2>/dev/null && pass "SKILL.md 包含目录自愈初始化步骤" || fail "SKILL.md 缺失目录自愈初始化"
grep -q "扫描\|逆向" "$init_skill" 2>/dev/null && pass "SKILL.md 包含 codebase 逆向扫描步骤" || fail "SKILL.md 缺失 codebase 逆向扫描"
grep -q "stories.md.*data_models.md.*apis.md.*modules.md.*architecture_constraints.md.*coding_standards.md" "$init_skill" 2>/dev/null && pass "SKILL.md 包含六大资产写入规程" || fail "SKILL.md 缺失六大资产写入规程"
if grep -q "\.paseo/learnings/" "$init_skill" "$init_roles" 2>/dev/null; then fail "upaseo-init 仍引用错误的 .paseo/learnings/ 目录"; else pass "upaseo-init 使用 .paseo/learnings.jsonl 文件约定"; fi

echo ""
echo "========================================"
echo "结果: $PASS 通过, $FAIL 失败"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
