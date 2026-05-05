# 棋盘脚本，挂在 scenes/main.tscn 的 Board 节点上。
# 它负责保存棋盘尺寸、障碍格、鼠标悬停格，并用 _draw() 绘制占位棋盘。
class_name GridBoard
extends Node2D

# 棋盘尺寸，x 是列数，y 是行数。
# 当前是 10 列、7 行。
@export var grid_size := Vector2i(10, 7)

# 每个格子的像素大小。
# 64 表示一个格子宽 64 像素、高 64 像素。
@export var cell_size := 64

# 障碍格列表。
# Vector2i(4, 2) 表示第 4 列、第 2 行的格子不可通行。
@export var blocked_cells: Array[Vector2i] = [
	Vector2i(4, 2),
	Vector2i(4, 3),
	Vector2i(5, 3),
	Vector2i(7, 1),
]

# 当前要高亮显示的可移动格子。
# Game 脚本选中单位后会把结果传进来。
var move_cells: Array[Vector2i] = []

# 当前要高亮显示的可攻击格子。
# Game 脚本选中单位或移动后会把结果传进来。
var attack_cells: Array[Vector2i] = []

# 鼠标当前悬停的格子。
# Vector2i(-1, -1) 表示鼠标不在有效棋盘格里。
var hover_cell := Vector2i(-1, -1)


# 每帧检查鼠标在哪个格子上。
# 如果悬停格变化，就重绘棋盘，让悬停效果跟着鼠标更新。
func _process(_delta: float) -> void:
	var next_hover := world_to_cell(get_global_mouse_position())
	if next_hover != hover_cell:
		hover_cell = next_hover
		queue_redraw()


# 判断某个格子是否在棋盘范围内。
# 参数 cell 是格子坐标；返回 true 表示它没有越界。
func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


# 判断某个格子是否是障碍格。
# 参数 cell 是格子坐标；返回 true 表示这个格子不可通行。
func is_blocked(cell: Vector2i) -> bool:
	return blocked_cells.has(cell)


# 把世界坐标转换成棋盘格子坐标。
# 鼠标位置是世界坐标，战棋逻辑需要格子坐标，所以点击时会调用它。
func world_to_cell(world_position: Vector2) -> Vector2i:
	var local_position := to_local(world_position)
	return Vector2i(floori(local_position.x / cell_size), floori(local_position.y / cell_size))


# 把格子坐标转换成世界坐标。
# 返回的是这个格子的中心点，适合让单位站在格子中央。
func cell_to_world(cell: Vector2i) -> Vector2:
	return global_position + Vector2(cell) * cell_size + Vector2(cell_size, cell_size) * 0.5


# 设置棋盘高亮。
# new_move_cells 是蓝色可移动格；new_attack_cells 是红色可攻击格。
func set_highlights(new_move_cells: Array[Vector2i], new_attack_cells: Array[Vector2i]) -> void:
	move_cells = new_move_cells
	attack_cells = new_attack_cells
	queue_redraw()


# 清除所有高亮格子。
# 取消选择、结束回合或战斗结束时会调用。
func clear_highlights() -> void:
	move_cells.clear()
	attack_cells.clear()
	queue_redraw()


# 绘制棋盘、障碍、移动范围、攻击范围和鼠标悬停效果。
# 当前这是占位美术，后续可以替换为 TileMapLayer 或图片节点。
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(grid_size * cell_size)), Color("#1a2029"))

	for y in grid_size.y:
		for x in grid_size.x:
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell * cell_size), Vector2(cell_size, cell_size))
			var color := Color("#2b3542") if (x + y) % 2 == 0 else Color("#24303c")

			if is_blocked(cell):
				color = Color("#40505c")
			if move_cells.has(cell):
				color = Color("#2e7fc6")
			if attack_cells.has(cell):
				color = Color("#a84848")
			if cell == hover_cell and is_inside(cell):
				color = color.lightened(0.18)

			draw_rect(rect.grow(-1.0), color)
			draw_rect(rect, Color("#111820"), false, 1.0)

			if is_blocked(cell):
				draw_line(rect.position + Vector2(12.0, 12.0), rect.end - Vector2(12.0, 12.0), Color("#85929e"), 3.0)
				draw_line(Vector2(rect.end.x - 12.0, rect.position.y + 12.0), Vector2(rect.position.x + 12.0, rect.end.y - 12.0), Color("#85929e"), 3.0)
