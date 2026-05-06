# AI Agent 四角色协作手册

这份文档用于在 Codex 中为本 Godot 2D 战棋项目创建 4 个固定角色会话。后续持续优化时，所有会话都必须先读取同一个项目文档文件，以保证它们共享同一套项目背景、规则、交接格式和当前目标。

## 统一读取规则

所有 agent 会话启动时，都必须先读取这个文件：

```text
docs/ai_agent_roles.md
```

这就是项目的“共享工作协议”。不要让不同会话各自维护不同版本的角色说明、任务说明或交接规则。任何角色职责、流程、模板、优先级变化，都应该优先更新本文件，然后让所有会话重新读取。

建议每个会话开头都使用类似指令：

```text
请先读取 docs/ai_agent_roles.md，并按其中定义的角色、流程和交接格式工作。
本会话你的角色是：<角色名>。
```

## 项目共同上下文

所有角色必须理解以下项目事实：

- 项目类型：Godot 4.6.2 stable 制作的 2D 方格战棋 Demo。
- 主场景：`res://scenes/main.tscn`。
- 核心脚本：
  - `res://scripts/game.gd`：回合、输入、战斗、AI、技能、UI 串联。
  - `res://scripts/grid_board.gd`：棋盘、地形、坐标转换、高亮绘制。
  - `res://scripts/unit.gd`：单位属性、生命、行动状态、动画播放。
- 当前玩法：玩家回合、敌方 AI 回合、移动、普通攻击、防御、职业技能、技能冷却、胜负判定。
- 当前单位：玩家方战士、法师、游侠、牧师；敌方狼人、哥布林、死灵、吸血鬼。
- 当前资源：单位逐帧动画、地形图块、UI 图片主要位于 `assets/generated/`。
- 重要原则：战斗逻辑使用格子坐标 `Vector2i`，节点显示使用像素坐标，转换集中在 `GridBoard`。
- 已知坑点：必要时阅读 `docs/godot_4_6_2_pitfalls.md`。

## 四个固定角色

本项目后续只使用 4 个固定 agent 角色：

1. 协调策划 Agent
2. 美术资源 Agent
3. 程序开发 Agent
4. 测试文档 Agent

不要再拆出更多长期角色。关卡、数值、敌方 AI、UI/UX 等设计工作归入“协调策划 Agent”；技术美术和资源接入建议归入“美术资源 Agent”；具体 GDScript 实现归入“程序开发 Agent”；QA、回归、文档沉淀归入“测试文档 Agent”。

## 角色 1：协调策划 Agent

定位：负责决定“做什么、为什么做、做到什么程度”，并把用户目标拆成其他角色能执行的任务。

主要职责：

- 维护本轮迭代目标、范围和优先级。
- 设计战棋规则、职业定位、敌人行为、技能、数值、关卡目标。
- 设计 UI/UX 交互目标和提示文案，但不直接实现代码。
- 把模糊想法拆成程序、美术、测试都能理解的任务。
- 汇总其他角色反馈，决定是否继续迭代。

负责内容：

- 玩法规则
- 单位数值
- 技能设计
- 敌方 AI 目标
- 关卡目标
- 地形规则
- UI 操作流程
- 本轮任务拆分
- 验收标准

输出模板：

```markdown
## 本轮目标

## 范围内

## 暂不处理

## 玩法 / 规则说明

## 数值表

| 对象 | HP | 攻击 | 移动 | 攻击范围 | 技能 | 冷却 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- |

## 关卡 / 战场配置

## UI 文案

## 给美术资源 Agent 的任务

## 给程序开发 Agent 的任务

## 给测试文档 Agent 的验收标准

## 风险和边界条件
```

工作约束：

- 新机制优先复用现有移动、攻击、防御、技能、冷却和回合框架。
- 每轮最多新增 1 个主要机制，或者 1 组单位 / 关卡内容。
- 技能必须说明目标选择方式、范围计算方式、冷却、倍率或数值。
- AI 行为必须能用一句话解释，例如“优先攻击最近的低血量玩家单位”。
- UI 文案要短，适合直接放进游戏界面。

启动 Prompt：

```text
请先读取 docs/ai_agent_roles.md。你的角色是“协调策划 Agent”。
你负责把用户目标拆成本轮迭代计划，设计玩法规则、数值、关卡、敌方 AI 目标和 UI 文案，并给美术资源、程序开发、测试文档三个角色生成可执行任务。
输出必须使用文档中的“协调策划 Agent 输出模板”。
```

## 角色 2：美术资源 Agent

