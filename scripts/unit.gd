# 单位脚本，挂在 scenes/unit.tscn 的 Unit 节点上。
# Unit 是 Area2D，所以它可以接收鼠标点击事件。
class_name BattleUnit
extends Area2D

# 当玩家点击这个单位时发出。
# Game 脚本会监听这个信号，然后决定是选中己方单位还是攻击敌方单位。
signal selected(unit: BattleUnit)

# 单位显示名，用于 UI 提示。
@export var unit_name := "Unit"

# 单位阵营。
# "player" 表示玩家单位；"enemy" 表示敌方单位。
@export_enum("player", "enemy") var team := "player"

# 单位当前所在的格子坐标，不是像素坐标。
# 例如 Vector2i(1, 3) 表示第 1 列、第 3 行。
@export var grid_position := Vector2i.ZERO

# 最大生命值。
@export var max_hp := 10

# 普通攻击伤害。
@export var attack_power := 4

# 每回合最多能移动多少格。
@export var move_range := 3

# 攻击范围，使用曼哈顿距离计算。
# 1 表示只能攻击上下左右相邻格；2 表示可以打到两格远。
@export var attack_range := 1

# 当前生命值。
# setup() 会把它初始化为 max_hp。
var hp := max_hp

# 本回合是否已经移动过。
# 用来防止单位在同一回合无限移动。
var has_moved := false

# 本回合是否已经完成行动。
# 当前规则里，攻击后就算完成行动。
var has_acted := false

# 棋盘格子的像素大小。
# 单位需要知道它，才能把格子坐标转换为节点位置。
var cell_size := 64

# 是否正被玩家选中。
# 只影响占位绘制的黄色外圈，不影响战斗逻辑。
var is_selected := false

# 鼠标是否悬停在单位上。
# 只影响占位绘制的白色外圈，不影响战斗逻辑。
var is_hovered := false


# 用一份字典初始化单位。
# data 是单位配置，例如名字、阵营、血量和出生格；new_cell_size 是棋盘格子大小。
func setup(data: Dictionary, new_cell_size: int) -> void:
	unit_name = data.get("name", unit_name)
	team = data.get("team", team)
	grid_position = data.get("grid_position", grid_position)
	max_hp = data.get("max_hp", max_hp)
	attack_power = data.get("attack_power", attack_power)
	move_range = data.get("move_range", move_range)
	attack_range = data.get("attack_range", attack_range)
	hp = max_hp
	cell_size = new_cell_size
	position = Vector2(grid_position) * cell_size + Vector2(cell_size, cell_size) * 0.5
	queue_redraw()


# 直接设置单位所在格子，并同步更新节点位置。
# 当前移动动画由 Game 脚本负责，所以这个方法适合瞬移或初始化时使用。
func set_grid_position(value: Vector2i) -> void:
	grid_position = value
	position = Vector2(grid_position) * cell_size + Vector2(cell_size, cell_size) * 0.5


# 新回合开始时重置行动状态。
# 玩家回合开始会重置玩家单位；敌方行动前会重置敌方单位。
func reset_turn() -> void:
	has_moved = false
	has_acted = false
	queue_redraw()


# 让单位受到伤害。
# 参数 amount 是伤害值；返回 true 表示单位血量已经归零。
func take_damage(amount: int) -> bool:
	hp = max(hp - amount, 0)
	queue_redraw()
	return hp == 0


# 设置单位是否被选中。
# 这个状态只负责显示效果，真正的选中逻辑保存在 Game.selected_unit。
func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()


# 节点准备好后连接鼠标进入和离开事件。
# 这些事件只用来更新悬停显示效果。
func _ready() -> void:
	mouse_entered.connect(func() -> void:
		is_hovered = true
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		is_hovered = false
		queue_redraw()
	)


# 绘制单位占位美术。
# 后续替换成 Sprite2D 或 AnimatedSprite2D 后，可以删除或注释这里的绘制代码。
func _draw() -> void:
	var radius := cell_size * 0.32
	var body_color := Color("#4f8cff") if team == "player" else Color("#d95050")
	if has_acted:
		body_color = body_color.darkened(0.35)

	draw_circle(Vector2.ZERO, radius + 4.0, Color("#f4e38b") if is_selected else Color("#1f2630"))
	draw_circle(Vector2.ZERO, radius, body_color)

	if is_hovered:
		draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 48, Color.WHITE, 2.0)

	var hp_ratio := float(hp) / float(max_hp)
	var bar_width := cell_size * 0.62
	var bar_pos := Vector2(-bar_width * 0.5, radius + 8.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, 6.0)), Color("#26313f"))
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, 6.0)), Color("#62d26f"))


# Area2D 接收到鼠标事件时调用。
# 这里不直接处理选中或攻击，而是发出 selected 信号交给 Game 脚本判断。
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit(self)
