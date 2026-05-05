# 主战斗脚本，挂在 scenes/main.tscn 的 Game 根节点上。
# 它负责把棋盘、单位、输入、回合、敌方 AI 和 UI 串在一起。
extends Node2D

# 战斗当前处于哪个阶段。
# PLAYER_TURN：玩家可以选择单位、移动和攻击。
# ENEMY_TURN：敌方 AI 自动行动，玩家输入会被忽略。
# VICTORY / DEFEAT：战斗结束，按钮和输入不再推进回合。
enum Phase { PLAYER_TURN, ENEMY_TURN, VICTORY, DEFEAT }

# 单位场景。所有玩家和敌人都会从这个场景实例化出来。
const UNIT_SCENE := preload("res://scenes/unit.tscn")

# 四方向移动。战旗游戏里通常只允许上下左右走格子，不允许斜向移动。
const DIRECTIONS := [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP,
]

# 棋盘节点，提供格子尺寸、障碍格、坐标转换和高亮绘制。
@onready var board: GridBoard = $Board

# 所有单位都会作为 Board/Units 的子节点。
# 这样单位坐标和棋盘坐标都在 Board 的局部坐标系里，计算更简单。
@onready var units_root: Node2D = $Board/Units

# 顶部 UI：当前回合文字、提示文字、结束回合按钮。
@onready var turn_label: Label = %TurnLabel
@onready var info_label: Label = %InfoLabel
@onready var end_turn_button: Button = %EndTurnButton

# 当前战斗阶段，默认从玩家回合开始。
var phase := Phase.PLAYER_TURN

# 当前被玩家选中的单位。没有选中任何单位时为 null。
var selected_unit: BattleUnit

# 当前战场上的所有单位，包括玩家和敌人。
# 单位死亡时会从这个数组移除。
var units: Array[BattleUnit] = []

# 当前选中单位能移动到哪些格子。
# 玩家点击空格时，会用它判断能不能移动。
var reachable_cells: Array[Vector2i] = []

# 当前选中单位能攻击哪些格子。
# 玩家点击敌方单位时，会用它判断能不能攻击。
var attackable_cells: Array[Vector2i] = []


# Godot 在节点进入场景树并准备完成后调用。
# 这里连接按钮事件、生成默认单位，并初始化 UI。
func _ready() -> void:
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	_spawn_default_units()
	_show_info("Select a unit to act.")
	_update_ui()


# 处理没有被 UI 或 Area2D 消耗掉的鼠标输入。
# 本项目主要用鼠标左键点击棋盘空格来移动单位。
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if phase != Phase.PLAYER_TURN:
			return

		var clicked_cell := board.world_to_cell(get_global_mouse_position())
		if not board.is_inside(clicked_cell):
			_clear_selection()
			return

		var unit_at_cell := _unit_at(clicked_cell)
		if unit_at_cell != null:
			_on_unit_selected(unit_at_cell)
			return

		if selected_unit != null and reachable_cells.has(clicked_cell):
			await _move_unit(selected_unit, clicked_cell)
			_refresh_selection_after_action()


# 生成一组演示用单位。
# 后续做关卡系统时，可以把这份数据改成从关卡资源、JSON 或 TileMap 标记里读取。
func _spawn_default_units() -> void:
	var unit_data := [
		{"name": "Captain", "team": "player", "grid_position": Vector2i(1, 3), "max_hp": 14, "attack_power": 5, "move_range": 3},
		{"name": "Archer", "team": "player", "grid_position": Vector2i(1, 5), "max_hp": 10, "attack_power": 4, "move_range": 3, "attack_range": 2},
		{"name": "Raider", "team": "enemy", "grid_position": Vector2i(8, 2), "max_hp": 10, "attack_power": 3, "move_range": 3},
		{"name": "Guard", "team": "enemy", "grid_position": Vector2i(8, 5), "max_hp": 12, "attack_power": 4, "move_range": 2},
	]

	for data in unit_data:
		var unit := UNIT_SCENE.instantiate() as BattleUnit
		units_root.add_child(unit)
		unit.setup(data, board.cell_size)
		unit.selected.connect(_on_unit_selected)
		units.append(unit)


# 处理单位被点击后的逻辑。
# 参数 unit 是被点击的单位，可能是己方，也可能是敌方。
func _on_unit_selected(unit: BattleUnit) -> void:
	if phase != Phase.PLAYER_TURN:
		return

	if unit.team == "player":
		if unit.has_acted:
			_show_info("%s has already acted." % unit.unit_name)
			return
		_select_unit(unit)
		return

	if selected_unit != null and attackable_cells.has(unit.grid_position):
		_attack(selected_unit, unit)
		_refresh_selection_after_action()