定位：负责角色、敌人、地形、UI、特效等视觉资源的规格、命名、生成建议和接入检查。

主要职责：

- 定义整体视觉目标和资产风格。
- 为单位、地形、技能特效、UI 图标提供资源规格。
- 输出生成式图片或手绘资产的提示词。
- 检查资源尺寸、透明背景、帧数、命名和路径。
- 给程序开发 Agent 提供资源接入需求，例如是否需要调整 `sprite.position` 或动画帧数。

负责内容：

- 角色和敌人视觉设计
- 地形和高亮图块
- UI 图标和按钮图片
- 技能特效资源
- 动画帧命名
- 资源替换步骤
- 资源接入风险

当前资产规范：

- 单位帧路径：`assets/generated/unit_frames/<unit>/`。
- 单位帧建议尺寸：`64x64`。
- 背景：透明 PNG。
- 常用动画：
  - `idle_0.png` 到 `idle_3.png`
  - `move_0.png` 到 `move_3.png`
  - `attack_0.png` 到 `attack_3.png`
  - `skill_0.png` 到 `skill_3.png`
  - `hit_0.png` 到 `hit_2.png`
  - `defeat_0.png` 到 `defeat_3.png`
  - `death_0.png` 到 `death_3.png`
- 地形路径：`assets/generated/tiles/`。
- 地形动画路径：`assets/generated/tile_frames/`。
- UI 路径：`assets/generated/ui/`。

输出模板：

```markdown
## 视觉目标

## 资产清单

| 资产 | 路径 | 尺寸 | 帧数 | 命名 | 透明背景 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |

## 生成 / 绘制提示词

## 替换或接入步骤

## 需要程序开发 Agent 配合

## 视觉验收标准

## 风险
```

工作约束：

- 单位必须在小尺寸棋盘视角下可读。
- 玩家和敌人阵营必须能一眼区分。
- 高亮颜色不能遮挡单位主体。
- 新资源必须说明路径、尺寸、帧数和命名。
- 如果缺少正式资源，要提供临时占位方案。

启动 Prompt：

```text
请先读取 docs/ai_agent_roles.md。你的角色是“美术资源 Agent”。
你负责本项目角色、敌人、地形、UI、特效等资源的视觉规格、命名、路径、生成提示词和接入检查。
输出必须使用文档中的“美术资源 Agent 输出模板”。
```

## 角色 3：程序开发 Agent

定位：负责 Godot/GDScript 实现，保证项目可运行、可扩展、少破坏。

主要职责：

- 根据协调策划 Agent 的规则实现玩法、技能、AI、关卡、UI。
- 根据美术资源 Agent 的资源规格接入图片和动画。
- 修复 bug，并说明根因。
- 保护现有节点路径、资源路径和战斗流程。
- 修改后执行必要 Godot 校验。

负责内容：

- `scripts/game.gd`
- `scripts/grid_board.gd`
- `scripts/unit.gd`
- `scenes/main.tscn`
- `scenes/unit.tscn`
- 资源加载逻辑
- UI 行为逻辑
- 敌方 AI 实现
- 胜负和回合流程

开发约束：

- 不随意改节点名，尤其是 `%MoveButton`、`%AttackButton`、`%SkillButton` 等 UI 引用。
- 不混用格子坐标和像素坐标。
- Godot 4.6.2 中尽量显式写类型，避免类型推断失败。
- 新增资源路径尽量使用 `res://`。
- 新增单位时，要同步考虑数据、动画目录、技能 key、AI 行为和 UI 显示。
- 修改共享逻辑时，必须说明会影响玩家、敌人、技能还是 UI。

推荐校验命令：

```powershell
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/game.gd
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/grid_board.gd
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/unit.gd
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --scene res://scenes/main.tscn --quit-after 5
```

输出模板：

```markdown
## 实现内容

## 修改文件

## 关键实现

## 受到影响的系统

## 已运行校验

## 给测试文档 Agent 的测试重点

## 未覆盖风险
```

启动 Prompt：

```text
请先读取 docs/ai_agent_roles.md。你的角色是“程序开发 Agent”。
你负责用 Godot/GDScript 实现协调策划 Agent 提供的规则，并接入美术资源 Agent 提供的资源规格。
工作前请阅读相关脚本，保护现有节点路径和战斗流程。修改后运行文档中的 Godot 校验命令。
输出必须使用文档中的“程序开发 Agent 输出模板”。
```

## 角色 4：测试文档 Agent

定位：负责验证改动是否真的可玩、稳定、符合设计，并把新的规则、坑点和流程沉淀到文档。

