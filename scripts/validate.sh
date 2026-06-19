#!/usr/bin/env bash
# upaseo skill suite - 一致性验证脚本
# 用法: bash scripts/validate.sh
#
# 三层架构（iter 5 重构）:
#   L1 结构层: 每个技能必须有 SKILL.md / 正确 frontmatter / 符号链接 / 目录结构
#   L2 交叉引用层: 技能间引用真实可解析 / 共享 reference 单一事实源 / 无遗留外部依赖
#   L3 行为层: 各技能规程条文存在 (worktree 隔离 / 状态机 / SoT 链 / drift 校验 / 发布 / e2e ...)
#
# 每条 check 调用 pass/fail 累计计数; 结尾汇总并按 FAIL 计数决定 exit code.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
L1_PASS=0; L1_FAIL=0
L2_PASS=0; L2_FAIL=0
L3_PASS=0; L3_FAIL=0
CURRENT_LAYER="L1"

pass() { echo "  ✅ $1"; PASS=$((PASS+1));
  case "$CURRENT_LAYER" in L1) L1_PASS=$((L1_PASS+1));; L2) L2_PASS=$((L2_PASS+1));; L3) L3_PASS=$((L3_PASS+1));; esac; }
fail() { echo "  ❌ $1"; FAIL=$((FAIL+1));
  case "$CURRENT_LAYER" in L1) L1_FAIL=$((L1_FAIL+1));; L2) L2_FAIL=$((L2_FAIL+1));; L3) L3_FAIL=$((L3_FAIL+1));; esac; }

SKILLS=(upaseo upaseo-advisor upaseo-brainstorm upaseo-committee upaseo-compact upaseo-e2e upaseo-goal upaseo-handoff upaseo-loop upaseo-reviewer upaseo-simplify upaseo-ship upaseo-init upaseo-todo)
ALL_SKILLS=("${SKILLS[@]}" using-upaseo)

# =============================================================================
# L1 结构层: 技能存在性、frontmatter、符号链接、目录骨架
# =============================================================================
CURRENT_LAYER="L1"
echo "=== L1.1 YAML name 字段校验 ==="
for s in "${ALL_SKILLS[@]}"; do
  expected="$s"
  actual=$(grep "^name:" "$ROOT/$s/SKILL.md" 2>/dev/null | head -1 | sed 's/name: //')
  if [ "$actual" = "$expected" ]; then pass "$s"; else fail "$s: expected '$expected', got '$actual'"; fi
done

echo ""
echo "=== L1.2 skill-creator 元数据与长度规范 ==="
for s in "${ALL_SKILLS[@]}"; do
  fm=$(awk 'BEGIN{c=0} /^---$/ {c++; next} c==1 {print}' "$ROOT/$s/SKILL.md" 2>/dev/null)
  extra=$(printf "%s\n" "$fm" | awk -F: '/^[A-Za-z0-9_-]+:/ { if ($1 != "name" && $1 != "description") print $1 }')
  if [ -z "$extra" ]; then pass "$s frontmatter 仅包含 name/description"; else fail "$s frontmatter 含非 skill-creator 字段: $extra"; fi
  body_lines=$(awk 'BEGIN{c=0;n=0} /^---$/ {c++; next} c>=2 {n++} END{print n}' "$ROOT/$s/SKILL.md" 2>/dev/null)
  if [ "$body_lines" -le 500 ]; then pass "$s body <= 500 lines"; else fail "$s body 超过 500 lines: $body_lines"; fi
done

echo ""
echo "=== L1.3 符号链接完整性 ==="
echo "--- 1.3.1 ~/.agents/skills/ 符号链接 ---"
for s in "${ALL_SKILLS[@]}"; do
  target=$(readlink "$HOME/.agents/skills/$s" 2>/dev/null || echo "")
  if [ -d "$target" ] && [ -f "$target/SKILL.md" ]; then pass "$s -> $target"; else fail "$s: ~/.agents/skills/ 链接无效或不存在"; fi
done
echo "--- 1.3.2 ~/.gemini/config/skills/ 符号链接 ---"
for s in "${ALL_SKILLS[@]}"; do
  target=$(readlink "$HOME/.gemini/config/skills/$s" 2>/dev/null || echo "")
  if [ -d "$target" ] && [ -f "$target/SKILL.md" ]; then pass "$s -> $target"; else fail "$s: ~/.gemini/config/skills/ 链接无效或不存在"; fi
done

echo ""
echo "=== L1.4 运行时目录骨架 ==="
# 核心持久化文件必须存在；on-demand 运行时目录 (goals/plans/compacts/handoffs) 由各自技能
# 在首次使用时创建，这里改为校验"技能声明了 on-demand 创建"而非目录本身存在。
[ -f "$ROOT/.paseo/todos.md" ] && pass ".paseo/todos.md 存在" || fail ".paseo/todos.md 缺失"
[ -f "$ROOT/.paseo/learnings.jsonl" ] && pass ".paseo/learnings.jsonl 存在" || fail ".paseo/learnings.jsonl 缺失"
grep -q "若 .*goals/.*不存在\|先创建目录" "$ROOT/upaseo-goal/SKILL.md" 2>/dev/null && pass "upaseo-goal 声明 goals 目录 on-demand 创建" || fail "upaseo-goal 未声明 goals 目录 on-demand 创建"
grep -q "mkdir -p.*compacts\|compacts/.*不存在.*先创建\|先创建目录" "$ROOT/upaseo-compact/SKILL.md" 2>/dev/null && pass "upaseo-compact 声明 compacts 目录 on-demand 创建" || fail "upaseo-compact 未声明 compacts 目录 on-demand 创建"
grep -q "handoffs/.*不存在.*先创建\|先创建目录" "$ROOT/upaseo-handoff/SKILL.md" 2>/dev/null && pass "upaseo-handoff 声明 handoffs 目录 on-demand 创建" || fail "upaseo-handoff 未声明 handoffs 目录 on-demand 创建"
[ -d "$ROOT/.github/issues" ] && pass ".github/issues 降级目录存在" || fail ".github/issues 降级目录不存在"
[ -d "$ROOT/docs/history" ] && pass "docs/history 归档目录存在" || fail "docs/history 归档目录不存在"
for t in stories data_models apis modules architecture_constraints coding_standards; do
  if [ -f "$ROOT/.agents/story/${t}.md" ]; then pass ".agents/story/${t}.md 存在"; else fail "缺失 .agents/story/${t}.md"; fi