# 选中一个玩家单位，并刷新它的移动范围和攻击范围。
# 参数 unit 必须是玩家单位，并且本回合还没有行动过。
func _select_unit(unit: BattleUnit) -> void:
	_clear_selection()
	selected_unit = unit
	selected_unit.set_selected(true)
	reachable_cells = _find_reachable_cells(unit)
	attackable_cells = _find_attack_cells(unit.grid_position, unit.attack_range, true)
	board.set_highlights(reachable_cells, attackable_cells)
	_show_info("%s selected. Blue: move, red: attack." % unit.unit_name)


# 清除当前选中单位和棋盘高亮。
# 点击棋盘外、结束回合、单位行动完成时都会调用。
func _clear_selection() -> void:
	if selected_unit != null:
		selected_unit.set_selected(false)
	selected_unit = null
	reachable_cells.clear()
	attackable_cells.clear()
	board.clear_highlights()


# 单位移动或攻击后刷新选择状态。
# 如果已经攻击，就清除选择；如果只是移动，就保留单位并刷新攻击范围。
func _refresh_selection_after_action() -> void:
	if selected_unit == null:
		return

	if selected_unit.has_acted:
		_clear_selection()
	else:
		_select_unit(selected_unit)

	_check_battle_end()
	_update_ui()


# 把单位移动到目标格子，并播放一个很短的 Tween 动画。
# 参数 unit 是要移动的单位；target_cell 是目标格子坐标。
func _move_unit(unit: BattleUnit, target_cell: Vector2i) -> void:
	unit.grid_position = target_cell
	unit.has_moved = true
	var tween := create_tween()
	tween.tween_property(unit, "position", Vector2(target_cell) * board.cell_size + Vector2(board.cell_size, board.cell_size) * 0.5, 0.18).set_trans(Tween.TRANS_SINE)
	await tween.finished
	attackable_cells = _find_attack_cells(unit.grid_position, unit.attack_range, true)
	board.set_highlights([], attackable_cells)
	_show_info("%s moved. You may attack if a target is in range." % unit.unit_name)


# 执行一次普通攻击。
# 参数 attacker 是攻击者；defender 是受击者。
# 当前规则：攻击后攻击者本回合行动结束；目标血量为 0 时从战场移除。
func _attack(attacker: BattleUnit, defender: BattleUnit) -> void:
	defender.take_damage(attacker.attack_power)
	attacker.has_acted = true
	_show_info("%s attacks %s for %d damage." % [attacker.unit_name, defender.unit_name, attacker.attack_power])

	if defender.hp <= 0:
		units.erase(defender)
		defender.queue_free()


# 玩家点击“End Turn”按钮时调用。
# 切到敌方回合，等待敌方 AI 行动完成，再回到玩家回合。
func _on_end_turn_pressed() -> void:
	if phase != Phase.PLAYER_TURN:
		return

	_clear_selection()
	phase = Phase.ENEMY_TURN
	_update_ui()
	await _run_enemy_turn()
	if phase == Phase.ENEMY_TURN:
		_start_player_turn()


# 敌方 AI 的完整回合。
# 当前 AI 很简单：每个敌人找最近的玩家单位，能打就打，不能打就向目标靠近。
func _run_enemy_turn() -> void:
	_show_info("Enemy turn...")
	await get_tree().create_timer(0.3).timeout

	for enemy in units.filter(func(unit: BattleUnit) -> bool: return unit.team == "enemy"):
		enemy.reset_turn()
		if phase != Phase.ENEMY_TURN:
			return

		var target := _nearest_unit(enemy.grid_position, "player")
		if target == null:
			break

		if _distance(enemy.grid_position, target.grid_position) <= enemy.attack_range:
			_attack(enemy, target)
			_check_battle_end()
			await get_tree().create_timer(0.25).timeout
			continue

		var next_cell := _best_enemy_move(enemy, target.grid_position)
		if next_cell != enemy.grid_position:
			await _move_unit(enemy, next_cell)

		if is_instance_valid(target) and _distance(enemy.grid_position, target.grid_position) <= enemy.attack_range:
			_attack(enemy, target)

		_check_battle_end()
		await get_tree().create_timer(0.25).timeout


# 开始新的玩家回合。
# 重置所有玩家单位的移动和行动状态，然后刷新 UI。
func _start_player_turn() -> void:
	for unit in units:
		if unit.team == "player":
			unit.reset_turn()
	phase = Phase.PLAYER_TURN
	_show_info("Player turn. Select a unit.")
	_update_ui()