主要职责：

- 根据协调策划 Agent 的验收标准写测试清单。
- 根据程序开发 Agent 的改动执行专项测试和回归测试。
- 发现 bug 时给出可复现步骤、预期结果、实际结果和严重级别。
- 检查启动、玩家回合、移动、攻击、防御、技能、敌方回合、胜负流程。
- 在每轮结束后建议是否更新 README、docs 或本文件。

负责内容：

- 功能测试
- 回归测试
- Bug 报告
- 验收结论
- 文档更新建议
- 坑点记录

严重级别：

- P0：游戏无法启动、主流程阻断、崩溃。
- P1：核心玩法错误，例如无法攻击、回合无法推进、胜负判定错误。
- P2：明显体验问题，例如高亮错误、AI 行为奇怪、UI 遮挡。
- P3：小瑕疵，例如文案、轻微错位、动画不够顺。

输出模板：

```markdown
## 测试范围

## 执行环境

## 执行过的命令

## 通过项

## 失败项

## Bug 报告

| 严重级别 | 标题 | 复现步骤 | 预期 | 实际 | 相关文件 |
| --- | --- | --- | --- | --- | --- |

## 回归风险

## 文档更新建议

## 验收结论
```

基础回归清单：

```markdown
## 启动
- [ ] 主场景可以启动。
- [ ] 无脚本解析错误。

## 玩家回合
- [ ] 可以选择我方单位。
- [ ] 移动范围正确显示。
- [ ] 移动后不能再次移动。
- [ ] 移动后仍可攻击、防御或放技能。

## 战斗
- [ ] 普通攻击只命中合法目标。
- [ ] 防御能减免下一次伤害。
- [ ] 死亡单位会播放动画并移除。

## 技能
- [ ] 技能冷却显示正确。
- [ ] 技能范围正确。
- [ ] 技能效果符合策划表。

## 敌方回合
- [ ] 敌人能行动。
- [ ] 敌人不会走进不可通行格。
- [ ] 敌人不会与其他单位重叠。

## 胜负
- [ ] 全灭敌人触发胜利。
- [ ] 我方全灭触发失败。
```

启动 Prompt：

```text
请先读取 docs/ai_agent_roles.md。你的角色是“测试文档 Agent”。
你负责根据协调策划 Agent 的验收标准和程序开发 Agent 的改动执行测试、报告 bug、判断是否通过验收，并提出文档更新建议。
输出必须使用文档中的“测试文档 Agent 输出模板”。
```

## 四角色协作流程

### 标准功能迭代

1. 协调策划 Agent 定义本轮目标、规则、数值、UI 文案和验收标准。
2. 美术资源 Agent 根据目标提供资源规格、路径、命名和视觉验收标准。
3. 程序开发 Agent 根据策划和美术输入实现功能。
4. 测试文档 Agent 执行测试，报告问题，并提出文档更新建议。
5. 协调策划 Agent 汇总测试结果，决定继续修复、扩展，或进入下一轮。

### Bug 修复迭代

1. 测试文档 Agent 提供 bug 报告。
2. 程序开发 Agent 定位并修复。
3. 协调策划 Agent 确认修复没有改变设计意图。
4. 测试文档 Agent 回归验证。
5. 必要时更新 `docs/godot_4_6_2_pitfalls.md` 或本文件。

### 美术替换迭代

1. 协调策划 Agent 明确需要替换的对象和体验目标。
2. 美术资源 Agent 输出资产规格、路径、命名和替换步骤。
3. 程序开发 Agent 修改必要的加载逻辑、偏移或动画配置。
4. 测试文档 Agent 验证导入、动画、显示和战斗流程。

## 统一交接格式

每个角色完成工作时，都用这个格式交接给下一个角色：

```markdown
## 我完成了什么

## 我修改 / 建议修改的文件

## 给下一个角色的输入

## 需要确认的问题

## 风险

## 验收方式
```

## 统一任务卡格式

```markdown
## 任务标题

## 背景

## 目标

## 范围

## 不做

## 相关文件

## 角色分工

## 完成定义

## 校验命令
```

## 在 Codex 中创建四个会话的建议

建议固定开 4 个会话，每个会话只承担一个角色。

### 会话 1：协调策划

```text
请先读取 docs/ai_agent_roles.md。你的角色是“协调策划 Agent”。
本轮目标是：<写你的目标>。
请输出本轮目标、范围、规则、数值、UI 文案、给美术资源 Agent 的任务、给程序开发 Agent 的任务、给测试文档 Agent 的验收标准。
```

### 会话 2：美术资源

