#!/usr/bin/env bash
# upaseo skill suite - 一致性验证脚本
# 用法: bash scripts/validate.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "  ✅ $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

SKILLS=(upaseo upaseo-advisor upaseo-brainstorm upaseo-committee upaseo-compact upaseo-e2e upaseo-goal upaseo-handoff upaseo-loop upaseo-reviewer upaseo-simplify upaseo-ship upaseo-init upaseo-todo)
ALL_SKILLS=("${SKILLS[@]}" using-upaseo)

echo "=== 1. YAML name 字段校验 ==="
for s in "${ALL_SKILLS[@]}"; do
  expected="$s"
  actual=$(grep "^name:" "$ROOT/$s/SKILL.md" 2>/dev/null | head -1 | sed 's/name: //')
  if [ "$actual" = "$expected" ]; then pass "$s"; else fail "$s: expected '$expected', got '$actual'"; fi
done

echo ""
echo "=== 1.1 skill-creator 元数据与长度规范 ==="
for s in "${ALL_SKILLS[@]}"; do
  fm=$(awk 'BEGIN{c=0} /^---$/ {c++; next} c==1 {print}' "$ROOT/$s/SKILL.md" 2>/dev/null)
  extra=$(printf "%s\n" "$fm" | awk -F: '/^[A-Za-z0-9_-]+:/ { if ($1 != "name" && $1 != "description") print $1 }')
  if [ -z "$extra" ]; then pass "$s frontmatter 仅包含 name/description"; else fail "$s frontmatter 含非 skill-creator 字段: $extra"; fi
  body_lines=$(awk 'BEGIN{c=0;n=0} /^---$/ {c++; next} c>=2 {n++} END{print n}' "$ROOT/$s/SKILL.md" 2>/dev/null)
  if [ "$body_lines" -le 500 ]; then pass "$s body <= 500 lines"; else fail "$s body 超过 500 lines: $body_lines"; fi
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
found=$(grep -rn "brainstorming\|code-simplify\|code-reviewer" "$ROOT"/*/SKILL.md "$ROOT"/using-upaseo/references/roles.md 2>/dev/null || true)
if [ -z "$found" ]; then pass "无遗留外部技能引用残留"; else fail "发现遗留外部引用: $found"; fi
if grep -q "karpathy-guidelines" "$ROOT/upaseo-goal/SKILL.md" 2>/dev/null; then pass "upaseo-goal 允许显式应用 karpathy-guidelines"; else pass "未使用 karpathy-guidelines"; fi

echo ""
echo "=== 5. 计划文件路径一致性 ==="
bad_paths=$(grep -n '~/\.paseo/plans\|~/.paseo/plans' "$ROOT/using-upaseo/SKILL.md" 2>/dev/null || true)
if [ -z "$bad_paths" ]; then pass "路径统一为 .paseo/plans/ (项目根目录)"; else fail "发现 ~/.paseo/plans 引用: $bad_paths"; fi

echo ""
echo "=== 5.2 goal 与 plan 目录契约 ==="
grep -q "\.paseo/goals/" "$ROOT/upaseo-goal/SKILL.md" && pass "upaseo-goal 写入 .paseo/goals/" || fail "upaseo-goal 未声明 .paseo/goals/"
grep -q "不调用 \`/goal\`\|不启动执行" "$ROOT/upaseo-goal/SKILL.md" && pass "upaseo-goal 只落盘不执行" || fail "upaseo-goal 仍可能启动执行"
grep -q "upaseo-goal.*可选流程\|可选 goal" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 将 upaseo-goal 视为可选流程" || fail "using-upaseo 未声明 goal 流程可选"
grep -q "\.paseo/goals/" "$ROOT/using-upaseo/SKILL.md" && grep -q "\.paseo/plans/" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 区分 goal 与 plan 目录" || fail "using-upaseo 缺失 goal/plan 目录分离"
grep -q "\.paseo/goals/" "$ROOT/README.md" && grep -q "\.paseo/goals/" "$ROOT/AGENTS.md" && pass "README 与 AGENTS.md 记录 goals 目录契约" || fail "README 或 AGENTS.md 缺失 goals 目录契约"
if [ -d "$ROOT/.paseo/goals" ]; then pass ".paseo/goals 目录存在"; else fail ".paseo/goals 目录不存在"; fi
grep -q "upaseo-brainstorm" "$ROOT/upaseo-goal/SKILL.md" && grep -q "karpathy-guidelines" "$ROOT/upaseo-goal/SKILL.md" && grep -q "upaseo-simplify" "$ROOT/upaseo-goal/SKILL.md" && pass "upaseo-goal 集成 brainstorm/simplify/karpathy 原则" || fail "upaseo-goal 缺失目标收敛原则集成"
grep -q "^边界：" "$ROOT/upaseo-goal/SKILL.md" && grep -q "logs|tests|browser|manual|agent-run" "$ROOT/upaseo-goal/SKILL.md" && pass "upaseo-goal 模板包含边界与验证方法" || fail "upaseo-goal 模板缺失边界或验证方法"

echo ""
echo "=== 5.1 upaseo 与 using-upaseo 职责边界 ==="
grep -q "Foundation Reference" "$ROOT/upaseo/SKILL.md" && pass "upaseo 明确为底层基座参考" || fail "upaseo 未明确基座参考定位"
grep -q "not a user-facing development workflow\|not the product development workflow entrypoint" "$ROOT/upaseo/SKILL.md" && pass "upaseo 明确不是完整开发入口" || fail "upaseo 未声明非完整开发入口"
grep -q "唯一的完整开发工作流入口" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 明确为唯一完整开发入口" || fail "using-upaseo 未声明唯一完整开发入口"
grep -q "不得静默创建软链接" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 遵守 CLI 软链接需用户确认" || fail "using-upaseo 仍可能静默创建 CLI 软链接"
grep -q "会话隔离硬规则" "$ROOT/using-upaseo/SKILL.md" && grep -q "/upaseo-handoff --worktree" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo --worktree 强制 handoff 到新 worktree 会话" || fail "using-upaseo --worktree 缺失 handoff 会话隔离规则"
grep -q "Worktree 会话隔离" "$ROOT/README.md" && pass "README 记录 worktree 会话隔离机制" || fail "README 缺失 worktree 会话隔离机制"
grep -q "/upaseo-handoff --worktree" "$ROOT/using-upaseo/references/params.md" && grep -q "/upaseo-handoff --worktree" "$ROOT/using-upaseo/references/quick-mode.md" && pass "参数与快速模式文档记录 worktree handoff 规则" || fail "参数或快速模式文档缺失 worktree handoff 规则"

echo ""
echo "=== 6. roles.md 关键规程检查 ==="
roles="$ROOT/upaseo/references/roles.md"
grep -q "内联摘要\|按需读取" "$roles" && pass "精简传递策略" || fail "精简传递策略缺失"
grep -q "合规检查" "$roles" && pass "合规检查规程" || fail "合规检查规程缺失"
grep -q "完工通知\|Completion" "$roles" && pass "完工通知规程" || fail "完工通知规程缺失"
grep -q "story-updater" "$roles" && pass "story-updater 角色规程" || fail "story-updater 角色规程缺失"
grep -q "architecture-designer" "$roles" && pass "architecture-designer 计划评审角色" || fail "architecture-designer 计划评审角色缺失"
grep -q "feature-designer" "$roles" && pass "feature-designer 计划评审角色" || fail "feature-designer 计划评审角色缺失"
grep -q "test-strategist" "$roles" && pass "test-strategist 验收评审角色" || fail "test-strategist 验收评审角色缺失"
# 引用文件指向总表
grep -q "upaseo/references/roles.md" "$ROOT/using-upaseo/references/roles.md" && pass "using-upaseo roles.md 引用总表" || fail "using-upaseo roles.md 未引用总表"
grep -q "upaseo/references/roles.md" "$ROOT/upaseo-init/references/roles.md" && pass "upaseo-init roles.md 引用总表" || fail "upaseo-init roles.md 未引用总表"
grep -q "upaseo/references/roles.md" "$ROOT/upaseo-ship/references/roles.md" && pass "upaseo-ship roles.md 引用总表" || fail "upaseo-ship roles.md 未引用总表"

echo ""
echo "=== 7. 开发故事与历史资产目录机制校验 ==="
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
echo "--- 7.1 运行时 story 资产文件存在性 ---"
for t in stories data_models apis modules architecture_constraints coding_standards; do
  if [ -f "$ROOT/.agents/story/${t}.md" ]; then pass ".agents/story/${t}.md 存在"; else fail "缺失 .agents/story/${t}.md"; fi
done
old_story_refs=$(grep -rn "\.paseo/story" "$ROOT" --exclude-dir=.git --exclude="validate.sh" 2>/dev/null || true)
if [ -z "$old_story_refs" ]; then pass "无 .paseo/story 旧路径引用"; else fail "发现 .paseo/story 旧路径引用: $old_story_refs"; fi

echo ""
echo "=== 7.2 quick/full 与 checkpoint 规程一致性 ==="
grep -q "最小主计划" "$ROOT/using-upaseo/SKILL.md" && grep -q "最小主计划" "$ROOT/using-upaseo/references/quick-mode.md" && pass "quick 模式创建最小主计划" || fail "quick 模式未明确创建最小主计划"
grep -q "微改快速通道" "$ROOT/using-upaseo/SKILL.md" && grep -q "Micro-Change Decision" "$ROOT/using-upaseo/references/quick-mode.md" && grep -q "跳过 TDD/loop" "$ROOT/README.md" && pass "微改快速通道允许确定性小改跳过 TDD/loop" || fail "微改快速通道规程缺失"
grep -q "轻量 upaseo-loop\|轻量 Loop" "$ROOT/using-upaseo/references/quick-mode.md" && grep -q "有行为风险" "$ROOT/using-upaseo/references/quick-mode.md" && pass "quick 模式对行为风险小改仍使用轻量 loop" || fail "quick 模式缺失行为风险 loop 边界"
grep -q "checkpoint commit" "$ROOT/using-upaseo/SKILL.md" && pass "using-upaseo 包含迭代 checkpoint commit" || fail "using-upaseo 缺失 checkpoint commit 规程"
grep -q "iter_<N>_design.md" "$ROOT/using-upaseo/SKILL.md" && pass "恢复流程兼容旧版 iter_N_design.md" || fail "恢复流程缺失旧计划文件兼容"

echo ""
echo "=== 7.3 文件即上下文与高稳健性架构校验 ==="
grep -q "文件即上下文" "$ROOT/using-upaseo/SKILL.md" && pass "SKILL.md 包含文件即上下文规约" || fail "SKILL.md 缺失文件即上下文规约"
grep -q "State: Designing\|State: Implementing\|State: Verifying" "$ROOT/using-upaseo/SKILL.md" && pass "SKILL.md 断电现场现场恢复自愈状态机完整" || fail "SKILL.md 缺失断电现场恢复状态机"
grep -q "自适应评审会分级" "$ROOT/using-upaseo/SKILL.md" && pass "SKILL.md 包含自适应评审会分级（轻重自适应）" || fail "SKILL.md 缺失评审会自适应分级规程"
grep -q "PR Fallback" "$ROOT/using-upaseo/SKILL.md" && pass "SKILL.md 包含 PR Fallback 智能兜底机制" || fail "SKILL.md 缺失 PR 智能兜底机制"
grep -q "资产防事实漂移" "$ROOT/using-upaseo/SKILL.md" && pass "SKILL.md 包含资产防事实漂移校验（Diff-Asset）" || fail "SKILL.md 缺失防资产漂移校验"
grep -q "文件即上下文" "$ROOT/upaseo/references/roles.md" && pass "roles.md 总表的 Orchestrator 职责包含文件即上下文" || fail "roles.md 总表缺失编排器文件即上下文要求"
grep -q "文件即上下文" "$ROOT/requirement.md" && pass "requirement.md 涵盖文件即上下文极简开发理念" || fail "requirement.md 缺失文件即上下文规范"

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
grep -q "\.paseo/todos.md" "$ship_skill" 2>/dev/null && grep -q "只关闭有证据" "$ship_skill" 2>/dev/null && pass "SKILL.md 包含项目 todo 发布关闭规程" || fail "SKILL.md 缺失项目 todo 发布关闭规程"
grep -q "写入方闭环\|先读 global" "$ship_skill" 2>/dev/null && pass "ship global-learnings 写入方声明读取闭环" || fail "ship global-learnings 仍为只写死功能"

echo ""
echo "=== 8.1 learnings 系统规程校验 ==="
learnings_ref="$ROOT/upaseo/references/learnings-precheck.md"
grep -q "category 作用域过滤\|category 作用域" "$learnings_ref" 2>/dev/null && pass "learnings-precheck 定义 category 作用域过滤" || fail "learnings-precheck 缺失 category 作用域过滤"
grep -q "先读全局\|先读 global\|global-learnings.jsonl" "$learnings_ref" 2>/dev/null && pass "learnings-precheck 定义 global+项目读取顺序" || fail "learnings-precheck 缺失 global 读取顺序"
grep -q "老化\|aged" "$learnings_ref" 2>/dev/null && pass "learnings-precheck 定义老化降级规则" || fail "learnings-precheck 缺失老化降级规则"
grep -q "last_confirmed" "$learnings_ref" 2>/dev/null && pass "learnings-precheck 定义 last_confirmed 字段" || fail "learnings-precheck 缺失 last_confirmed 字段"
# 各技能引用共享规程而非内联五步
ref_count=$(grep -rl "执行标准避障前置读取" "$ROOT"/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
[ "$ref_count" -ge 10 ] && pass "至少 $ref_count 个技能引用 learnings-precheck 共享规程" || fail "引用 learnings-precheck 的技能数不足($ref_count)"

echo ""
echo "=== 9. upaseo-compact 核心压缩规程校验 ==="
compact_skill="$ROOT/upaseo-compact/SKILL.md"
grep -q "\.paseo/compacts" "$compact_skill" 2>/dev/null && pass "upaseo-compact 写入 .paseo/compacts 恢复文档" || fail "upaseo-compact 缺失 compact 文档路径"
grep -q "Restore Prompt" "$compact_skill" 2>/dev/null && grep -q "恢复提示词" "$compact_skill" 2>/dev/null && pass "upaseo-compact 生成恢复提示词" || fail "upaseo-compact 缺失恢复提示词规程"
grep -q "Source of Truth" "$compact_skill" 2>/dev/null && pass "upaseo-compact 明确 compact 文档为事实源" || fail "upaseo-compact 未声明事实源"
grep -q "不要依赖系统 compact" "$compact_skill" 2>/dev/null && pass "upaseo-compact 替代系统 compact 摘要" || fail "upaseo-compact 未明确替代系统 compact"
grep -q "git status" "$compact_skill" 2>/dev/null && grep -q "Validation Evidence" "$compact_skill" 2>/dev/null && pass "upaseo-compact 记录工作区状态与验证证据" || fail "upaseo-compact 缺失状态或验证证据"
grep -q "Codex hooks 自愈\|先自动补齐再继续 compact" "$compact_skill" 2>/dev/null && grep -q "宿主探测\|非 Codex 宿主" "$compact_skill" 2>/dev/null && pass "upaseo-compact 会先做宿主探测并自愈 hooks 安装" || fail "upaseo-compact 缺失 hooks 自愈安装规程"
grep -q "PreCompact" "$ROOT/.codex/hooks.json" 2>/dev/null && grep -q "PostCompact" "$ROOT/.codex/hooks.json" 2>/dev/null && pass "项目级 Codex hooks 已接入 compact 自动化" || fail "缺失项目级 compact hooks 配置"
[ -f "$ROOT/.codex/hooks/pre-compact.mjs" ] && [ -f "$ROOT/.codex/hooks/post-compact.mjs" ] && pass "compact hook 脚本存在" || fail "compact hook 脚本缺失"
grep -q "fail-open" "$compact_skill" 2>/dev/null && pass "upaseo-compact 声明 hook 失败时 fail-open" || fail "upaseo-compact 未声明 hook fail-open"

echo ""
echo "=== 10. upaseo-init 核心初始化与逆向规程校验 ==="
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
echo "=== 11. upaseo-todo 核心待办规程校验 ==="
todo_skill="$ROOT/upaseo-todo/SKILL.md"
grep -q "\.paseo/todos.md" "$todo_skill" 2>/dev/null && pass "upaseo-todo 写入 .paseo/todos.md" || fail "upaseo-todo 缺失 todos 文件路径"
grep -q "Source of Truth" "$todo_skill" 2>/dev/null && pass "upaseo-todo 声明 todos 文件为事实源" || fail "upaseo-todo 未声明 Source of Truth"
grep -q "用户明确提到.*todo" "$todo_skill" 2>/dev/null && grep -q "待办" "$todo_skill" 2>/dev/null && pass "upaseo-todo 明确 todo/待办触发记录" || fail "upaseo-todo 缺失触发记录规则"
grep -q "## Active" "$ROOT/.paseo/todos.md" 2>/dev/null && grep -q "## Done" "$ROOT/.paseo/todos.md" 2>/dev/null && pass ".paseo/todos.md 模板存在" || fail ".paseo/todos.md 缺失基础模板"
grep -q "Ship Integration" "$todo_skill" 2>/dev/null && grep -q "只关闭有证据" "$todo_skill" 2>/dev/null && pass "upaseo-todo 包含 ship 完成状态更新规则" || fail "upaseo-todo 缺失 ship 状态更新规则"
grep -q "upaseo-todo" "$ROOT/README.md" 2>/dev/null && grep -q "\.paseo/todos.md" "$ROOT/README.md" 2>/dev/null && pass "README 注册 upaseo-todo 与 todos 文件" || fail "README 缺失 upaseo-todo 注册"
grep -q "\.paseo/todos.md" "$ROOT/AGENTS.md" 2>/dev/null && pass "AGENTS.md 记录 todo 工作流约定" || fail "AGENTS.md 缺失 todo 工作流约定"

echo ""
echo "=== 12. upaseo-e2e 集成测试规程校验 ==="
e2e_skill="$ROOT/upaseo-e2e/SKILL.md"
grep -q "冻结测试环境" "$e2e_skill" 2>/dev/null && grep -q "先写测试用例" "$e2e_skill" 2>/dev/null && pass "upaseo-e2e 先冻结环境再写 case" || fail "upaseo-e2e 缺失环境冻结或 case-first 规则"
grep -q "人工确认" "$e2e_skill" 2>/dev/null && grep -q "用户明确回复" "$e2e_skill" 2>/dev/null && pass "upaseo-e2e 在执行前要求人工确认" || fail "upaseo-e2e 缺失人工确认门槛"
grep -q "默认全部使用中文输出" "$e2e_skill" 2>/dev/null && grep -q "命令、路径、环境变量名" "$e2e_skill" 2>/dev/null && pass "upaseo-e2e 明确中文输出约束" || fail "upaseo-e2e 缺失中文输出约束"
grep -q "CLI 验证必须树形全部覆盖" "$e2e_skill" 2>/dev/null && grep -q "CLI 覆盖摘要" "$e2e_skill" 2>/dev/null && pass "upaseo-e2e 包含 CLI 树形全部覆盖要求" || fail "upaseo-e2e 缺失 CLI 树形覆盖规程"
grep -q "| Case ID | 测试面 | 前置条件 | 操作 | 验证方式 | 证据 | 状态 |" "$e2e_skill" 2>/dev/null && grep -q "## 环境冻结" "$e2e_skill" 2>/dev/null && pass "upaseo-e2e 推荐模板默认中文输出" || fail "upaseo-e2e 推荐模板未默认使用中文"
grep -q "失败先复现" "$e2e_skill" 2>/dev/null && grep -q "gh issue create" "$e2e_skill" 2>/dev/null && grep -q "\.github/issues/" "$e2e_skill" 2>/dev/null && pass "upaseo-e2e 包含复现优先与 issue 双通道上报" || fail "upaseo-e2e 缺失复现或 issue 上报规程"
[ -x "$ROOT/upaseo-e2e/scripts/report_issue.sh" ] && pass "upaseo-e2e issue 上报脚本存在且可执行" || fail "upaseo-e2e issue 上报脚本缺失或不可执行"
grep -q "状态：本地降级记录" "$ROOT/upaseo-e2e/scripts/report_issue.sh" 2>/dev/null && grep -q "GH 降级原因" "$ROOT/upaseo-e2e/scripts/report_issue.sh" 2>/dev/null && pass "upaseo-e2e 本地 issue 降级头部默认中文输出" || fail "upaseo-e2e 本地 issue 降级头部未默认中文输出"
[ -d "$ROOT/.github/issues" ] && pass ".github/issues 降级 issue 目录存在" || fail ".github/issues 降级 issue 目录不存在"
grep -q "upaseo-e2e" "$ROOT/README.md" 2>/dev/null && grep -q "\.github/issues" "$ROOT/README.md" 2>/dev/null && pass "README 注册 upaseo-e2e 与 issue 降级目录" || fail "README 缺失 upaseo-e2e 注册"
grep -q "upaseo-e2e" "$ROOT/AGENTS.md" 2>/dev/null && pass "AGENTS.md 记录 upaseo-e2e 工作流" || fail "AGENTS.md 缺失 upaseo-e2e 工作流约定"
grep -q "upaseo-e2e" "$ROOT/.agents/story/modules.md" 2>/dev/null && pass "模块资产记录 upaseo-e2e 模块职责" || fail "模块资产缺失 upaseo-e2e"
grep -q "\.github/issues/" "$ROOT/.agents/story/architecture_constraints.md" 2>/dev/null && pass "架构资产记录 issue 本地降级边界" || fail "架构资产缺失 issue 降级边界"
grep -q "人工确认" "$ROOT/.agents/story/coding_standards.md" 2>/dev/null && grep -q "树形全部覆盖" "$ROOT/.agents/story/coding_standards.md" 2>/dev/null && grep -q "gh issue create" "$ROOT/.agents/story/coding_standards.md" 2>/dev/null && pass "编码规范记录 e2e 确认、覆盖与上报规程" || fail "编码规范缺失 e2e 规程"

echo ""
echo "========================================"
echo "结果: $PASS 通过, $FAIL 失败"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