# 检查战斗是否结束。
# 如果敌人全灭就是胜利；如果玩家单位全灭就是失败。
func _check_battle_end() -> void:
	var player_count := units.filter(func(unit: BattleUnit) -> bool: return unit.team == "player").size()
	var enemy_count := units.filter(func(unit: BattleUnit) -> bool: return unit.team == "enemy").size()

	if enemy_count == 0:
		phase = Phase.VICTORY
		_clear_selection()
		_show_info("Victory! All enemies are defeated.")
	elif player_count == 0:
		phase = Phase.DEFEAT
		_clear_selection()
		_show_info("Defeat. All player units are down.")

	_update_ui()


# 计算单位当前能移动到哪些格子。
# 返回值是格子坐标数组，不包含起点、不包含障碍格、不包含已有单位的格子。
func _find_reachable_cells(unit: BattleUnit) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if unit.has_moved:
		return result

	var frontier: Array[Vector2i] = [unit.grid_position]
	var cost_by_cell := {}
	cost_by_cell[unit.grid_position] = 0

	while not frontier.is_empty():
		var current := frontier.pop_front() as Vector2i
		var current_cost := cost_by_cell[current] as int

		for direction in DIRECTIONS:
			var next_cell: Vector2i = current + direction
			var next_cost: int = current_cost + 1
			if next_cost > unit.move_range:
				continue
			if not board.is_inside(next_cell) or board.is_blocked(next_cell) or _unit_at(next_cell) != null:
				continue
			if cost_by_cell.has(next_cell) and int(cost_by_cell[next_cell]) <= next_cost:
				continue

			cost_by_cell[next_cell] = next_cost
			frontier.append(next_cell)
			result.append(next_cell)

	return result


# 计算从 origin 位置出发，在 attack_range 内的可攻击格。
# only_enemies 为 true 时，只返回有敌方单位的格子。
func _find_attack_cells(origin: Vector2i, attack_range: int, only_enemies := false) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(board.grid_size.y):
		for x in range(board.grid_size.x):
			var cell := Vector2i(x, y)
			if _distance(origin, cell) > attack_range:
				continue
			if cell == origin:
				continue
			if only_enemies:
				var unit := _unit_at(cell)
				if unit == null or selected_unit == null or unit.team == selected_unit.team:
					continue
			result.append(cell)
	return result


# 给敌方 AI 使用：从可移动格子里挑一个离目标最近的格子。
# 如果没有更近的格子，就留在原地。
func _best_enemy_move(enemy: BattleUnit, target_cell: Vector2i) -> Vector2i:
	var candidates := _find_reachable_cells(enemy)
	var best_cell := enemy.grid_position
	var best_distance := _distance(enemy.grid_position, target_cell)

	for cell in candidates:
		var distance := _distance(cell, target_cell)
		if distance < best_distance:
			best_distance = distance
			best_cell = cell

	return best_cell


# 查找距离 from_cell 最近的某个阵营单位。
# target_team 可以是 "player" 或 "enemy"。
func _nearest_unit(from_cell: Vector2i, target_team: String) -> BattleUnit:
	var nearest: BattleUnit
	var nearest_distance := 9999
	for unit in units:
		if unit.team != target_team:
			continue
		var distance := _distance(from_cell, unit.grid_position)
		if distance < nearest_distance:
			nearest = unit
			nearest_distance = distance
	return nearest


# 查询某个格子上是否有单位。
# 有单位则返回 BattleUnit；没有单位则返回 null。
func _unit_at(cell: Vector2i) -> BattleUnit:
	for unit in units:
		if unit.grid_position == cell:
			return unit
	return null


# 计算两个格子的曼哈顿距离。
# 战旗的四方向移动通常用这个距离判断范围。
func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


# 更新顶部提示文字。
func _show_info(text: String) -> void:
	info_label.text = text


# 根据当前 phase 刷新回合文字和结束回合按钮状态。
func _update_ui() -> void:
	match phase:
		Phase.PLAYER_TURN:
			turn_label.text = "Player Turn"
			end_turn_button.disabled = false
		Phase.ENEMY_TURN:
			turn_label.text = "Enemy Turn"
			end_turn_button.disabled = true
		Phase.VICTORY:
			turn_label.text = "Victory"
			end_turn_button.disabled = true
		Phase.DEFEAT:
			turn_label.text = "Defeat"
			end_turn_button.disabled = true