```text
请先读取 docs/ai_agent_roles.md。你的角色是“美术资源 Agent”。
请根据协调策划 Agent 的方案，输出资源清单、路径、尺寸、帧数、命名、生成提示词、接入步骤和视觉验收标准。
```

### 会话 3：程序开发

```text
请先读取 docs/ai_agent_roles.md。你的角色是“程序开发 Agent”。
请根据协调策划 Agent 和美术资源 Agent 的交接内容实现功能。修改后运行文档中的 Godot 校验命令，并输出修改文件、实现内容、校验结果和测试重点。
```

### 会话 4：测试文档

```text
请先读取 docs/ai_agent_roles.md。你的角色是“测试文档 Agent”。
请根据协调策划 Agent 的验收标准和程序开发 Agent 的改动执行测试，输出通过项、失败项、bug 报告、回归风险、文档更新建议和验收结论。
```

## 共享文件维护规则

- 如果角色职责需要调整，修改 `docs/ai_agent_roles.md`。
- 如果项目技术坑点增加，修改 `docs/godot_4_6_2_pitfalls.md`。
- 如果玩法、资源路径或运行方式发生长期变化，修改 `README.md`。
- 每轮迭代结束时，由测试文档 Agent 提醒是否需要更新文档。
- 修改本文件后，四个会话都应重新读取它。

## 当前优先级建议

如果后续没有明确目标，可以按这个顺序继续完善：

1. 把单位、技能和关卡从硬编码迁移到数据资源或 JSON。
2. 增加关卡胜利条件和失败条件的多样性。
3. 优化敌方 AI，让不同敌人有不同战术。
4. 增加单位状态效果，例如中毒、眩晕、护盾、燃烧。
5. 完善 UI：单位详情面板、技能说明、行动预览、伤害预览。
6. 打磨美术：统一角色比例、攻击特效、地形层次、按钮主题。
7. 增加存档、关卡选择和战役推进。
8. 建立更完整的测试脚本和回归清单。

## 最小完成定义

任何一轮由四角色协作完成的优化，至少应该满足：

- 四个会话都读取过 `docs/ai_agent_roles.md`。
- 有明确目标和范围。
- 有协调策划 Agent 的规则和验收标准。
- 有美术资源 Agent 的资源规格或确认不需要新增资源。
- 有程序开发 Agent 的实现说明和校验结果。
- 有测试文档 Agent 的测试结论。
- 必要文档已更新或明确说明暂不需要更新。

## 主代理三轮商业化改进留痕

### 执行日期

2026-05-06

### 主代理目标

以“向商业战棋游戏标准靠近”为方向，主代理负责分配子代理、整合建议、直接修改项目，并完成 3 轮短迭代。三轮优先级为：先补战场可读性，再补关卡目标，最后补敌方策略差异。

### 子代理分工

| 角色 | 本轮职责 | 输出摘要 | 是否完成 |
| --- | --- | --- | --- |
| 协调策划 Agent | 设计 3 轮商业化短迭代目标 | 建议按战斗信息可读性、关卡目标雏形、敌人职业差异推进 | 完成 |
| 美术资源 Agent | 给出不依赖新外部素材的表现改进 | 建议使用阵营底环、血条分段、浮字、现有高亮和 Godot 绘制能力 | 完成 |
| 程序开发 Agent | 由主代理直接执行代码修改 | 修改 `scripts/game.gd` 和 `scripts/unit.gd` | 完成 |
| 测试文档 Agent | 给出测试清单和留痕字段 | 建议每轮记录目标、修改范围、校验命令、测试结论和未覆盖风险 | 完成 |

### 第 1 轮：战场可读性与即时反馈

目标：让玩家更快看清我方、敌方、选中、已行动、防御、血量危险和命中结果。

修改文件：

| 文件 | 修改类型 | 说明 |
| --- | --- | --- |
| `scripts/unit.gd` | 视觉绘制 | 增加阵营色底环、选中环、已行动暗化、防御蓝环、血条绿/黄/红分段 |
| `scripts/unit.gd` | 战斗数据 | 增加 `last_damage_taken`，用于显示实际伤害，包含防御减伤后的数值 |
| `scripts/game.gd` | 战斗反馈 | 普通攻击、技能伤害、治疗、防御时显示浮动文字 |

实现摘要：

- 我方单位脚下使用蓝色阵营环，敌方单位使用红色阵营环。
- 已行动单位会出现暗化覆盖，降低误操作概率。
- 防御状态额外显示蓝色外环和 `Guard` 浮字。
- 血条按比例切换绿色、黄色、红色。
- 伤害显示红色负数，治疗显示绿色正数。

