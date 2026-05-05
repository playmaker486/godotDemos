# Godot 2D 战旗 Demo

这是一个 Godot 4.6.2 stable 的 2D 战旗游戏框架。当前版本使用脚本绘制占位美术，方便先学习玩法结构，后续再替换成自己的图片、动画和 UI 资源。

当前已包含：

- 棋盘绘制与障碍格
- 玩家单位和敌方单位
- 单位选择、移动、攻击
- 玩家回合与简单敌方 AI 回合
- 顶部状态栏与结束回合按钮

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

当前项目里大部分画面都是脚本里的 `_draw()` 临时画出来的。这些占位图形不是最终美术，只是为了让玩法能先跑起来。

### 单位外观

单位场景在 `res://scenes/unit.tscn`，脚本是 `res://scripts/unit.gd`。

当前单位外观由 `unit.gd` 的 `_draw()` 绘制：

- 蓝色圆形：玩家单位
- 红色圆形：敌方单位
- 黄色外圈：当前选中的单位
- 绿色血条：单位当前血量

替换方式：

1. 打开 `scenes/unit.tscn`。
2. 在 `Unit` 节点下面添加 `Sprite2D` 或 `AnimatedSprite2D`。
3. 给新节点设置自己的角色图片或动画帧。
4. 如果不想再显示圆形占位图，可以删除或注释 `unit.gd` 里的 `_draw()` 绘制内容。
5. 保留 `Area2D` 和 `CollisionShape2D`，因为它们负责鼠标点击检测。

建议先保留血条绘制，只替换角色本体。等角色图稳定后，再把血条也换成独立的 UI 节点或美术资源。

### 棋盘格子

棋盘节点在 `res://scenes/main.tscn` 的 `Board` 节点上，脚本是 `res://scripts/grid_board.gd`。

当前棋盘由 `grid_board.gd` 的 `_draw()` 绘制：

- 深色方格：普通地形
- 灰色带叉方格：障碍格
- 蓝色方格：可移动范围
- 红色方格：可攻击范围
- 变亮方格：鼠标悬停的格子

替换方式有两种：

1. 继续使用脚本绘制，只修改 `grid_board.gd` 里的颜色和线条。
2. 改成 `TileMapLayer` 或自定义贴图节点，用图片资源绘制地形。

如果改成 `TileMapLayer`，建议保留 `GridBoard` 脚本里的坐标转换方法，例如 `world_to_cell()` 和 `cell_to_world()`，因为战棋逻辑仍然需要格子坐标。

### 障碍格

障碍格配置在 `grid_board.gd` 的 `blocked_cells` 变量里：

```gdscript
@export var blocked_cells: Array[Vector2i] = [
	Vector2i(4, 2),
	Vector2i(4, 3),
	Vector2i(5, 3),
	Vector2i(7, 1),
]
```

你可以在 Godot Inspector 里修改这个数组，也可以直接改脚本。后续如果使用关卡编辑器或 TileMapLayer，可以把障碍格改成从地图数据里读取。

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

可以替换的内容：

- 按钮样式
- 字体
- 状态栏背景
- 回合提示文字
- 信息提示文字

这些 UI 不影响战斗逻辑，可以放心换主题、字体和布局。

## 代码入口

- `scripts/game.gd`：战斗流程、回合、输入、敌方 AI、胜负判断
- `scripts/grid_board.gd`：棋盘、格子坐标、障碍、高亮绘制
- `scripts/unit.gd`：单位属性、血量、行动状态、点击检测、占位绘制

如果你是 Godot 新手，建议先读 `unit.gd`，再读 `grid_board.gd`，最后读 `game.gd`。这样会比较容易理解“单位是什么 -> 棋盘是什么 -> 回合流程怎么把它们连起来”。

## 踩坑记录

我把本项目搭建和校验过程中遇到的 Godot 4.6.2 坑整理到了：

`docs/godot_4_6_2_pitfalls.md`

遇到脚本报错、命令行没日志、headless 崩溃、坐标错位时，可以先去那里查。
