# Godot 2D 战棋 Demo

这是一个使用 Godot 4.6.2 stable 制作的 2D 方格战棋项目。当前目标已经从“能玩、能扩展、方便替换美术”的原型，推进到更接近商业战棋游戏的可展示版本：有清晰的回合目标、单位信息面板、阵营识别、战斗反馈、敌方差异 AI、结算面板和持续迭代文档。

主场景：

```text
res://scenes/main.tscn
```

## 当前包含内容

- 2D 方格棋盘、障碍格、草地、山丘、河流和岩石地形。
- 我方 4 个职业：战士、法师、游侠、牧师。
- 敌方 4 个单位：狼人、哥布林、死灵、吸血鬼。
- 玩家回合、敌方 AI 回合、移动、普通攻击、防御、职业技能。
- 技能冷却、技能范围高亮、敌方移动范围预览。
- 关卡目标：8 回合内全灭敌人，并保护牧师。
- 失败条件：我方全灭、牧师阵亡、超过回合限制。
- 胜负结算面板：结果、原因、评级、回合数、存活数、阵亡名单。
- 单位信息面板：阵营、名称、HP、攻击、移动、射程、状态、技能说明。
- 战斗反馈：伤害浮字、治疗浮字、防御提示、技能范围脉冲。
- 单位状态视觉：敌我阵营环、选中环、防御环、已行动暗化、血条颜色分段。
- 敌方差异 AI：狼人、哥布林、死灵、吸血鬼有不同目标选择倾向。
- 吸血鬼攻击命中后会按伤害比例回血。
- 单位逐帧动画：待机、移动、攻击、技能、受击、击败、死亡。
- 草地和河流帧动画。

## 如何运行项目

1. 打开 Godot 4.6.2 stable。
2. 导入项目目录：`E:\myindiegames\gamedemo1`。
3. 确认主场景是 `res://scenes/main.tscn`。
4. 点击 Godot 编辑器右上角运行按钮。

也可以用 console 版 Godot 做脚本检查和短启动：

```powershell
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/game.gd
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/grid_board.gd
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/unit.gd
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --scene res://scenes/main.tscn --quit-after 5
```

排查脚本或启动问题时，推荐使用 `Godot_v4.6.2-stable_win64_console.exe`。不要用 `--headless` 验证本项目，当前环境下它可能崩溃，详见 `docs/godot_4_6_2_pitfalls.md`。

## 项目结构

```text
scenes/main.tscn                 主战斗场景
scenes/unit.tscn                 单位场景
scripts/game.gd                  回合、输入、战斗、AI、技能、UI、关卡目标
scripts/grid_board.gd            棋盘、地形、坐标转换、高亮绘制
scripts/unit.gd                  单位属性、血量、状态、动画、单位绘制
assets/generated/unit_frames/    单位逐帧动画
assets/generated/tile_frames/    草地和河流逐帧动画
assets/generated/tiles/          地形和高亮图块
assets/generated/ui/             UI 图片
assets/source/                   原始精灵图源文件
docs/ai_agent_roles.md           四角色 AI 协作手册和主代理迭代留痕
docs/godot_4_6_2_pitfalls.md     Godot 4.6.2 踩坑记录
```

## 当前战斗规则

玩家目标：

- 在 `MAX_TURNS` 回合内击败全部敌人。
- 保护 `PROTECTED_UNIT_NAME`，当前为 `Cleric`。

胜利：

- 敌方单位全部被击败。

失败：

- 我方单位全部被击败。
- 牧师被击败。
- 超过 8 回合限制。

当前关卡名和单位初始数据集中在 `scripts/game.gd` 顶部：

```gdscript
const LEVEL_NAME := "Riverside Breakthrough"
const MAX_TURNS := 8
const PROTECTED_UNIT_NAME := "Cleric"
const DEFAULT_UNIT_DATA := [...]
```

这还不是最终数据化方案，但已经比散落硬编码更容易维护。后续建议迁移到 Godot Resource 或 JSON。

## 当前职业技能

- 战士 / 旋风斩：冷却 2 回合，以自身为中心 3x3 区域内敌人受到 1.2 倍普通攻击伤害。
- 法师 / 火球术：冷却 3 回合，前方 3x3 区域内敌人受到 1.5 倍普通攻击伤害。
- 游侠 / 直射箭雨：冷却 3 回合，前方直线 6 格内敌人受到 1.2 倍普通攻击伤害。
- 牧师 / 群体治疗：冷却 3 回合，以自身为中心 3x3 区域内友方恢复最大生命的 1/3。

## 敌方 AI 差异

敌方不再全部只追最近目标，目前有轻量差异：

- Werewolf：倾向突击低血量且较近的目标。
- Goblin：优先攻击低 HP 目标，若目标在攻击范围内会更优先。
- Necromancer：偏好 Cleric / Mage，并倾向保持远程距离。
- Vampire：倾向攻击高血量目标，命中后按伤害一半回血。

AI 仍是确定性评分逻辑，不包含复杂协同、威胁格规划或包夹策略。

## UI 与反馈系统

当前 UI 包含：

- `UI/TopBar`：顶部状态栏。
- `TurnLabel`：当前回合和阶段，例如 `Turn 3/8 - Player`。
- `InfoLabel`：战斗提示、行动意图、预览文本。
- `ActionMenu`：移动、攻击、防御、技能、取消。
- 动态创建的 `UnitInfoPanel`：单位和关卡信息。
- 动态创建的 `ResultPanel`：胜负结算。
- 动态创建的 `EffectLayer`：浮字等战斗反馈节点。