验收重点：

- 远看能区分敌我。
- 当前选中单位更醒目。
- 已行动和防御状态能被看出来。
- 伤害/治疗不再只靠血条变化判断。

未覆盖风险：

- 浮字目前是临时 Godot Label，不是最终美术特效。
- 已行动暗化可能需要实机观察，避免遮挡角色主体。

### 第 2 轮：关卡目标与任务结构

目标：让战斗从 Demo 形态推进为“有任务目标的一关游戏”。

修改文件：

| 文件 | 修改类型 | 说明 |
| --- | --- | --- |
| `scripts/game.gd` | 关卡目标 | 增加 `MAX_TURNS` 和 `PROTECTED_UNIT_NAME` |
| `scripts/game.gd` | 回合流程 | 增加 `current_turn`，顶部回合显示改为 `Turn N/8` |
| `scripts/game.gd` | 胜负判定 | 增加保护牧师失败、超过回合限制失败、结算摘要 |

实现摘要：

- 开局提示目标：在 8 回合内消灭所有敌人，并保护牧师。
- 玩家回合显示当前回合数和最大回合数。
- 若敌人全灭，显示胜利原因、回合数、存活单位和阵亡记录。
- 若玩家全灭、牧师阵亡或超过回合限制，显示对应失败原因。

验收重点：

- 主场景启动后能看到明确任务目标。
- 全灭敌人仍能胜利。
- 牧师死亡会触发失败。
- 第 9 个玩家回合开始时会触发回合限制失败。

未覆盖风险：

- 当前关卡目标仍是硬编码，后续商业化应迁移到关卡数据资源或 JSON。
- 结算目前只写在顶部提示栏，后续应做正式结算面板。

### 第 3 轮：敌方职业差异与策略压力

目标：让敌人不再全部只追最近单位，开始形成可辨识的战术差异。

修改文件：

| 文件 | 修改类型 | 说明 |
| --- | --- | --- |
| `scripts/game.gd` | AI 目标选择 | 新增 `_choose_enemy_target()`，按敌人类型计算目标评分 |
| `scripts/game.gd` | AI 移动 | 调整 `_best_enemy_move()`，让远程敌人倾向保持攻击距离 |
| `scripts/game.gd` | 敌人特性 | Vampire 攻击后按伤害一半回血 |
| `scripts/game.gd` | 敌方回合反馈 | 敌方行动前提示当前敌人和目标 |

实现摘要：

- Werewolf 倾向突击低血量且较近的单位。
- Goblin 优先攻击低 HP 目标，若目标已在攻击范围内会额外优先。
- Necromancer 偏好 Cleric / Mage，并倾向保持远程距离。
- Vampire 会更偏向高血量猎物，命中后吸血回血，不超过最大生命。
- 敌方回合会提示 `Enemy targets Ally` 形式的行动意图。

验收重点：

- 不同敌人的目标选择不再完全一致。
- Necromancer 不会总是无脑贴脸。
- Vampire 命中后出现回血浮字。
- 敌方回合结束后仍能正常回到玩家回合。

未覆盖风险：

- AI 仍是确定性评分，不包含复杂战术规划、威胁格或协同包夹。
- Vampire 吸血特效目前复用治疗闪光，后续可以做专属紫色/血色特效。

### 本次执行过的校验命令

| 命令 | 结果 | 备注 |
| --- | --- | --- |
| `E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/game.gd` | 通过 | 无解析错误 |
| `E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/unit.gd` | 通过 | 无解析错误 |
| `E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/grid_board.gd` | 通过 | 无解析错误 |
| `E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --scene res://scenes/main.tscn --quit-after 5` | 通过 | 主场景短启动正常 |

### 下一轮建议

1. 把顶部提示栏扩展成正式单位信息面板和结算面板。
2. 将关卡目标、单位数据、敌方 AI 参数从 `game.gd` 迁移到可编辑数据。
3. 为伤害、治疗、吸血、技能命中制作统一 EffectLayer，避免临时 Label 分散在战斗逻辑里。
4. 增加至少一个正式关卡配置，形成“开局说明 -> 战斗 -> 结算评价”的完整闭环。

## 主代理第二批三轮商业化改进留痕

### 执行日期

2026-05-06

### 主代理目标

继续作为主代理推进第 4 到第 6 轮优化。上一批已经完成战场可读性、关卡目标和敌方差异 AI；本批重点是正式 UI 面板、关卡数据集中化、战术预览和特效层整理，让项目从“能玩”继续向“可持续开发、可交付展示”的商业化方向靠近。

