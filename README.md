# Godot 2D 战旗 Demo

这是一个使用 Godot 4.6.2 stable 制作的 2D 战旗游戏框架。项目目标是先把“能玩、能扩展、方便换美术”的基础结构搭起来，后续可以逐步替换成正式角色、地形、UI 和特效资源。

当前已包含：

- 2D 方格棋盘、障碍格、草地、山丘、河流和岩石地形
- 我方 4 个职业：战士、法师、牧师、游侠
- 敌方 4 个单位：狼人、哥布林、死灵、吸血鬼
- 单位选择、移动、普通攻击、防守、职业技能
- 操作菜单：移动、攻击、防守、技能、取消
- 技能冷却、技能范围高亮、敌方移动范围预览
- 我方回合和简单敌方 AI 回合
- 单位帧动画：待机、移动、攻击、技能、受击、击败、死亡
- 草地和河流帧动画
- 顶部状态栏和结束回合按钮

主场景是：

```text
res://scenes/main.tscn
```

## 如何运行项目

1. 打开 Godot 4.6.2 stable。
2. 导入本项目目录：`E:\myindiegames\gamedemo1`。
3. 确认主场景是 `res://scenes/main.tscn`。
4. 点击 Godot 编辑器右上角的运行按钮。

也可以用 console 版 Godot 做脚本检查：

```powershell
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/game.gd
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/unit.gd
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --scene res://scenes/main.tscn --quit-after 5
```

普通版 `Godot_v4.6.2-stable_win64.exe` 不一定会把日志输出到 PowerShell。排查报错时，推荐使用 `Godot_v4.6.2-stable_win64_console.exe`。

## 项目结构

```text
scenes/main.tscn                 主战斗场景
scenes/unit.tscn                 单位场景
scripts/game.gd                  回合、输入、战斗、AI、技能逻辑
scripts/grid_board.gd            棋盘、地形、坐标转换、高亮绘制
scripts/unit.gd                  单位属性、血量、行动状态、帧动画播放
assets/generated/unit_frames/    单位逐帧动画
assets/generated/tile_frames/    草地和河流逐帧动画
assets/generated/tiles/          地形和高亮图块
assets/generated/ui/             UI 图片
assets/source/                   原始精灵图源文件
docs/                            Godot 踩坑文档
```

## 如何替换单位美术

单位场景在：

```text
res://scenes/unit.tscn
```

单位显示节点是 `AnimatedSprite2D`。所有单位动画帧都从这里读取：

```text
assets/generated/unit_frames/<单位名>/
```

例如战士目录是：

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

可替换的单位目录：

- `assets/generated/unit_frames/warrior/`：战士
- `assets/generated/unit_frames/mage/`：法师
- `assets/generated/unit_frames/ranger/`：游侠
- `assets/generated/unit_frames/cleric/`：牧师
- `assets/generated/unit_frames/werewolf/`：狼人
- `assets/generated/unit_frames/goblin/`：哥布林
- `assets/generated/unit_frames/necromancer/`：死灵
- `assets/generated/unit_frames/vampire/`：吸血鬼

替换方式：

1. 准备透明背景 PNG，建议单帧尺寸保持 `64x64`。
2. 用同名文件覆盖对应目录里的帧图，例如 `warrior/attack_0.png`。
3. 文件名和序号保持一致，Godot 会自动重新导入。
4. 如果想增加或减少帧数，需要同步修改 `scripts/unit.gd` 里的 `_build_sprite_frames()`。

当前我方职业的攻击和技能素材已经来自你提供的两张精灵图：

- `assets/source/party_attack_skill_sheet.png`：战士、法师、牧师的攻击和技能源图
- `assets/source/ranger_attack_skill_sheet.png`：游侠的攻击和箭雨技能源图
- `assets/source/warrior_gemini_sheet.png`：战士移动和攻击源图

如果你之后继续给我类似的大精灵图，我可以继续自动切图并覆盖到对应目录。

## 攻击和技能动画是怎么播放的

普通攻击时，代码会调用：

```gdscript
play_attack_animation()
```

它会播放：