注意：

- 不要随意改 `%MoveButton`、`%AttackButton`、`%DefendButton`、`%SkillButton`、`%CancelButton`、`%EndTurnButton` 等 unique name 引用。
- 当前 `UnitInfoPanel`、`ResultPanel`、`EffectLayer` 是 `scripts/game.gd` 在运行时创建的，不在 `main.tscn` 中手工摆放。

## 如何替换单位美术

单位场景：

```text
res://scenes/unit.tscn
```

单位显示节点是 `AnimatedSprite2D`。所有单位动画帧从这里读取：

```text
assets/generated/unit_frames/<unit>/
```

例如战士目录：

```text
assets/generated/unit_frames/warrior/
```

当前每个单位支持这些动画文件：

- `idle_0.png` 到 `idle_3.png`：待机
- `move_0.png` 到 `move_3.png`：移动
- `attack_0.png` 到 `attack_3.png`：普通攻击
- `skill_0.png` 到 `skill_3.png`：职业技能
- `hit_0.png` 到 `hit_2.png`：受击
- `defeat_0.png` 到 `defeat_3.png`：击败倒下
- `death_0.png` 到 `death_3.png`：死亡移除

可替换目录：

- `assets/generated/unit_frames/warrior/`
- `assets/generated/unit_frames/mage/`
- `assets/generated/unit_frames/ranger/`
- `assets/generated/unit_frames/cleric/`
- `assets/generated/unit_frames/werewolf/`
- `assets/generated/unit_frames/goblin/`
- `assets/generated/unit_frames/necromancer/`
- `assets/generated/unit_frames/vampire/`

替换方式：

1. 准备透明背景 PNG，建议单帧尺寸保持 `64x64`。
2. 用同名文件覆盖对应目录里的帧图，例如 `warrior/attack_0.png`。
3. 文件名和序号保持一致，Godot 会自动重新导入。
4. 如果想增加或减少帧数，需要同步修改 `scripts/unit.gd` 的 `_build_sprite_frames()`。

## 如何替换棋盘和地形

棋盘脚本：

```text
res://scripts/grid_board.gd
```

地形图块：

```text
assets/generated/tiles/
```

可替换内容：

- `grass.png`：草地
- `hill.png`：山丘
- `river.png`：河流
- `rocks.png`：岩石障碍
- `highlight_move.png`：移动范围高亮
- `highlight_attack.png`：攻击范围高亮
- `highlight_hover.png`：鼠标悬停高亮

草地和河流还有逐帧动画：

- `assets/generated/tile_frames/grass_0.png` 到 `grass_5.png`
- `assets/generated/tile_frames/river_0.png` 到 `river_5.png`

障碍、山丘、河流格配置在 `scripts/grid_board.gd` 顶部：

```gdscript
@export var blocked_cells: Array[Vector2i] = [...]
@export var hill_cells: Array[Vector2i] = [...]
@export var river_cells: Array[Vector2i] = [...]
```

当前规则：

- `blocked_cells`：不可通行。
- `river_cells`：不可通行。
- `hill_cells`：目前只是视觉地形，可以通行。

## 代码入口建议

建议按这个顺序读代码：

1. `scripts/unit.gd`：单位属性、生命、行动状态、动画播放、脚下环和血条绘制。
2. `scripts/grid_board.gd`：棋盘尺寸、地形、坐标转换、高亮绘制。
3. `scripts/game.gd`：单位生成、回合流程、输入、战斗、AI、技能、UI、胜负结算。

如果你是 Godot 新手，不建议直接从 `game.gd` 开始硬啃。先理解单位和棋盘，再看 Game 如何把它们串起来，会轻松很多。

## AI Agent 协作与主代理留痕

后续如果继续用 Codex 多会话协作，请先阅读：

```text
docs/ai_agent_roles.md
```

这个文件定义了 4 个固定角色：

- 协调策划 Agent
- 美术资源 Agent
- 程序开发 Agent
- 测试文档 Agent

也记录了主代理已经完成的两批共 6 轮商业化改进：

1. 战场可读性与即时反馈。
2. 关卡目标与任务结构。
3. 敌方职业差异与策略压力。
4. 正式单位信息面板。
5. 关卡与单位数据集中化。
6. 战术预览、结算面板与 EffectLayer。

## 已知限制与下一步建议

当前仍是 Demo 级架构，下一步建议：

1. 把 `DEFAULT_UNIT_DATA`、关卡目标和 AI 参数迁移到外部 JSON 或 Godot Resource。
2. 把 `EffectLayer` 独立为 `scripts/effect_layer.gd`，让 `game.gd` 只调用效果接口。
3. 把 `UnitInfoPanel` 拆成正式 UI 控件：名称、HP 条、属性行、技能区、状态徽章。
4. 增加鼠标悬停实时攻击预览，而不是点击目标后才显示预览。
5. 增加正式开局任务面板和可交互结算按钮。
6. 建立自动化回归脚本，至少覆盖移动、攻击、技能、敌方回合和胜负条件。

## Godot 4.6.2 踩坑记录

项目搭建和校验过程中遇到的问题已整理到：

```text
docs/godot_4_6_2_pitfalls.md
```

遇到脚本报错、命令行没日志、`--headless` 崩溃、坐标错位、动画导入问题时，可以先查这里。