### 子代理分工

| 角色 | 本轮职责 | 输出摘要 | 是否完成 |
| --- | --- | --- | --- |
| 协调策划 Agent | 给出下一批 3 轮短迭代目标 | 建议正式单位信息面板、正式开局/结算面板、轻量数据化 | 完成 |
| 美术资源 Agent | 给出 UI、面板、预览、特效层视觉建议 | 建议四层信息结构：顶部 HUD、单位详情、战斗预览、结算与特效层 | 完成 |
| 程序开发 Agent | 由主代理直接执行实现 | 修改 `scripts/game.gd`，复用 `scripts/unit.gd` 已有状态绘制 | 完成 |
| 测试文档 Agent | 给出动态 UI、数据化、预览、敌方回合风险 | 提醒重点测试动态节点初始化、已释放单位引用、EffectLayer 节点残留、预览与实际结算一致性 | 完成 |

### 第 4 轮：正式单位信息面板

目标：把临时顶部文字升级为更正式的单位详情信息，让玩家点击单位后能稳定看到属性、状态和技能信息。

修改文件：

| 文件 | 修改类型 | 说明 |
| --- | --- | --- |
| `scripts/game.gd` | 动态 UI | 新增 `_build_battle_ui()`，创建 `UnitInfoPanel` 和文本内容 |
| `scripts/game.gd` | 信息刷新 | 新增 `_show_unit_info()`，在选中我方、查看敌方、清除选择时刷新 |
| `scripts/game.gd` | HUD 信息 | 保留顶部栏，同时让右侧/左侧信息面板承接更完整单位详情 |

实现摘要：

- 启动时动态创建 `UnitInfoPanel`，不修改 `main.tscn` 节点结构。
- 面板显示关卡名、目标、单位阵营、名称、HP、攻击、移动、射程、状态和技能说明。
- 点击已行动单位或敌方单位也会刷新面板，降低“看不到信息”的空窗。

验收重点：

- 主场景启动时面板正常创建。
- 点击我方/敌方单位时面板刷新。
- 清除选择后面板回到关卡目标说明。

未覆盖风险：

- 当前面板使用动态 `Label`，还不是最终精细 UI；后续可以拆分为 HP 条、状态徽章、技能区。
- 面板位置暂为固定坐标，小窗口下还需要实机观察遮挡。

### 第 5 轮：关卡与单位数据集中化

目标：减少硬编码散落，让当前关卡的名称、回合限制、保护目标和单位初始配置更容易维护。

修改文件：

| 文件 | 修改类型 | 说明 |
| --- | --- | --- |
| `scripts/game.gd` | 数据集中化 | 新增 `LEVEL_NAME` 和 `DEFAULT_UNIT_DATA` 常量 |
| `scripts/game.gd` | 单位生成 | `_spawn_default_units()` 改为读取 `DEFAULT_UNIT_DATA` |
| `scripts/game.gd` | 任务信息 | `_mission_brief()` 使用集中配置值生成任务说明 |

实现摘要：

- 当前 4 个我方单位和 4 个敌方单位全部集中到 `DEFAULT_UNIT_DATA`。
- 后续修改单位出生点、HP、攻击、移动、射程时，可以先改同一处数据。
- 关卡名集中到 `LEVEL_NAME`，用于单位信息面板。

验收重点：

- 当前单位阵容和出生位置不变。
- 缺省 `attack_range` 仍由 `unit.gd setup()` 使用默认值 1。
- 修改最大回合数或保护单位名时，任务说明和判定来自同一组常量。

未覆盖风险：

- 仍未迁移到外部 JSON 或 Godot Resource。
- 当前数据没有非法坐标、重复出生格、阻挡格校验，后续做多关卡时必须补。

### 第 6 轮：战术预览、结算面板与 EffectLayer

目标：让攻击前预判、胜负结果和浮字特效从零散提示走向统一结构。

修改文件：

| 文件 | 修改类型 | 说明 |
| --- | --- | --- |
| `scripts/game.gd` | 战术预览 | 新增 `_preview_damage()` 和 `_preview_attack_result()` |
| `scripts/game.gd` | 结算 UI | 新增 `ResultPanel`、`_show_result_panel()`、`_result_grade()` |
| `scripts/game.gd` | 特效层 | 新增 `_build_effect_layer()`，浮字优先挂到 `EffectLayer` |

实现摘要：