```text
attack_0.png -> attack_1.png -> attack_2.png -> attack_3.png
```

释放职业技能时，代码会调用：

```gdscript
play_skill_animation()
```

它会播放：

```text
skill_0.png -> skill_1.png -> skill_2.png -> skill_3.png
```

然后 `game.gd` 会继续播放范围高亮和命中特效。也就是说，角色本体动画和战场范围特效是分开的，后续可以分别替换。

## 如何替换棋盘和地形

棋盘节点在主场景的 `Board`，脚本是：

```text
res://scripts/grid_board.gd
```

当前地形图块在：

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

如果只是换图，直接覆盖同名 PNG 即可。如果后续要做更正式的地图系统，可以把棋盘改成 `TileMapLayer`，但建议保留 `GridBoard` 里的 `world_to_cell()` 和 `cell_to_world()`，因为战旗逻辑仍然需要格子坐标。

## 如何调整障碍和地形位置

障碍、山丘、河流格配置在 `scripts/grid_board.gd` 顶部：

```gdscript
@export var blocked_cells: Array[Vector2i] = [...]
@export var hill_cells: Array[Vector2i] = [...]
@export var river_cells: Array[Vector2i] = [...]
```

当前规则：

- `blocked_cells`：不可通行
- `river_cells`：不可通行
- `hill_cells`：目前只是视觉地形，可以通行

如果你想做“山丘移动消耗更高”“河流可以被飞行单位通过”这类规则，可以在 `game.gd` 的寻路逻辑里扩展。

## 如何替换 UI

主要 UI 在：

```text
res://scenes/main.tscn
```

可替换内容：

- `UI/TopBar`：顶部状态栏
- `TurnLabel`：当前回合文字
- `InfoLabel`：提示文字
- `EndTurnButton`：结束回合按钮
- `ActionMenu`：单位行为选择框
- `assets/generated/ui/end_turn_button.png`：结束回合按钮图片

行为选择框现在包含：

- 移动
- 攻击
- 防守
- 技能
- 取消

如果只是换视觉样式，可以在 Godot 里给按钮、面板和 Label 设置 Theme。不要改节点名称，否则 `game.gd` 里的 `%MoveButton`、`%AttackButton` 等引用会找不到节点。

## 当前职业技能

- 战士 / 旋风斩：冷却 2 回合，以自己为中心 3x3 区域内所有敌人受到 1.2 倍普攻伤害。
- 法师 / 火球术：冷却 3 回合，前方 3x3 区域内所有敌人受到 1.5 倍普攻伤害。
- 游侠 / 直射弓箭雨：冷却 3 回合，前方直线 6 格内所有敌人受到 1.2 倍普攻伤害。
- 牧师 / 群体治愈：冷却 3 回合，以自己为中心 3x3 区域内所有友方回复最大生命的 1/3。

## 当前战斗操作

1. 点击我方单位，弹出行为选择框。
2. 点击“移动”，显示蓝色移动范围。
3. 移动后，本回合不能再次移动，但可以继续攻击、防守或释放技能。
4. 点击“攻击”，选择框会关闭，并显示可攻击敌人。
5. 点击“技能”，选择框会关闭，并播放职业技能动画和范围效果。
6. 点击“取消”，取消当前单位选择。
7. 我方回合中点击敌人，可以预览它下回合可能的移动范围。

## 代码入口

- `scripts/unit.gd`：先读这个。它负责单位属性、血量、行动状态、动画播放和点击信号。
- `scripts/grid_board.gd`：再读这个。它负责棋盘尺寸、坐标转换、地形绘制和高亮绘制。
- `scripts/game.gd`：最后读这个。它负责把单位、棋盘、输入、回合、AI 和技能串起来。

如果你是 Godot 新手，建议按这个顺序读代码，会比直接从 `game.gd` 开始轻松很多。

## Godot 4.6.2 踩坑记录

项目搭建和校验过程中的坑已经整理到：

```text
docs/godot_4_6_2_pitfalls.md
```

遇到脚本报错、命令行没日志、`headless` 崩溃、坐标错位、动画导入问题时，可以先去这里查。