done
old_story_refs=$(grep -rn "\.paseo/story" "$ROOT" --exclude-dir=.git --exclude="validate.sh" 2>/dev/null || true)
if [ -z "$old_story_refs" ]; then pass "无 .paseo/story 旧路径引用"; else fail "发现 .paseo/story 旧路径引用: $old_story_refs"; fi
[ -x "$ROOT/upaseo-e2e/scripts/report_issue.sh" ] && pass "report_issue.sh 可执行" || fail "report_issue.sh 缺失或不可执行"
[ -f "$ROOT/.codex/hooks.json" ] && [ -f "$ROOT/.codex/hooks/pre-compact.mjs" ] && [ -f "$ROOT/.codex/hooks/post-compact.mjs" ] && pass "compact hook 脚本与配置存在" || fail "compact hook 脚本或配置缺失"

# =============================================================================
# L2 交叉引用层: 技能间引用真实可解析 / 共享 reference 单一事实源 / 无遗留外部依赖
# =============================================================================
CURRENT_LAYER="L2"
echo ""
echo "=== L2.1 learnings 共享规程引用覆盖率 ==="
for s in "${ALL_SKILLS[@]}"; do
  if grep -q "learnings" "$ROOT/$s/SKILL.md" 2>/dev/null; then pass "$s"; else fail "$s: 无 learnings 引用"; fi