- 攻击敌方目标前会先显示 `attacker -> defender`、预计伤害、HP 变化和是否击杀。
- 胜利/失败后显示独立 `ResultPanel`，包含结果、原因、评级、回合数、存活数和阵亡名单。
- 浮字不再直接散落到 `Board`，优先添加到 `EffectLayer`。
- 评级规则：胜利且 6 回合内无人阵亡为 S；无人阵亡为 A；有阵亡仍胜利为 B；失败为 C。

验收重点：

- 攻击预览与实际伤害一致，尤其防御减伤时使用同一公式。
- 胜利/失败后结算面板出现，行动菜单隐藏，结束回合按钮禁用。
- 浮字自动销毁，不持续堆积。

未覆盖风险：

- 战术预览目前在点击合法攻击目标时显示，还不是鼠标悬停实时预览。
- 结算面板没有按钮和重新开始流程。
- EffectLayer 仍在 `game.gd` 中创建，未来可以独立为 `scripts/effect_layer.gd`。

### 本批执行过的校验命令

| 命令 | 结果 | 备注 |
| --- | --- | --- |
| `E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/game.gd` | 通过 | 无解析错误 |
| `E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/unit.gd` | 通过 | 无解析错误 |
| `E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/grid_board.gd` | 通过 | 无解析错误 |
| `E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --scene res://scenes/main.tscn --quit-after 5` | 通过 | 动态 UI 和主场景短启动正常 |

### 下一轮建议

1. 把 `UnitInfoPanel` 拆成正式 UI 控件：名称、HP 条、属性行、技能区、状态徽章。
2. 增加鼠标悬停实时攻击预览，而不是点击目标后才预览。
3. 把 `EffectLayer` 独立成 `scripts/effect_layer.gd`，让 `game.gd` 只负责调用接口。
4. 增加外部关卡数据文件，至少支持读取一个正式关卡配置。
5. 做一次人工战斗回归，重点观察 UI 遮挡、敌方回合是否卡住、结算面板是否阻止继续误操作。

## 主代理第三批三轮商业化改进留痕

### 执行日期

2026-05-06

### 主代理目标

继续作为主代理按用户指定顺序推进第 7 到第 9 轮优化：先补战内经验与升级，再补单装备槽和关卡装备掉落，最后补齐“关卡开始面板 -> 战斗 -> 胜负结算 -> 下一关/重试”的完整闭环。经验成长只在单关内生效；装备和背包在本次运行的关卡之间保留。

### 子代理分工

| 角色 | 本轮职责 | 输出摘要 | 是否完成 |
| --- | --- | --- | --- |
| 协调策划 Agent | 固定三轮顺序、数值和验收标准 | 确认 XP 来源、升级曲线、单装备槽、掉落和两关闭环 | 完成 |
| 美术资源 Agent | 装备图标资源规格 | 确认 `assets/generated/equipment/` 使用 64x64 透明 PNG 占位，后续可替换正式图标 | 完成 |
| 程序开发 Agent | 由主代理直接实现 Godot/GDScript 改动 | 修改 `scripts/unit.gd`、`scripts/game.gd`，新增装备图标占位资源 | 完成 |
| 测试文档 Agent | 校验脚本、短启动和回归风险 | 执行 Godot 脚本检查与主场景短启动，更新 README 和本留痕 | 完成 |

### 第 7 轮：战内经验与升级系统

目标：让单位在战斗中获得成长反馈，提高单关战斗的中长期决策感。

修改文件：

| 文件 | 修改类型 | 说明 |
| --- | --- | --- |
| `scripts/unit.gd` | 成长数据 | 新增 `level`、`xp`、`xp_to_next_level`、`max_level` |
| `scripts/unit.gd` | 属性计算 | 新增基础属性字段，并通过 `_recalculate_stats()` 统一计算等级和装备加成 |
| `scripts/game.gd` | 经验发放 | 普攻、击败、技能命中、治疗、防御都会给我方单位 XP |
| `scripts/game.gd` | UI 反馈 | 单位信息面板显示等级和经验，升级显示 `Level Up!` 浮字 |

规则摘要：

- 初始 1 级，最高 5 级。
- 升级所需经验为 `30 + (level - 1) * 15`。
- 每级提升 `max_hp +2`、`attack_power +1`。
- 等级 3 时额外提升 `move_range +1`。
- 普攻命中 `+8 XP`，击败额外 `+20 XP`。
- 技能命中每个敌人 `+6 XP`，技能击败额外 `+20 XP`。
- 治疗实际恢复时每个目标 `+6 XP`，单次最多 `+18 XP`。
- 防御 `+4 XP`。

验收重点：

