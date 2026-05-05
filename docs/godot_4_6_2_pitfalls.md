# Godot 4.6.2 战旗 Demo 踩坑记录

这份文档记录的是本项目搭建和校验过程中实际遇到的问题。格式统一为“问题 / 原因 / 解决方式 / 建议”，方便以后继续扩展。

## 1. 普通 Godot exe 不输出终端日志

**问题**

在 PowerShell 里运行 `Godot_v4.6.2-stable_win64.exe`，命令很快退出，但几乎没有任何输出。这样不方便确认脚本有没有报错。

**原因**

Windows 下普通 Godot exe 更适合图形界面启动，不一定把日志写回当前终端。

**解决方式**

使用同目录下的 console 版：

```powershell
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --scene res://scenes/main.tscn --quit-after 5
```

**建议**

日常用普通 exe 打开编辑器；排查脚本、场景和启动错误时，用 console 版。

## 2. `--headless` 在当前环境里崩溃

**问题**

用 `--headless` 启动 Godot 4.6.2 时，console 输出 `CrashHandlerException: Program crashed with signal 11`。

**原因**

这是当前机器、Godot 4.6.2、Windows、显示/渲染后端组合下的引擎运行问题。它发生在进入项目日志之前，不像是本项目脚本导致的错误。

**解决方式**

不要用 `--headless` 校验这个项目。改用 console 版正常显示模式：

```powershell
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --scene res://scenes/main.tscn --quit-after 5
```

**建议**

如果 headless 崩溃，不要先怀疑业务脚本。先用 `--help` 查看可用参数，再换 console 版普通模式做脚本解析和场景启动校验。

## 3. `--check-only` 必须搭配 `--script`

**问题**

想只检查 GDScript 语法和类型，不想完整启动游戏。

**原因**

Godot 的 `--check-only` 是给脚本检查用的，需要和 `--script` 一起使用。

**解决方式**

逐个检查脚本：

```powershell
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/game.gd
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/grid_board.gd
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --check-only --script res://scripts/unit.gd
```

**建议**

改完脚本后先跑 `--check-only`，再启动主场景。这样能更快定位“语法问题”还是“运行时问题”。

## 4. Godot 4.6.2 的类型推断比较严格

**问题**

脚本里曾经出现类似错误：

```text
Parse Error: Cannot infer the type of "next" variable because the value doesn't have a set type.
```

**原因**

`DIRECTIONS` 这样的数组如果没有显式类型，Godot 可能无法可靠推断循环变量和计算结果的类型。

**解决方式**

给关键变量加类型标注：

```gdscript
var next_cell: Vector2i = current + direction
var next_cost: int = current_cost + 1
```

**建议**

Godot 4 项目里，格子坐标、单位数组、返回值都尽量写清楚类型。类型越明确，编辑器提示和命令行检查越稳定。

## 5. Windows 终端可能把中文显示成乱码

**问题**

PowerShell 里读取 README 或 GDScript 时，中文可能显示成乱码。

**原因**

这是终端编码显示问题，不一定代表文件本身坏了。Godot 通常能读取 UTF-8 文件，但 PowerShell 的显示编码可能不一致。

**解决方式**

这次项目里保留中文文档和中文注释，但代码中的变量名、函数名、UI 文案仍使用英文，降低脚本解析风险。

**建议**

中文适合写在注释和 Markdown 文档里；脚本标识符、资源路径、节点名建议使用英文和 ASCII。

## 6. 主场景启动校验要真的启动场景

**问题**

脚本逐个 `--check-only` 通过，不代表场景里的节点路径、预加载资源、信号连接一定都正确。

**原因**

`--check-only` 主要检查脚本解析，不会完整执行主场景的 `_ready()` 和节点查找。

**解决方式**

脚本检查后再短暂启动主场景：

```powershell
E:\godot\Godot_v4.6.2-stable_win64_console.exe --path E:\myindiegames\gamedemo1 --scene res://scenes/main.tscn --quit-after 5
```

**建议**

校验顺序建议是：

1. 检查单个脚本。
2. 启动主场景几帧。
3. 打开编辑器手动点击单位、移动、攻击、结束回合。

## 7. 格子坐标和世界坐标不要混用

**问题**

战旗游戏里经常会遇到单位位置不对、点击格子错位、移动目标偏半格的问题。

**原因**

游戏逻辑使用的是格子坐标，例如 `Vector2i(1, 3)`；Godot 节点位置使用的是像素坐标，例如 `Vector2(96, 224)`。两者不能直接混用。

**解决方式**

本项目在 `GridBoard` 里集中处理转换：

- `world_to_cell()`：鼠标世界坐标转格子坐标
- `cell_to_world()`：格子坐标转世界坐标

**建议**

战斗逻辑只保存格子坐标；真正移动节点时再换算成像素坐标。

## 8. 单位放在 Board 节点下，要使用局部坐标移动

**问题**

单位节点是 `Board/Units/Unit`，如果直接使用全局坐标移动，容易出现偏移。

**原因**

`Unit` 是 `Board` 的子节点，`Unit.position` 是相对于 `Board` 的局部坐标，不是屏幕全局坐标。

**解决方式**

移动单位时用局部坐标：

```gdscript
Vector2(target_cell) * board.cell_size + Vector2(board.cell_size, board.cell_size) * 0.5
```

**建议**

同一个系统内尽量固定一种坐标空间。单位都放在 `Board` 下，就让单位移动使用 Board 的局部坐标。

## 9. 移动和攻击范围要分开维护

**问题**

如果把移动范围和攻击范围混在一起，移动后可能还能继续移动，或者攻击格显示不准。

**原因**

战旗游戏通常有“移动前可走哪些格”和“当前位置可攻击哪些格”两套不同数据。

**解决方式**

本项目使用两个数组：

- `reachable_cells`：当前选中单位可移动的格子
- `attackable_cells`：当前选中单位可攻击的格子

移动后清空移动格，只刷新攻击格。

**建议**

后续加入技能、地形消耗、远程攻击时，也继续把“移动判定”和“攻击判定”分开写。

## 10. 移动后要记录行动状态，避免无限移动

**问题**

如果不记录单位已经移动过，玩家可以反复点击蓝色格，让单位在同一回合无限移动。

**原因**

回合制游戏需要明确“本回合是否已经移动”和“本回合是否已经完成行动”。

**解决方式**

本项目在 `BattleUnit` 里使用：

- `has_moved`：本回合是否已经移动
- `has_acted`：本回合是否已经完成攻击或行动

`_find_reachable_cells()` 会在 `has_moved == true` 时返回空数组。

**建议**

后续如果加入“待机”按钮，可以把待机也设置为 `has_acted = true`。

## 11. 点击单位和点击空格要分流处理

**问题**

玩家点击棋盘时，可能点到己方单位、敌方单位、空格、棋盘外。不同情况要做不同事情。

**原因**

战棋游戏的鼠标输入不是单一动作，而是根据当前回合、选中单位和点击对象决定结果。

**解决方式**

本项目的输入流程是：

1. 点击棋盘外：清除选择。
2. 点击己方单位：选中单位。
3. 点击敌方单位：如果在攻击范围内就攻击。
4. 点击空格：如果在移动范围内就移动。

**建议**

后续加技能菜单、右键取消、角色详情面板时，也先设计清楚点击对象和当前状态，再写输入逻辑。