done
[ -f "$ROOT/upaseo/references/learnings-precheck.md" ] && pass "learnings-precheck.md 共享规程存在" || fail "learnings-precheck.md 共享规程缺失"
[ -f "$ROOT/upaseo/references/diff-asset-validation.md" ] && pass "diff-asset-validation.md 共享清单存在" || fail "diff-asset-validation.md 共享清单缺失"
[ -f "$ROOT/upaseo/references/roles.md" ] && pass "roles.md 总表存在" || fail "roles.md 总表缺失"
ref_count=$(grep -rl "执行标准避障前置读取" "$ROOT"/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
[ "$ref_count" -ge 10 ] && pass "至少 $ref_count 个技能引用 learnings-precheck 共享规程" || fail "引用 learnings-precheck 的技能数不足($ref_count)"
for sub in using-upaseo upaseo-init upaseo-ship; do
  grep -q "upaseo/references/roles.md" "$ROOT/$sub/references/roles.md" 2>/dev/null && pass "$sub roles.md 引用总表" || fail "$sub roles.md 未引用总表"
done

echo ""
echo "=== L2.2 遗留外部技能引用检测 ==="
found=$(grep -rn "brainstorming\|code-simplify\|code-reviewer" "$ROOT"/*/SKILL.md "$ROOT"/using-upaseo/references/roles.md 2>/dev/null || true)
if [ -z "$found" ]; then pass "无遗留外部技能引用残留"; else fail "发现遗留外部引用: $found"; fi
if grep -q "karpathy-guidelines" "$ROOT/upaseo-goal/SKILL.md" 2>/dev/null; then pass "upaseo-goal 允许显式应用 karpathy-guidelines"; else pass "未使用 karpathy-guidelines"; fi

echo ""
echo "=== L2.3 goal/plan 路径与目录契约 ==="
bad_paths=$(grep -n '~/\.paseo/plans\|~/.paseo/plans' "$ROOT/using-upaseo/SKILL.md" 2>/dev/null || true)
if [ -z "$bad_paths" ]; then pass "路径统一为 .paseo/plans/ (项目根目录)"; else fail "发现 ~/.paseo/plans 引用: $bad_paths"; fi
grep -q "\.paseo/goals/" "$ROOT/upaseo-goal/SKILL.md" && pass "upaseo-goal 写入 .paseo/goals/" || fail "upaseo-goal 未声明 .paseo/goals/"
grep -q "不调用 \`/goal\`\|不启动执行" "$ROOT/upaseo-goal/SKILL.md" && pass "upaseo-goal 只落盘不执行" || fail "upaseo-goal 仍可能启动执行"
grep -q "upaseo-goal.*可选流程\|可选 goal" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 将 upaseo-goal 视为可选流程" || fail "using-upaseo 未声明 goal 流程可选"
grep -q "\.paseo/goals/" "$ROOT/using-upaseo/SKILL.md" && grep -q "\.paseo/plans/" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 区分 goal 与 plan 目录" || fail "using-upaseo 缺失 goal/plan 目录分离"
grep -q "\.paseo/goals/" "$ROOT/README.md" && grep -q "\.paseo/goals/" "$ROOT/AGENTS.md" && pass "README 与 AGENTS.md 记录 goals 目录契约" || fail "README 或 AGENTS.md 缺失 goals 目录契约"
grep -q "upaseo-brainstorm" "$ROOT/upaseo-goal/SKILL.md" && grep -q "karpathy-guidelines" "$ROOT/upaseo-goal/SKILL.md" && grep -q "upaseo-simplify" "$ROOT/upaseo-goal/SKILL.md" && pass "upaseo-goal 集成 brainstorm/simplify/karpathy 原则" || fail "upaseo-goal 缺失目标收敛原则集成"
grep -q "^边界：" "$ROOT/upaseo-goal/SKILL.md" && grep -q "logs|tests|browser|manual|agent-run" "$ROOT/upaseo-goal/SKILL.md" && pass "upaseo-goal 模板包含边界与验证方法" || fail "upaseo-goal 模板缺失边界或验证方法"
[ -f "$ROOT/docs/history/requirement.md" ] && pass "requirement.md 已归档到 docs/history/" || fail "requirement.md 未归档"
grep -q "文件即上下文" "$ROOT/docs/history/requirement.md" 2>/dev/null && pass "归档 requirement.md 涵盖文件即上下文极简开发理念" || fail "归档 requirement.md 缺失文件即上下文规范"

echo ""
echo "=== L2.4 upaseo 与 using-upaseo 职责边界 ==="
grep -q "Foundation Reference" "$ROOT/upaseo/SKILL.md" && pass "upaseo 明确为底层基座参考" || fail "upaseo 未明确基座参考定位"
grep -q "not a user-facing development workflow\|not the product development workflow entrypoint" "$ROOT/upaseo/SKILL.md" && pass "upaseo 明确不是完整开发入口" || fail "upaseo 未声明非完整开发入口"
grep -q "唯一的完整开发工作流入口" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 明确为唯一完整开发入口" || fail "using-upaseo 未声明唯一完整开发入口"
grep -q "不得静默创建软链接" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 遵守 CLI 软链接需用户确认" || fail "using-upaseo 仍可能静默创建 CLI 软链接"
grep -q "会话隔离硬规则" "$ROOT/using-upaseo/SKILL.md" && grep -q "/upaseo-handoff --worktree" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo --worktree 强制 handoff 到新 worktree 会话" || fail "using-upaseo --worktree 缺失 handoff 会话隔离规则"
grep -q "Worktree 会话隔离" "$ROOT/README.md" && pass "README 记录 worktree 会话隔离机制" || fail "README 缺失 worktree 会话隔离机制"
grep -q "/upaseo-handoff --worktree" "$ROOT/using-upaseo/references/params.md" && grep -q "/upaseo-handoff --worktree" "$ROOT/using-upaseo/references/quick-mode.md" && pass "参数与快速模式文档记录 worktree handoff 规则" || fail "参数或快速模式文档缺失 worktree handoff 规则"

echo ""
echo "=== L2.5 roles.md 关键规程引用 ==="
roles="$ROOT/upaseo/references/roles.md"
grep -q "内联摘要\|按需读取" "$roles" && pass "精简传递策略" || fail "精简传递策略缺失"
grep -q "合规检查" "$roles" && pass "合规检查规程" || fail "合规检查规程缺失"
grep -q "完工通知\|Completion" "$roles" && pass "完工通知规程" || fail "完工通知规程缺失"
grep -q "story-updater" "$roles" && pass "story-updater 角色规程" || fail "story-updater 角色规程缺失"
grep -q "architecture-designer" "$roles" && pass "architecture-designer 计划评审角色" || fail "architecture-designer 计划评审角色缺失"
grep -q "feature-designer" "$roles" && pass "feature-designer 计划评审角色" || fail "feature-designer 计划评审角色缺失"
grep -q "test-strategist" "$roles" && pass "test-strategist 验收评审角色" || fail "test-strategist 验收评审角色缺失"
grep -q "文件即上下文" "$ROOT/upaseo/references/roles.md" && pass "roles.md 总表的 Orchestrator 职责包含文件即上下文" || fail "roles.md 总表缺失编排器文件即上下文要求"

echo ""
echo "=== L2.6 story 资产目录机制 ==="
for t in stories data_models apis modules architecture_constraints coding_standards; do
  if [ -f "$ROOT/using-upaseo/references/${t}_template.md" ] || [ -f "$ROOT/upaseo-init/references/templates/${t}.md" ]; then pass "模板 $t 存在"; else fail "缺失模板 ${t}_template.md"; fi
done
if grep -q "mkdir -p.*\.agents/story" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 .agents/story 目录初始化"; else fail "SKILL.md 缺失 .agents/story 目录创建"; fi
if grep -q "AGENTS.md" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null && grep -q "AGENTS.md" "$ROOT/upaseo-init/SKILL.md" 2>/dev/null; then pass "using-upaseo 与 upaseo-init 包含 AGENTS.md 引用自愈"; else fail "缺失 AGENTS.md 创建或引用自愈规程"; fi
if grep -q "\.agents/story" "$ROOT/AGENTS.md" 2>/dev/null; then pass "根 AGENTS.md 引用 .agents/story 资产库"; else fail "根 AGENTS.md 缺失 .agents/story 引用"; fi
if grep -q "stories.md" "$ROOT/AGENTS.md" 2>/dev/null && grep -q "data_models.md" "$ROOT/AGENTS.md" 2>/dev/null && grep -q "apis.md" "$ROOT/AGENTS.md" 2>/dev/null && grep -q "modules.md" "$ROOT/AGENTS.md" 2>/dev/null && grep -q "architecture_constraints.md" "$ROOT/AGENTS.md" 2>/dev/null && grep -q "coding_standards.md" "$ROOT/AGENTS.md" 2>/dev/null; then pass "根 AGENTS.md 列出六大资产文件"; else fail "根 AGENTS.md 未列全六大资产文件"; fi
if grep -q "story-updater" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 story-updater 自动更新资产机制"; else fail "SKILL.md 缺失 story-updater 机制"; fi
if grep -q "stories.md" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 stories 资产历史强注入"; else fail "SKILL.md 缺失 stories 资产强注入"; fi
if grep -q "data_models.md" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 data_models 资产历史强注入"; else fail "SKILL.md 缺失 data_models 资产强注入"; fi
if grep -q "architecture_constraints.md" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 architecture_constraints 资产历史强注入"; else fail "SKILL.md 缺失 architecture_constraints 资产强注入"; fi
if grep -q "coding_standards.md" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含 coding_standards 资产历史强注入"; else fail "SKILL.md 缺失 coding_standards 资产强注入"; fi
if grep -q "硬性读取顺序.*architecture_constraints.md.*coding_standards.md" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 明确子 Agent 必读架构约束与编码规范"; else fail "SKILL.md 缺失子 Agent 必读架构约束与编码规范"; fi
if grep -q "早期动作.*architecture_constraints.md.*coding_standards.md\|路径被读取" "$ROOT/upaseo-loop/SKILL.md" 2>/dev/null; then pass "upaseo-loop verifier 检查架构约束与编码规范读取(语义化)"; else fail "upaseo-loop 缺失架构约束与编码规范读取合规检查"; fi
if grep -q "迭代计划评审会" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null && grep -q "Design Council Log" "$ROOT/using-upaseo/SKILL.md" 2>/dev/null; then pass "SKILL.md 包含迭代计划评审会与会议记录门槛"; else fail "SKILL.md 缺失迭代计划评审会或会议记录门槛"; fi

# =============================================================================
# L3 行为层: 各技能关键规程条文存在
# =============================================================================
CURRENT_LAYER="L3"

echo ""
echo "=== L3.1 using-upaseo 文件即上下文与高稳健性架构 ==="
grep -q "文件即上下文" "$ROOT/using-upaseo/SKILL.md" && pass "SKILL.md 包含文件即上下文规约" || fail "SKILL.md 缺失文件即上下文规约"
grep -q "State: Designing\|State: Implementing\|State: Verifying" "$ROOT/using-upaseo/SKILL.md" && pass "SKILL.md 断电现场现场恢复自愈状态机完整" || fail "SKILL.md 缺失断电现场恢复状态机"
grep -q "自适应评审会分级" "$ROOT/using-upaseo/SKILL.md" && pass "SKILL.md 包含自适应评审会分级（轻重自适应）" || fail "SKILL.md 缺失评审会自适应分级规程"
grep -q "PR Fallback" "$ROOT/using-upaseo/SKILL.md" && pass "SKILL.md 包含 PR Fallback 智能兜底机制" || fail "SKILL.md 缺失 PR 智能兜底机制"
grep -q "资产防事实漂移" "$ROOT/using-upaseo/SKILL.md" && pass "SKILL.md 包含资产防事实漂移校验（Diff-Asset）" || fail "SKILL.md 缺失防资产漂移校验"

echo ""
echo "=== L3.2 quick/full 与 checkpoint 规程一致性 ==="
grep -q "最小主计划" "$ROOT/using-upaseo/SKILL.md" && grep -q "最小主计划" "$ROOT/using-upaseo/references/quick-mode.md" && pass "quick 模式创建最小主计划" || fail "quick 模式未明确创建最小主计划"
grep -q "微改快速通道" "$ROOT/using-upaseo/SKILL.md" && grep -q "Micro-Change Decision" "$ROOT/using-upaseo/references/quick-mode.md" && grep -q "跳过 TDD/loop" "$ROOT/README.md" && pass "微改快速通道允许确定性小改跳过 TDD/loop" || fail "微改快速通道规程缺失"
grep -q "轻量 upaseo-loop\|轻量 Loop" "$ROOT/using-upaseo/references/quick-mode.md" && grep -q "有行为风险" "$ROOT/using-upaseo/references/quick-mode.md" && pass "quick 模式对行为风险小改仍使用轻量 loop" || fail "quick 模式缺失行为风险 loop 边界"
grep -q "checkpoint commit" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 包含迭代 checkpoint commit" || fail "using-upaseo 缺失 checkpoint commit 规程"
grep -q "iter_<N>_design.md" "$ROOT/using-upaseo/SKILL.md" && pass "恢复流程兼容旧版 iter_N_design.md" || fail "恢复流程缺失旧计划文件兼容"

echo ""
echo "=== L3.3 upaseo-ship 核心发布规程 ==="
ship_roles="$ROOT/upaseo-ship/references/roles.md"
ship_skill="$ROOT/upaseo-ship/SKILL.md"
grep -q "release-auditor" "$ship_roles" 2>/dev/null && pass "角色 release-auditor 存在" || fail "角色 release-auditor 缺失"
grep -q "cleaner" "$ship_roles" 2>/dev/null && pass "角色 cleaner 存在" || fail "角色 cleaner 缺失"
grep -q "编译与测试阻断" "$ship_skill" 2>/dev/null && pass "SKILL.md 包含编译校验与阻断" || fail "SKILL.md 缺失编译与测试阻断"
grep -q "global-learnings.jsonl" "$ship_skill" 2>/dev/null && pass "SKILL.md 包含全局教训同步共享" || fail "SKILL.md 缺失 learnings 全局同步"
grep -q "PR 已经合并" "$ship_skill" 2>/dev/null && pass "SKILL.md 明确 ship 在 PR 合并后执行" || fail "SKILL.md 未明确 ship 在 PR 合并后执行"
grep -q "Release metadata commit" "$ship_skill" 2>/dev/null && pass "SKILL.md 包含 release metadata commit" || fail "SKILL.md 缺失 release metadata commit"
grep -q "不负责发起 feature 分支合并" "$ship_skill" 2>/dev/null && pass "SKILL.md 不在 ship 阶段发起 feature merge" || fail "SKILL.md 仍可能在 ship 阶段合并 feature 分支"
grep -q "\.paseo/todos.md" "$ship_skill" 2>/dev/null && grep -q "只关闭有证据" "$ship_skill" 2>/dev/null && pass "SKILL.md 包含项目 todo 发布关闭规程" || fail "SKILL.md 缺失项目 todo 发布关闭规程"
grep -q "写入方闭环\|先读 global" "$ship_skill" 2>/dev/null && pass "ship global-learnings 写入方声明读取闭环" || fail "ship global-learnings 仍为只写死功能"

echo ""
echo "=== L3.4 learnings 系统规程 ==="
learnings_ref="$ROOT/upaseo/references/learnings-precheck.md"
grep -q "category 作用域过滤\|category 作用域" "$learnings_ref" 2>/dev/null && pass "learnings-precheck 定义 category 作用域过滤" || fail "learnings-precheck 缺失 category 作用域过滤"
grep -q "先读全局\|先读 global\|global-learnings.jsonl" "$learnings_ref" 2>/dev/null && pass "learnings-precheck 定义 global+项目读取顺序" || fail "learnings-precheck 缺失 global 读取顺序"
grep -q "老化\|aged" "$learnings_ref" 2>/dev/null && pass "learnings-precheck 定义老化降级规则" || fail "learnings-precheck 缺失老化降级规则"
grep -q "last_confirmed" "$learnings_ref" 2>/dev/null && pass "learnings-precheck 定义 last_confirmed 字段" || fail "learnings-precheck 缺失 last_confirmed 字段"

echo ""
echo "=== L3.5 upaseo-compact 核心压缩规程 ==="
compact_skill="$ROOT/upaseo-compact/SKILL.md"
grep -q "\.paseo/compacts" "$compact_skill" 2>/dev/null && pass "upaseo-compact 写入 .paseo/compacts 恢复文档" || fail "upaseo-compact 缺失 compact 文档路径"
grep -q "Restore Prompt" "$compact_skill" 2>/dev/null && grep -q "恢复提示词" "$compact_skill" 2>/dev/null && pass "upaseo-compact 生成恢复提示词" || fail "upaseo-compact 缺失恢复提示词规程"
grep -q "Source of Truth" "$compact_skill" 2>/dev/null && pass "upaseo-compact 明确 compact 文档为事实源" || fail "upaseo-compact 未声明事实源"
grep -q "不要依赖系统 compact" "$compact_skill" 2>/dev/null && pass "upaseo-compact 替代系统 compact 摘要" || fail "upaseo-compact 未明确替代系统 compact"
grep -q "git status" "$compact_skill" 2>/dev/null && grep -q "Validation Evidence" "$compact_skill" 2>/dev/null && pass "upaseo-compact 记录工作区状态与验证证据" || fail "upaseo-compact 缺失状态或验证证据"
grep -q "Codex hooks 自愈\|先自动补齐再继续 compact" "$compact_skill" 2>/dev/null && grep -q "宿主探测\|非 Codex 宿主" "$compact_skill" 2>/dev/null && pass "upaseo-compact 会先做宿主探测并自愈 hooks 安装" || fail "upaseo-compact 缺失 hooks 自愈安装规程"
grep -q "PreCompact" "$ROOT/.codex/hooks.json" 2>/dev/null && grep -q "PostCompact" "$ROOT/.codex/hooks.json" 2>/dev/null && pass "项目级 Codex hooks 已接入 compact 自动化" || fail "缺失项目级 compact hooks 配置"
grep -q "fail-open" "$compact_skill" 2>/dev/null && pass "upaseo-compact 声明 hook 失败时 fail-open" || fail "upaseo-compact 未声明 hook fail-open"

echo ""
echo "=== L3.6 upaseo-init 核心初始化与逆向规程 ==="
init_roles="$ROOT/upaseo-init/references/roles.md"
init_skill="$ROOT/upaseo-init/SKILL.md"
roles_total="$ROOT/upaseo/references/roles.md"
grep -q "story-architect" "$roles_total" 2>/dev/null && pass "角色 story-architect 存在(总表)" || fail "角色 story-architect 缺失"
grep -q "asset-reverse-engineer" "$roles_total" 2>/dev/null && pass "角色 asset-reverse-engineer 存在(总表)" || fail "角色 asset-reverse-engineer 缺失"
grep -q "目录" "$init_skill" 2>/dev/null && pass "SKILL.md 包含目录自愈初始化步骤" || fail "SKILL.md 缺失目录自愈初始化"
grep -q "AGENTS.md" "$init_skill" 2>/dev/null && grep -q "AGENTS.md" "$init_roles" 2>/dev/null && pass "upaseo-init 创建或修复 AGENTS.md 根指引" || fail "upaseo-init 缺失 AGENTS.md 根指引规程"
grep -q "扫描\|逆向" "$init_skill" 2>/dev/null && pass "SKILL.md 包含 codebase 逆向扫描步骤" || fail "SKILL.md 缺失 codebase 逆向扫描"
grep -q "stories.md.*data_models.md.*apis.md.*modules.md.*architecture_constraints.md.*coding_standards.md" "$init_skill" 2>/dev/null && pass "SKILL.md 包含六大资产写入规程" || fail "SKILL.md 缺失六大资产写入规程"
if grep -q "\.paseo/learnings/" "$init_skill" "$init_roles" 2>/dev/null; then fail "upaseo-init 仍引用错误的 .paseo/learnings/ 目录"; else pass "upaseo-init 使用 .paseo/learnings.jsonl 文件约定"; fi

echo ""
echo "=== L3.7 upaseo-todo 核心待办规程 ==="
todo_skill="$ROOT/upaseo-todo/SKILL.md"
grep -q "\.paseo/todos.md" "$todo_skill" 2>/dev/null && pass "upaseo-todo 写入 .paseo/todos.md" || fail "upaseo-todo 缺失 todos 文件路径"
grep -q "Source of Truth" "$todo_skill" 2>/dev/null && pass "upaseo-todo 声明 todos 文件为事实源" || fail "upaseo-todo 未声明 Source of Truth"
grep -q "用户明确提到.*todo" "$todo_skill" 2>/dev/null && grep -q "待办" "$todo_skill" 2>/dev/null && pass "upaseo-todo 明确 todo/待办触发记录" || fail "upaseo-todo 缺失触发记录规则"
grep -q "## Active" "$ROOT/.paseo/todos.md" 2>/dev/null && grep -q "## Done" "$ROOT/.paseo/todos.md" 2>/dev/null && pass ".paseo/todos.md 模板存在" || fail ".paseo/todos.md 缺失基础模板"
grep -q "Ship Integration" "$todo_skill" 2>/dev/null && grep -q "只关闭有证据" "$todo_skill" 2>/dev/null && pass "upaseo-todo 包含 ship 完成状态更新规则" || fail "upaseo-todo 缺失 ship 状态更新规则"
grep -q "upaseo-todo" "$ROOT/README.md" 2>/dev/null && grep -q "\.paseo/todos.md" "$ROOT/README.md" 2>/dev/null && pass "README 注册 upaseo-todo 与 todos 文件" || fail "README 缺失 upaseo-todo 注册"
grep -q "\.paseo/todos.md" "$ROOT/AGENTS.md" 2>/dev/null && pass "AGENTS.md 记录 todo 工作流约定" || fail "AGENTS.md 缺失 todo 工作流约定"

echo ""
echo "=== L3.8 upaseo-e2e 集成测试规程 ==="
e2e_skill="$ROOT/upaseo-e2e/SKILL.md"
grep -q "冻结测试环境" "$e2e_skill" 2>/dev/null && grep -q "先写测试用例" "$e2e_skill" 2>/dev/null && pass "upaseo-e2e 先冻结环境再写 case" || fail "upaseo-e2e 缺失环境冻结或 case-first 规则"
grep -q "人工确认" "$e2e_skill" 2>/dev/null && grep -q "用户明确回复" "$e2e_skill" 2>/dev/null && pass "upaseo-e2e 在执行前要求人工确认" || fail "upaseo-e2e 缺失人工确认门槛"
grep -q "默认全部使用中文输出" "$e2e_skill" 2>/dev/null && grep -q "命令、路径、环境变量名" "$e2e_skill" 2>/dev/null && pass "upaseo-e2e 明确中文输出约束" || fail "upaseo-e2e 缺失中文输出约束"
grep -q "CLI 验证必须树形全部覆盖" "$e2e_skill" 2>/dev/null && grep -q "CLI 覆盖摘要" "$e2e_skill" 2>/dev/null && pass "upaseo-e2e 包含 CLI 树形全部覆盖要求" || fail "upaseo-e2e 缺失 CLI 树形覆盖规程"
grep -q "| Case ID | 测试面 | 前置条件 | 操作 | 验证方式 | 证据 | 状态 |" "$e2e_skill" 2>/dev/null && grep -q "## 环境冻结" "$e2e_skill" 2>/dev/null && pass "upaseo-e2e 推荐模板默认中文输出" || fail "upaseo-e2e 推荐模板未默认使用中文"
grep -q "失败先复现" "$e2e_skill" 2>/dev/null && grep -q "gh issue create" "$e2e_skill" 2>/dev/null && grep -q "\.github/issues/" "$e2e_skill" 2>/dev/null && pass "upaseo-e2e 包含复现优先与 issue 双通道上报" || fail "upaseo-e2e 缺失复现或 issue 上报规程"
grep -q "状态：本地降级记录" "$ROOT/upaseo-e2e/scripts/report_issue.sh" 2>/dev/null && grep -q "GH 降级原因" "$ROOT/upaseo-e2e/scripts/report_issue.sh" 2>/dev/null && pass "upaseo-e2e 本地 issue 降级头部默认中文输出" || fail "upaseo-e2e 本地 issue 降级头部未默认中文输出"
grep -q "upaseo-e2e" "$ROOT/README.md" 2>/dev/null && grep -q "\.github/issues" "$ROOT/README.md" 2>/dev/null && pass "README 注册 upaseo-e2e 与 issue 降级目录" || fail "README 缺失 upaseo-e2e 注册"
grep -q "upaseo-e2e" "$ROOT/AGENTS.md" 2>/dev/null && pass "AGENTS.md 记录 upaseo-e2e 工作流" || fail "AGENTS.md 缺失 upaseo-e2e 工作流约定"
grep -q "upaseo-e2e" "$ROOT/.agents/story/modules.md" 2>/dev/null && pass "模块资产记录 upaseo-e2e 模块职责" || fail "模块资产缺失 upaseo-e2e"
grep -q "\.github/issues/" "$ROOT/.agents/story/architecture_constraints.md" 2>/dev/null && pass "架构资产记录 issue 本地降级边界" || fail "架构资产缺失 issue 降级边界"
grep -q "人工确认" "$ROOT/.agents/story/coding_standards.md" 2>/dev/null && grep -q "树形全部覆盖" "$ROOT/.agents/story/coding_standards.md" 2>/dev/null && grep -q "gh issue create" "$ROOT/.agents/story/coding_standards.md" 2>/dev/null && pass "编码规范记录 e2e 确认、覆盖与上报规程" || fail "编码规范缺失 e2e 规程"

echo ""
echo "=== L3.9 SoT 优先级链与 plan schema_version (iter 4) ==="
upaseo_skill="$ROOT/upaseo/SKILL.md"
using_skill="$ROOT/using-upaseo/SKILL.md"
grep -q "Source-of-Truth Priority Chain" "$upaseo_skill" 2>/dev/null && pass "upaseo 定义 Source-of-Truth Priority Chain 单一事实源" || fail "upaseo 缺失 SoT 优先级链定义"
grep -q "compact" "$upaseo_skill" 2>/dev/null && grep -q "handoff" "$upaseo_skill" 2>/dev/null && grep -q "plan" "$upaseo_skill" 2>/dev/null && grep -q "goal" "$upaseo_skill" 2>/dev/null && grep -q "compact > handoff > plan > goal\|compact.*handoff.*plan.*goal" "$upaseo_skill" 2>/dev/null && pass "SoT 链顺序为 compact > handoff > plan > goal" || fail "SoT 链顺序缺失或不正确"
grep -q "goal.*不可被覆盖\|immutab\|不可被更高优先级" "$upaseo_skill" 2>/dev/null && pass "SoT 链声明 goal 边界不可被覆盖" || fail "SoT 链缺失 goal 不可覆盖约束"
grep -q "Priority: compact" "$ROOT/upaseo-compact/SKILL.md" 2>/dev/null && pass "compact 文档模板声明 Priority: compact" || fail "compact 文档模板缺失 Priority: compact"
grep -q "Priority: handoff" "$ROOT/upaseo-handoff/SKILL.md" 2>/dev/null && pass "handoff 文档模板声明 Priority: handoff" || fail "handoff 文档模板缺失 Priority: handoff"
grep -q "Priority: plan" "$using_skill" 2>/dev/null && pass "plan 文档模板声明 Priority: plan" || fail "plan 文档模板缺失 Priority: plan"
grep -q "Priority: goal" "$ROOT/upaseo-goal/SKILL.md" 2>/dev/null && pass "goal 文档模板声明 Priority: goal" || fail "goal 文档模板缺失 Priority: goal"
grep -q "schema_version: 1" "$using_skill" 2>/dev/null && pass "plan 模板含 schema_version: 1" || fail "plan 模板缺失 schema_version: 1"
grep -q "schema_version 迁移规则\|schema_version.*迁移" "$using_skill" 2>/dev/null && pass "异常恢复含 schema_version 迁移规则" || fail "异常恢复缺失 schema_version 迁移规则"
grep -q "schema_version: 0" "$using_skill" 2>/dev/null && grep -q "schema_version: 2" "$using_skill" 2>/dev/null && pass "迁移规则覆盖 v0 兼容与 v2 未来触发" || fail "迁移规则未覆盖 v0/v2 版本"
grep -q "Source-of-Truth Priority Chain\|SoT 优先级链" "$using_skill" 2>/dev/null && pass "using-upaseo 异常恢复引用 SoT 优先级链" || fail "using-upaseo 异常恢复未引用 SoT 链"
[ -f "$ROOT/upaseo/references/diff-asset-validation.md" ] && pass "资产防漂移校验清单 reference 存在" || fail "资产防漂移校验清单 reference 缺失"
grep -q "diff-asset-validation.md" "$using_skill" 2>/dev/null && pass "using-upaseo §5.F 引用 diff-asset-validation 清单" || fail "using-upaseo §5.F 未引用 diff-asset-validation 清单"
grep -q "diff-asset-validation.md" "$ROOT/upaseo-ship/SKILL.md" 2>/dev/null && pass "upaseo-ship 发布前复核引用 diff-asset-validation 清单" || fail "upaseo-ship 未引用 diff-asset-validation 清单"
grep -q "\[write\]\|\[drop\]\|\[hold\]" "$ROOT/upaseo/references/diff-asset-validation.md" 2>/dev/null && pass "diff-asset-validation 定义三方对照登记规则" || fail "diff-asset-validation 缺失三方对照登记规则"
grep -q -- "--lang en|zh\|--lang en\b" "$ROOT/upaseo-e2e/SKILL.md" 2>/dev/null && pass "upaseo-e2e 支持 --lang en|zh 参数" || fail "upaseo-e2e 缺失 --lang 参数"
grep -q -- "--lang" "$ROOT/upaseo-e2e/scripts/report_issue.sh" 2>/dev/null && pass "report_issue.sh 支持 --lang 参数" || fail "report_issue.sh 缺失 --lang 参数"
grep -q "issue-\|shasum\|BYTE_HASH" "$ROOT/upaseo-e2e/scripts/report_issue.sh" 2>/dev/null && pass "report_issue.sh 纯中文标题生成非空 slug 兜底" || fail "report_issue.sh 缺失中文标题 slug 兜底"
grep -q "Status: local-fallback" "$ROOT/upaseo-e2e/scripts/report_issue.sh" 2>/dev/null && grep -q "状态：本地降级记录" "$ROOT/upaseo-e2e/scripts/report_issue.sh" 2>/dev/null && pass "report_issue.sh --lang 切换中英文头部" || fail "report_issue.sh 未支持中英文头部切换"

echo ""
echo "=== L3.10 ponytail 精简阶梯 + ocr 审查引擎 (iter 6) ==="
ladder_ref="$ROOT/upaseo/references/simplify-ladder.md"
simplify_skill="$ROOT/upaseo-simplify/SKILL.md"
reviewer_skill="$ROOT/upaseo-reviewer/SKILL.md"
[ -f "$ladder_ref" ] && pass "simplify-ladder.md 共享单一事实源存在" || fail "simplify-ladder.md 共享单一事实源缺失"
grep -q "精简阶梯\|Simplification Ladder" "$ladder_ref" 2>/dev/null && pass "simplify-ladder 定义精简阶梯" || fail "simplify-ladder 缺失精简阶梯定义"
grep -q "1" "$ladder_ref" 2>/dev/null && grep -q "6" "$ladder_ref" 2>/dev/null && grep -q "YAGNI" "$ladder_ref" 2>/dev/null && grep -q "标准库" "$ladder_ref" 2>/dev/null && pass "simplify-ladder 定义完整 6 级 ladder" || fail "simplify-ladder 6 级 ladder 不完整"
grep -q "删除清单\|Delete-List" "$ladder_ref" 2>/dev/null && pass "simplify-ladder 定义删除清单" || fail "simplify-ladder 缺失删除清单"
grep -q "\[cut\]\|\[shrink\]\|\[keep\]" "$ladder_ref" 2>/dev/null && pass "simplify-ladder 定义 [cut]/[shrink]/[keep] 登记" || fail "simplify-ladder 缺失删除清单登记规则"
grep -q "type: debt\|延迟债务\|Deferred Debt" "$ladder_ref" 2>/dev/null && pass "simplify-ladder 定义延迟债务 type:debt" || fail "simplify-ladder 缺失延迟债务定义"
grep -q "安全红线\|Safety Boundary\|永不入删除清单" "$ladder_ref" 2>/dev/null && pass "simplify-ladder 定义安全红线" || fail "simplify-ladder 缺失安全红线"
grep -q "项目类型条件\|代码扩展名\|纯 markdown\|降级为一句话" "$ladder_ref" 2>/dev/null && pass "simplify-ladder 定义项目类型条件启用" || fail "simplify-ladder 缺失项目类型条件启用"
grep -q "simplify-ladder.md" "$simplify_skill" 2>/dev/null && pass "upaseo-simplify 引用 simplify-ladder.md" || fail "upaseo-simplify 未引用 simplify-ladder.md"
grep -q "删除清单\|Delete-List" "$simplify_skill" 2>/dev/null && pass "upaseo-simplify 含删除清单规程" || fail "upaseo-simplify 缺失删除清单规程"
grep -q "type: debt\|延迟债务" "$simplify_skill" 2>/dev/null && pass "upaseo-simplify 含延迟债务登记" || fail "upaseo-simplify 缺失延迟债务登记"
grep -q "完整 6 级\|轻量删除清单\|跳过 simplify" "$simplify_skill" 2>/dev/null && pass "upaseo-simplify 强度挂靠执行模式" || fail "upaseo-simplify 缺失强度挂靠执行模式"
grep -q "审查引擎分层\|Review Engine Tiers" "$reviewer_skill" 2>/dev/null && pass "upaseo-reviewer 定义审查引擎分层" || fail "upaseo-reviewer 缺失审查引擎分层"
grep -q "ocr review" "$reviewer_skill" 2>/dev/null && pass "upaseo-reviewer Tier 1 调 ocr review" || fail "upaseo-reviewer 缺失 ocr review 调用"
grep -q -- "--audience agent" "$reviewer_skill" 2>/dev/null && pass "upaseo-reviewer ocr 调用含 --audience agent" || fail "upaseo-reviewer ocr 调用缺失 --audience agent"
grep -q "Tier 2\|Agent 模拟审计" "$reviewer_skill" 2>/dev/null && pass "upaseo-reviewer 定义 Tier 2 降级" || fail "upaseo-reviewer 缺失 Tier 2 降级"
grep -q "blocker" "$reviewer_skill" 2>/dev/null && grep -q "minor" "$reviewer_skill" 2>/dev/null && pass "upaseo-reviewer 定义 blocker/minor 严重度分级" || fail "upaseo-reviewer 缺失严重度分级"
grep -q "ocr llm test\|command -v ocr" "$reviewer_skill" 2>/dev/null && pass "upaseo-reviewer 含 ocr 可用性自检" || fail "upaseo-reviewer 缺失 ocr 可用性自检"
grep -q "simplify-ladder.md\|精简阶梯前置门\|Simplification Ladder Gate" "$using_skill" 2>/dev/null && pass "using-upaseo §5.C 含阶梯前置门" || fail "using-upaseo §5.C 缺失阶梯前置门"
grep -q "删除清单\|Delete-List" "$using_skill" 2>/dev/null && pass "using-upaseo §6 item1 含删除清单" || fail "using-upaseo §6 item1 缺失删除清单"
grep -q "type: debt" "$using_skill" 2>/dev/null && pass "using-upaseo §6 item1 含 type:debt 登记" || fail "using-upaseo §6 item1 缺失 type:debt 登记"
grep -q "ocr review" "$using_skill" 2>/dev/null && pass "using-upaseo §6 item2 编排 ocr review" || fail "using-upaseo §6 item2 缺失 ocr review 编排"
grep -q "降级 Tier 2\|降级.*Agent 模拟审计\|Tier 2" "$using_skill" 2>/dev/null && pass "using-upaseo §6 item2 含 ocr 降级路径" || fail "using-upaseo §6 item2 缺失 ocr 降级路径"
grep -q "type: <task|debt>\|type: debt" "$ROOT/upaseo-todo/SKILL.md" 2>/dev/null && pass "upaseo-todo entry 格式含 type: 字段" || fail "upaseo-todo entry 格式缺失 type: 字段"
grep -q "type: debt" "$ROOT/upaseo-ship/SKILL.md" 2>/dev/null && pass "upaseo-ship 复核 type:debt 延迟债务" || fail "upaseo-ship 缺失 type:debt 复核"
grep -q "代码精简阶梯" "$ROOT/.agents/story/coding_standards.md" 2>/dev/null && pass "coding_standards 记录代码精简阶梯规程" || fail "coding_standards 缺失代码精简阶梯规程"
grep -q "代码审查引擎分层\|ocr" "$ROOT/.agents/story/coding_standards.md" 2>/dev/null && pass "coding_standards 记录代码审查引擎分层规程" || fail "coding_standards 缺失代码审查引擎分层规程"
grep -q "ponytail\|精简阶梯" "$ROOT/.agents/story/architecture_constraints.md" 2>/dev/null && pass "architecture_constraints 记录 ladder 条件启用边界" || fail "architecture_constraints 缺失 ladder 边界"
grep -q "ocr.*可选外部\|ocr.*降级\|open-code-review" "$ROOT/.agents/story/architecture_constraints.md" 2>/dev/null && pass "architecture_constraints 记录 ocr 可选外部依赖边界" || fail "architecture_constraints 缺失 ocr 边界"

echo ""
echo "========================================"
echo "分层结果: L1 $L1_PASS 通过/$L1_FAIL 失败 | L2 $L2_PASS 通过/$L2_FAIL 失败 | L3 $L3_PASS 通过/$L3_FAIL 失败"
echo "总结果: $PASS 通过, $FAIL 失败"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
