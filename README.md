# Godot 2D 战旗 Demo

这是一个 Godot 4.6.2 stable 的 2D 战旗游戏框架。当前版本使用脚本绘制占位美术，方便先学习玩法结构，后续再替换成自己的图片、动画和 UI 资源。

当前已包含：

- 棋盘绘制与障碍格
- 四个玩家角色：Warrior、Mage、Ranger、Cleric
- 四个敌方怪物：Werewolf、Goblin、Necromancer、Vampire
- 野外地形：草地、山丘、河流、岩石障碍
- 单位选择、移动、攻击
- 选中单位后的操作菜单：Attack、Defend、Skill
- 职业技能与技能冷却
- 玩家回合与简单敌方 AI 回合
- 顶部状态栏与结束回合按钮
- 一套 AI 生成的原创占位美术素材

主场景是 `res://scenes/main.tscn`。

## 如何运行项目

1. 打开 Godot 4.6.2 stable。
2. 导入本项目目录。
3. 确认主场景是 `res://scenes/main.tscn`。
4. 点击运行按钮。

如果要用命令行检查脚本，推荐使用 console 版 Godot：

```powershell
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/game.gd
```

普通 `Godot_v4.6.2-stable_win64.exe` 不一定会把日志输出到 PowerShell，所以排查错误时优先用 `Godot_v4.6.2-stable_win64_console.exe`。

## 如何替换美术素材

当前项目已经接入了一套 AI 生成的原创占位美术。素材集中放在 `res://assets/generated/`，后续你可以逐张替换。

### 单位外观

单位场景在 `res://scenes/unit.tscn`，脚本是 `res://scripts/unit.gd`。

当前单位外观由 `unit.tscn` 里的 `AnimatedSprite2D` 显示。每个角色的帧动画放在：

`assets/generated/unit_frames/<角色名>/`

当前每个角色都有这些动画：

- `idle_0.png` 到 `idle_3.png`
- `move_0.png` 到 `move_3.png`
- `attack_0.png` 到 `attack_3.png`
- `hit_0.png` 到 `hit_2.png`
- `defeat_0.png` 到 `defeat_3.png`
- `death_0.png` 到 `death_3.png`

旧的单张角色图仍然保留在：

- `assets/generated/units/warrior.png`
- `assets/generated/units/mage.png`
- `assets/generated/units/ranger.png`
- `assets/generated/units/cleric.png`
- `assets/generated/units/werewolf.png`
- `assets/generated/units/goblin.png`
- `assets/generated/units/necromancer.png`
- `assets/generated/units/vampire.png`

替换方式：

1. 打开 `scenes/unit.tscn`。
2. 保留 `Unit` 节点、`AnimatedSprite2D` 和 `CollisionShape2D`。
3. 用同名 PNG 覆盖 `assets/generated/unit_frames/<角色名>/` 里的帧图片。
4. 如果帧数变化，需要同步修改 `unit.gd` 里的 `_add_animation_frames()` 调用参数。

`unit.gd` 的 `_draw()` 现在只画选中圈、悬停圈和血条。建议先保留这些辅助显示，等角色图稳定后再换成正式 UI。

### 棋盘格子

棋盘节点在 `res://scenes/main.tscn` 的 `Board` 节点上，脚本是 `res://scripts/grid_board.gd`。

当前棋盘由 `grid_board.gd` 的 `_draw()` 绘制，但绘制时已经使用生成好的 64x64 图块：

- `assets/generated/tiles/grass.png`
- `assets/generated/tiles/hill.png`
- `assets/generated/tiles/river.png`
- `assets/generated/tiles/rocks.png`
- `assets/generated/tiles/highlight_move.png`
- `assets/generated/tiles/highlight_attack.png`
- `assets/generated/tiles/highlight_hover.png`

草地和河流已经有帧动画：