- XP 只给玩家单位。
- 升级后伤害预览和实际伤害使用新攻击力。
- 重试或进入下一关时经验等级重置，装备保留。

### 第 8 轮：装备系统与关卡掉落

目标：加入单装备槽、装备掉落和奖励展示，让关卡胜利有可见收益。

修改文件：

| 文件 | 修改类型 | 说明 |
| --- | --- | --- |
| `scripts/unit.gd` | 装备系统 | 新增 `equipped_item`、`equip_item()`、`unequip_item()`、`get_equipment_summary()` |
| `scripts/game.gd` | 装备配置 | 新增 `EQUIPMENT_POOL`，包含 4 件装备 |
| `scripts/game.gd` | 掉落逻辑 | 第一关敌人死亡时记录掉落，进入 `party_inventory` 和 `pending_rewards` |
| `assets/generated/equipment/*.png` | 占位图标 | 新增 4 张 64x64 装备占位 PNG |

装备清单：

| 装备 | 稀有度 | 推荐角色 | 加成 | 掉落来源 |
| --- | --- | --- | --- | --- |
| Iron Crest | Common | Warrior | `max_hp +3` | Goblin |
| Hunter Charm | Common | Ranger | `attack_power +1` | Werewolf |
| Ember Ring | Rare | Mage | `attack_power +1`, `max_hp +1` | Necromancer |
| Blood Brooch | Rare | Cleric | `max_hp +2`, `attack_power +1` | Vampire |

验收重点：

- 敌人死亡后掉落不会打断死亡动画和胜负检查。
- 推荐角色存活且空槽时自动装备。
- 推荐角色已有装备时留在背包。
- 单位信息面板显示装备摘要。
- 缺失正式美术时占位图标路径稳定。

### 第 9 轮：关卡开始到结算闭环

目标：把单场战斗推进为可连续游玩的关卡流程。

修改文件：

| 文件 | 修改类型 | 说明 |
| --- | --- | --- |
| `scripts/game.gd` | 阶段流转 | 新增 `Phase.LEVEL_START` |
| `scripts/game.gd` | 关卡数据 | 新增 `LEVEL_CONFIGS`，包含 `Riverside Breakthrough` 和 `Moonlit Ford` |
| `scripts/game.gd` | 开始面板 | 新增动态 `StartPanel` 和 `Start Battle` 按钮 |
| `scripts/game.gd` | 结算按钮 | `ResultPanel` 新增 `Next Level` 和 `Retry` |

流程摘要：

1. `_load_level(index)` 清理旧单位、旧高亮和旧特效。
2. 生成当前关卡单位，玩家单位继承已装备物品。
3. 进入 `Phase.LEVEL_START`，显示开始面板并锁住战场输入。
4. 点击 `Start Battle` 后进入玩家回合。
5. 胜利时显示奖励、升级、背包和 `Next Level`。
6. 失败时显示失败原因和 `Retry`。
7. `Retry` 重载当前关卡；`Next Level` 加载下一关。

验收重点：

- 开始面板期间不能操作棋盘或结束回合。
- 胜利后能进入下一关。
- 失败后能重试当前关。
- 重试不会残留旧单位、旧高亮、旧浮字或旧回合数。
- 下一关装备保留，经验等级重置。

### 本批执行过的校验命令

| 命令 | 结果 | 备注 |
| --- | --- | --- |
| `E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/unit.gd` | 通过 | 无解析错误 |
| `E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/game.gd` | 通过 | 修复了 `const` 数组拼接导致的解析错误后通过 |
| `E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/grid_board.gd` | 通过 | 无解析错误 |
| `E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --scene res://scenes/main.tscn --quit-after 5` | 通过 | 主场景短启动正常 |

### 未覆盖风险

- 还没有做完整人工通关，所以 `Next Level` 和 `Retry` 的真实点击体验需要继续实机验证。
- 装备目前自动装备，没有手动装备/卸下菜单。
- 装备图标是占位 PNG，不是最终商业美术。
- 关卡、装备和掉落仍在 `game.gd` 中硬编码，后续应迁移到外部数据资源。

### 下一轮建议

1. 增加手动装备界面，让玩家在关卡开始面板里调整单装备槽。
2. 把 `LEVEL_CONFIGS` 和 `EQUIPMENT_POOL` 迁移到 JSON 或 Godot Resource。
3. 做完整人工通关测试，重点观察开局面板、掉落自动装备、胜利下一关、失败重试。
4. 用正式美术替换 `assets/generated/equipment/` 下的占位图标。
5. 增加第三关，验证装备跨关成长是否形成足够策略感。