- `assets/generated/tile_frames/grass_0.png` 到 `grass_5.png`
- `assets/generated/tile_frames/river_0.png` 到 `river_5.png`

替换方式有两种：

1. 直接用同名 PNG 覆盖 `assets/generated/tiles/` 里的图片。
2. 修改 `grid_board.gd` 顶部 preload 路径，指向你的正式素材。
3. 后续改成 `TileMapLayer` 或自定义贴图节点，用图片资源绘制地形。

如果改成 `TileMapLayer`，建议保留 `GridBoard` 脚本里的坐标转换方法，例如 `world_to_cell()` 和 `cell_to_world()`，因为战棋逻辑仍然需要格子坐标。

### 障碍格

障碍和特殊地形配置在 `grid_board.gd`：

```gdscript
@export var blocked_cells: Array[Vector2i] = [
	...
]

@export var hill_cells: Array[Vector2i] = [
	...
]

@export var river_cells: Array[Vector2i] = [
	...
]
```

`blocked_cells` 和 `river_cells` 当前不可通行；`hill_cells` 目前只是视觉地形，可以通行。

### 移动和攻击高亮

移动和攻击高亮也在 `grid_board.gd` 的 `_draw()` 里。

可以替换的内容：

- 蓝色移动格
- 红色攻击格
- 鼠标悬停效果
- 障碍格标记

如果想换成图片，可以在每个高亮格子位置生成 `Sprite2D`，或使用单独的 `TileMapLayer` 放高亮图块。

### UI 按钮和状态栏

顶部 UI 在 `res://scenes/main.tscn`：

- `UI/TopBar`：顶部状态栏容器
- `TurnLabel`：显示当前回合
- `InfoLabel`：显示操作提示
- `EndTurnButton`：结束回合按钮
- `assets/generated/ui/end_turn_button.png`：生成的按钮素材

可以替换的内容：

- 按钮样式
- 字体
- 状态栏背景
- 回合提示文字
- 信息提示文字

当前按钮图片通过 `game.gd` 的 `_style_end_turn_button()` 接入。后续要做更完整的 UI，可以给按钮创建 Godot Theme。

这些 UI 不影响战斗逻辑，可以放心换主题、字体和布局。

## 代码入口

- `scripts/game.gd`：战斗流程、回合、输入、敌方 AI、胜负判断
- `scripts/grid_board.gd`：棋盘、格子坐标、野外地形、障碍、高亮绘制
- `scripts/unit.gd`：单位属性、血量、行动状态、点击检测、角色图片显示

如果你是 Godot 新手，建议先读 `unit.gd`，再读 `grid_board.gd`，最后读 `game.gd`。这样会比较容易理解“单位是什么 -> 棋盘是什么 -> 回合流程怎么把它们连起来”。

## 当前战斗操作

点击我方单位后会弹出操作菜单：

- `Attack`：进入普通攻击模式，点击红色范围内的敌人进行攻击。
- `Defend`：进入防守，本回合行动结束，并让下一次受到的伤害减半。
- `Skill`：释放职业技能。技能释放后进入冷却，冷却会在玩家新回合开始时减少。

当前职业技能：

- Warrior / Whirlwind：冷却 2 回合，以自己为中心 3x3 范围内所有敌人受到 1.2 倍普攻伤害。
- Mage / Fireball：冷却 3 回合，前方 3x3 范围内所有敌人受到 1.5 倍普攻伤害。
- Ranger / Arrow Rain：冷却 3 回合，前方直线 6 格内所有敌人受到 1.2 倍普攻伤害。
- Cleric / Group Heal：冷却 3 回合，以自己为中心 3x3 范围内所有友方回复最大生命的 1/3。

## 踩坑记录

我把本项目搭建和校验过程中遇到的 Godot 4.6.2 坑整理到了：

`docs/godot_4_6_2_pitfalls.md`

遇到脚本报错、命令行没日志、headless 崩溃、坐标错位时，可以先去那里查。
