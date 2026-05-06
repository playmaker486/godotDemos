# 主战斗脚本，挂在 scenes/main.tscn 的 Game 根节点上。
# 它负责把棋盘、单位、输入、回合、敌方 AI 和 UI 串在一起。
extends Node2D

# 战斗当前处于哪个阶段。
# PLAYER_TURN：玩家可以选择单位、移动和攻击。
# ENEMY_TURN：敌方 AI 自动行动，玩家输入会被忽略。
# LEVEL_START：关卡说明面板显示中，战场输入被锁住。
# VICTORY / DEFEAT：战斗结束，按钮和输入不再推进回合。
enum Phase { LEVEL_START, PLAYER_TURN, ENEMY_TURN, VICTORY, DEFEAT }

# 玩家选中单位后的操作模式。
# MOVE：默认移动模式，可以点击蓝色格移动。
# ATTACK：点击敌方单位进行普通攻击。
# SKILL：点击技能按钮后的技能模式；部分技能会立即释放。
enum ActionMode { MOVE, ATTACK, SKILL }

# 单位场景。所有玩家和敌人都会从这个场景实例化出来。
const UNIT_SCENE := preload("res://scenes/unit.tscn")
const END_TURN_BUTTON_TEXTURE := preload("res://assets/generated/ui/end_turn_button.png")

# 相机自适应缩放用的边距。
# UI_TOP_RESERVED 是给顶部状态栏预留的屏幕高度，避免棋盘被 UI 盖住。
const CAMERA_MARGIN := 32.0
const UI_TOP_RESERVED := 80.0
const MIN_CAMERA_ZOOM := 0.65
const MAX_CAMERA_ZOOM := 1.8
const EQUIPMENT_POOL := {
	"iron_crest": {
		"id": "iron_crest",
		"name": "Iron Crest",
		"rarity": "Common",
		"preferred_unit": "Warrior",
		"icon_path": "res://assets/generated/equipment/iron_crest.png",
		"stat_mods": {"max_hp": 3},
		"description": "A battered crest that helps the front line hold."
	},
	"hunter_charm": {
		"id": "hunter_charm",
		"name": "Hunter Charm",
		"rarity": "Common",
		"preferred_unit": "Ranger",
		"icon_path": "res://assets/generated/equipment/hunter_charm.png",
		"stat_mods": {"attack_power": 1},
		"description": "A quiet charm for steadier shots."
	},
	"ember_ring": {
		"id": "ember_ring",
		"name": "Ember Ring",
		"rarity": "Rare",
		"preferred_unit": "Mage",
		"icon_path": "res://assets/generated/equipment/ember_ring.png",
		"stat_mods": {"attack_power": 1, "max_hp": 1},
		"description": "A warm ring with a stubborn inner flame."
	},
	"blood_brooch": {
		"id": "blood_brooch",
		"name": "Blood Brooch",
		"rarity": "Rare",
		"preferred_unit": "Cleric",
		"icon_path": "res://assets/generated/equipment/blood_brooch.png",
		"stat_mods": {"max_hp": 2, "attack_power": 1},
		"description": "A protective brooch polished to a dark shine."
	},
}
const LEVEL_CONFIGS := [
	{
		"name": "Riverside Breakthrough",
		"max_turns": 8,
		"protected_unit": "Cleric",
		"objective": "Defeat all enemies before the river line collapses.",
		"units": [
			{"name": "Warrior", "team": "player", "grid_position": Vector2i(1, 1), "max_hp": 16, "attack_power": 5, "move_range": 3},
			{"name": "Mage", "team": "player", "grid_position": Vector2i(1, 3), "max_hp": 9, "attack_power": 6, "move_range": 3, "attack_range": 2},
			{"name": "Ranger", "team": "player", "grid_position": Vector2i(1, 5), "max_hp": 11, "attack_power": 4, "move_range": 4, "attack_range": 2},
			{"name": "Cleric", "team": "player", "grid_position": Vector2i(2, 6), "max_hp": 12, "attack_power": 3, "move_range": 3},
			{"name": "Werewolf", "team": "enemy", "grid_position": Vector2i(8, 1), "max_hp": 14, "attack_power": 5, "move_range": 4, "drop_item_id": "hunter_charm"},
			{"name": "Goblin", "team": "enemy", "grid_position": Vector2i(8, 3), "max_hp": 9, "attack_power": 3, "move_range": 3, "drop_item_id": "iron_crest"},
			{"name": "Necromancer", "team": "enemy", "grid_position": Vector2i(7, 5), "max_hp": 10, "attack_power": 5, "move_range": 2, "attack_range": 2, "drop_item_id": "ember_ring"},
			{"name": "Vampire", "team": "enemy", "grid_position": Vector2i(8, 6), "max_hp": 13, "attack_power": 4, "move_range": 3, "drop_item_id": "blood_brooch"},
		],
	},
	{
		"name": "Moonlit Ford",
		"max_turns": 9,
		"protected_unit": "Cleric",
		"objective": "Cross the ford and break the night patrol.",
		"units": [
			{"name": "Warrior", "team": "player", "grid_position": Vector2i(1, 1), "max_hp": 16, "attack_power": 5, "move_range": 3},
			{"name": "Mage", "team": "player", "grid_position": Vector2i(1, 3), "max_hp": 9, "attack_power": 6, "move_range": 3, "attack_range": 2},
			{"name": "Ranger", "team": "player", "grid_position": Vector2i(1, 5), "max_hp": 11, "attack_power": 4, "move_range": 4, "attack_range": 2},
			{"name": "Cleric", "team": "player", "grid_position": Vector2i(2, 6), "max_hp": 12, "attack_power": 3, "move_range": 3},
			{"name": "Werewolf", "team": "enemy", "grid_position": Vector2i(7, 1), "max_hp": 16, "attack_power": 6, "move_range": 4},
			{"name": "Goblin", "team": "enemy", "grid_position": Vector2i(8, 2), "max_hp": 11, "attack_power": 4, "move_range": 3},
			{"name": "Necromancer", "team": "enemy", "grid_position": Vector2i(8, 5), "max_hp": 12, "attack_power": 6, "move_range": 2, "attack_range": 2},
			{"name": "Vampire", "team": "enemy", "grid_position": Vector2i(7, 6), "max_hp": 15, "attack_power": 5, "move_range": 3},
		],
	},
]
# 各职业技能参数。
const SKILL_COOLDOWNS := {
	"warrior": 2,
	"mage": 3,
	"ranger": 3,
	"cleric": 3,
}
const SKILL_NAMES := {
	"warrior": "旋风斩",
	"mage": "火球术",
	"ranger": "直射弓箭雨",
	"cleric": "群体治愈",
}

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
@onready var action_menu: PanelContainer = %ActionMenu
@onready var move_button: Button = %MoveButton
@onready var attack_button: Button = %AttackButton
@onready var defend_button: Button = %DefendButton
@onready var skill_button: Button = %SkillButton
@onready var cancel_button: Button = %CancelButton
@onready var ui_root: CanvasLayer = $UI

# 负责显示战场的 2D 相机。
# 窗口大小变化时会自动调整 zoom，让整张棋盘尽量完整显示。
@onready var camera: Camera2D = $Camera2D

# 当前战斗阶段，默认从关卡开始说明进入。
var phase := Phase.LEVEL_START
var current_level_index := 0
var current_turn := 1
var battle_result_reason := ""
var defeated_unit_names: Array[String] = []
var party_inventory: Array[Dictionary] = []
var pending_rewards: Array[String] = []
var level_progress_summary: Array[String] = []
var enemy_drop_by_name := {}
var unit_info_panel: PanelContainer
var unit_info_label: Label
var start_panel: PanelContainer
var start_label: Label
var start_button: Button
var result_panel: PanelContainer
var result_label: Label
var next_level_button: Button
var retry_button: Button
var effect_root: Node2D

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

# 当前菜单选择的操作模式。
var action_mode := ActionMode.MOVE


# Godot 在节点进入场景树并准备完成后调用。
# 这里连接按钮事件、生成默认单位，并初始化 UI。
func _ready() -> void:
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	move_button.pressed.connect(_on_move_button_pressed)
	attack_button.pressed.connect(_on_attack_button_pressed)
	defend_button.pressed.connect(_on_defend_button_pressed)
	skill_button.pressed.connect(_on_skill_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	get_viewport().size_changed.connect(_fit_camera_to_viewport)
	_style_end_turn_button()
	_build_battle_ui()
	_build_effect_layer()
	_load_level(0)
	_fit_camera_to_viewport.call_deferred()


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

		if selected_unit != null and action_mode == ActionMode.MOVE and reachable_cells.has(clicked_cell):
			await _move_unit(selected_unit, clicked_cell)
			_refresh_selection_after_action()


# 生成当前关卡的单位。玩家单位会继承本次运行中已经获得的装备。
func _spawn_default_units() -> void:
	for data in _current_unit_data():
		var unit := UNIT_SCENE.instantiate() as BattleUnit
		units_root.add_child(unit)
		unit.setup(data, board.cell_size)
		if unit.team == "player":
			var saved_item := _equipped_item_for_unit(unit.unit_name)
			if not saved_item.is_empty():
				unit.equip_item(saved_item)
		elif data.has("drop_item_id"):
			enemy_drop_by_name[unit.unit_name] = String(data.get("drop_item_id"))
		unit.selected.connect(_on_unit_selected)
		units.append(unit)


func _load_level(index: int) -> void:
	current_level_index = clampi(index, 0, LEVEL_CONFIGS.size() - 1)
	_clear_board_units()
	_clear_selection()
	_hide_result_panel()
	if start_panel != null:
		start_panel.visible = true
	current_turn = 1
	battle_result_reason = ""
	defeated_unit_names.clear()
	pending_rewards.clear()
	level_progress_summary.clear()
	enemy_drop_by_name.clear()
	phase = Phase.LEVEL_START
	_spawn_default_units()
	_show_info(_mission_brief())
	_show_unit_info(null)
	_show_start_panel()
	_update_ui()


func _clear_board_units() -> void:
	units.clear()
	for child in units_root.get_children():
		child.queue_free()
	if effect_root != null:
		for child in effect_root.get_children():
			child.queue_free()
	board.clear_highlights()


# 给结束回合按钮加上生成的 UI 图片。
# 这里用 icon 是最稳的接入方式；后续可以进一步换成完整 Theme。
func _style_end_turn_button() -> void:
	end_turn_button.icon = END_TURN_BUTTON_TEXTURE
	end_turn_button.custom_minimum_size = Vector2(170.0, 48.0)


func _build_battle_ui() -> void:
	unit_info_panel = PanelContainer.new()
	unit_info_panel.name = "UnitInfoPanel"
	unit_info_panel.custom_minimum_size = Vector2(260.0, 160.0)
	unit_info_panel.offset_left = 18.0
	unit_info_panel.offset_top = 78.0
	unit_info_panel.offset_right = 278.0
	unit_info_panel.offset_bottom = 238.0
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color(0.06, 0.075, 0.095, 0.84)
	info_style.border_color = Color(0.48, 0.58, 0.72, 0.92)
	info_style.set_border_width_all(2)
	info_style.set_corner_radius_all(8)
	unit_info_panel.add_theme_stylebox_override("panel", info_style)
	ui_root.add_child(unit_info_panel)

	var info_margin := MarginContainer.new()
	info_margin.add_theme_constant_override("margin_left", 10)
	info_margin.add_theme_constant_override("margin_top", 8)
	info_margin.add_theme_constant_override("margin_right", 10)
	info_margin.add_theme_constant_override("margin_bottom", 8)
	unit_info_panel.add_child(info_margin)

	unit_info_label = Label.new()
	unit_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unit_info_label.text = ""
	info_margin.add_child(unit_info_label)

	start_panel = PanelContainer.new()
	start_panel.name = "StartPanel"
	start_panel.custom_minimum_size = Vector2(500.0, 250.0)
	start_panel.offset_left = 210.0
	start_panel.offset_top = 150.0
	start_panel.offset_right = 710.0
	start_panel.offset_bottom = 400.0
	var start_style := StyleBoxFlat.new()
	start_style.bg_color = Color(0.035, 0.045, 0.06, 0.94)
	start_style.border_color = Color(0.42, 0.64, 0.86, 1.0)
	start_style.set_border_width_all(3)
	start_style.set_corner_radius_all(8)
	start_panel.add_theme_stylebox_override("panel", start_style)
	ui_root.add_child(start_panel)

	var start_margin := MarginContainer.new()
	start_margin.add_theme_constant_override("margin_left", 20)
	start_margin.add_theme_constant_override("margin_top", 16)
	start_margin.add_theme_constant_override("margin_right", 20)
	start_margin.add_theme_constant_override("margin_bottom", 16)
	start_panel.add_child(start_margin)

	var start_box := VBoxContainer.new()
	start_box.add_theme_constant_override("separation", 12)
	start_margin.add_child(start_box)

	start_label = Label.new()
	start_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_label.text = ""
	start_box.add_child(start_label)

	start_button = Button.new()
	start_button.text = "Start Battle"
	start_button.custom_minimum_size = Vector2(180.0, 42.0)
	start_button.pressed.connect(_on_start_battle_pressed)
	start_box.add_child(start_button)

	result_panel = PanelContainer.new()
	result_panel.name = "ResultPanel"
	result_panel.visible = false
	result_panel.custom_minimum_size = Vector2(460.0, 270.0)
	result_panel.offset_left = 230.0
	result_panel.offset_top = 150.0
	result_panel.offset_right = 690.0
	result_panel.offset_bottom = 420.0
	var result_style := StyleBoxFlat.new()
	result_style.bg_color = Color(0.04, 0.045, 0.055, 0.92)
	result_style.border_color = Color(0.86, 0.68, 0.32, 1.0)
	result_style.set_border_width_all(3)
	result_style.set_corner_radius_all(8)
	result_panel.add_theme_stylebox_override("panel", result_style)
	ui_root.add_child(result_panel)

	var result_margin := MarginContainer.new()
	result_margin.add_theme_constant_override("margin_left", 18)
	result_margin.add_theme_constant_override("margin_top", 14)
	result_margin.add_theme_constant_override("margin_right", 18)
	result_margin.add_theme_constant_override("margin_bottom", 14)
	result_panel.add_child(result_margin)

	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 10)
	result_margin.add_child(result_box)

	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.text = ""
	result_box.add_child(result_label)

	var result_buttons := HBoxContainer.new()
	result_buttons.add_theme_constant_override("separation", 12)
	result_box.add_child(result_buttons)

	next_level_button = Button.new()
	next_level_button.text = "Next Level"
	next_level_button.custom_minimum_size = Vector2(140.0, 40.0)
	next_level_button.pressed.connect(_on_next_level_pressed)
	result_buttons.add_child(next_level_button)

	retry_button = Button.new()
	retry_button.text = "Retry"
	retry_button.custom_minimum_size = Vector2(120.0, 40.0)
	retry_button.pressed.connect(_on_retry_pressed)
	result_buttons.add_child(retry_button)


func _build_effect_layer() -> void:
	effect_root = Node2D.new()
	effect_root.name = "EffectLayer"
	board.add_child(effect_root)


# 根据窗口大小调整相机缩放。
# Godot 的 Camera2D.zoom 越大，看起来越放大；越小，看起来越缩小。
# 这里用棋盘尺寸和窗口尺寸算出一个合适的 zoom，保证全屏和小窗口都能看到完整棋盘。
func _fit_camera_to_viewport() -> void:
	if board == null or camera == null:
		return

	var viewport_size: Vector2 = Vector2(get_viewport_rect().size)
	var board_size: Vector2 = Vector2(board.grid_size * board.cell_size)
	var available_size: Vector2 = Vector2(
		max(viewport_size.x - CAMERA_MARGIN * 2.0, board.cell_size),
		max(viewport_size.y - UI_TOP_RESERVED - CAMERA_MARGIN * 2.0, board.cell_size)
	)
	var zoom_value: float = min(available_size.x / board_size.x, available_size.y / board_size.y)
	zoom_value = clamp(zoom_value, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)

	camera.zoom = Vector2(zoom_value, zoom_value)
	camera.position = board.position + board_size * 0.5 - Vector2(0.0, UI_TOP_RESERVED * 0.5 / zoom_value)


# 显示单位操作菜单，并根据技能冷却刷新按钮状态。
func _show_action_menu(unit: BattleUnit) -> void:
	move_button.text = "移动"
	attack_button.text = "攻击"
	defend_button.text = "防守"
	cancel_button.text = "取消"
	move_button.disabled = unit.has_moved
	attack_button.disabled = false
	defend_button.disabled = false

	var skill_key := _skill_key(unit)
	var skill_name := _skill_name(unit)
	if skill_key == "" or unit.skill_cooldown_remaining > 0:
		skill_button.disabled = true
		skill_button.text = "冷却:%d" % unit.skill_cooldown_remaining
	else:
		skill_button.disabled = false
		skill_button.text = "技能"

	if skill_key == "":
		skill_button.text = "Skill"
	elif unit.skill_cooldown_remaining > 0:
		skill_button.text = "CD %d" % unit.skill_cooldown_remaining
	else:
		skill_button.text = skill_name

	action_menu.visible = true
	_position_action_menu(unit)
	_show_info.call_deferred(_unit_summary(unit))
	_show_unit_info(unit)


# 把操作菜单放在单位附近，并限制在窗口范围内。
func _position_action_menu(unit: BattleUnit) -> void:
	var screen_position: Vector2 = get_viewport().get_canvas_transform() * unit.global_position
	var viewport_size: Vector2 = Vector2(get_viewport_rect().size)
	var menu_size := Vector2(124.0, 178.0)
	action_menu.position = Vector2(
		clamp(screen_position.x + 28.0, 12.0, max(12.0, viewport_size.x - menu_size.x - 12.0)),
		clamp(screen_position.y - 48.0, UI_TOP_RESERVED, max(UI_TOP_RESERVED, viewport_size.y - menu_size.y - 12.0))
	)


# 点击移动按钮：进入移动模式，并显示蓝色移动范围。
func _on_move_button_pressed() -> void:
	if selected_unit == null or selected_unit.has_acted or selected_unit.has_moved:
		return
	action_mode = ActionMode.MOVE
	reachable_cells = _find_reachable_cells(selected_unit)
	attackable_cells.clear()
	board.set_highlights(reachable_cells, attackable_cells)
	action_menu.visible = false
	_show_info("移动模式：点击蓝色格子移动。")


# 点击攻击按钮：切到普通攻击模式，只显示可攻击目标。
func _on_attack_button_pressed() -> void:
	if selected_unit == null or selected_unit.has_acted:
		return
	action_mode = ActionMode.ATTACK
	reachable_cells.clear()
	attackable_cells = _find_attack_cells(selected_unit.grid_position, selected_unit.attack_range, true)
	board.set_highlights(reachable_cells, attackable_cells)
	action_menu.visible = false
	_show_info("攻击模式：点击红色范围内的敌人。")


# 点击防守按钮：单位进入防守状态，受到的下一次伤害减半。
func _on_defend_button_pressed() -> void:
	if selected_unit == null or selected_unit.has_acted:
		return
	await _play_defend_animation(selected_unit)
	selected_unit.defend()
	_award_xp(selected_unit, 4, "guard")
	_show_info("%s 进入防守，下一次受到伤害减半。" % selected_unit.unit_name)
	_refresh_selection_after_action()


# 点击技能按钮：根据职业释放对应技能。
func _on_skill_button_pressed() -> void:
	if selected_unit == null or selected_unit.has_acted or selected_unit.skill_cooldown_remaining > 0:
		return
	action_mode = ActionMode.SKILL
	action_menu.visible = false
	_show_info("%s: %s" % [_skill_name(selected_unit), _skill_preview_text(selected_unit)])
	await _execute_skill(selected_unit)
	_refresh_selection_after_action()


# 点击取消按钮：取消当前单位选中，并关闭操作菜单。
func _on_cancel_button_pressed() -> void:
	_clear_selection()
	_show_info("已取消选择。")


func _on_start_battle_pressed() -> void:
	if phase != Phase.LEVEL_START:
		return
	start_panel.visible = false
	phase = Phase.PLAYER_TURN
	_show_info("Player turn. %s" % _mission_brief())
	_update_ui()


func _on_next_level_pressed() -> void:
	if phase != Phase.VICTORY:
		return
	if current_level_index + 1 >= LEVEL_CONFIGS.size():
		return
	_load_level(current_level_index + 1)


func _on_retry_pressed() -> void:
	_load_level(current_level_index)


# 返回单位职业对应的技能 key。
func _skill_key(unit: BattleUnit) -> String:
	var key := unit.unit_name.to_lower()
	return key if SKILL_COOLDOWNS.has(key) else ""


# 返回单位技能显示名。
func _skill_name(unit: BattleUnit) -> String:
	var key := _skill_key(unit)
	return String(SKILL_NAMES.get(key, "Skill"))


# 返回单位技能冷却回合数。
func _skill_cooldown(unit: BattleUnit) -> int:
	var key := _skill_key(unit)
	return int(SKILL_COOLDOWNS.get(key, 0))


# 执行当前单位的职业技能。
func _execute_skill(caster: BattleUnit) -> void:
	var key := _skill_key(caster)
	if key == "":
		return

	var cells := _skill_cells(caster, key)
	board.set_highlights([], cells)
	await _play_skill_animation(caster, cells, _skill_color(key))

	match key:
		"warrior":
			await _damage_units_in_cells(caster, cells, 1.2)
		"mage":
			await _damage_units_in_cells(caster, cells, 1.5)
		"ranger":
			await _damage_units_in_cells(caster, cells, 1.2)
		"cleric":
			await _heal_units_in_cells(caster, cells)

	caster.skill_cooldown_remaining = _skill_cooldown(caster)
	caster.has_acted = true
	_show_info("%s uses %s." % [caster.unit_name, _skill_name(caster)])


# 根据职业技能生成影响格子。
func _skill_cells(caster: BattleUnit, key: String) -> Array[Vector2i]:
	match key:
		"warrior":
			return _cells_in_square(caster.grid_position, 1)
		"mage":
			return _cells_in_front_box(caster.grid_position, _front_direction(caster), 3, 1)
		"ranger":
			return _cells_in_front_line(caster.grid_position, _front_direction(caster), 6)
		"cleric":
			return _cells_in_square(caster.grid_position, 1)
	return []


# 玩家默认面向右，敌方默认面向左。
func _front_direction(unit: BattleUnit) -> Vector2i:
	return Vector2i.RIGHT if unit.team == "player" else Vector2i.LEFT


# 获取以 center 为中心，半径为 radius 的方形区域。
func _cells_in_square(center: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(x, y)
			if board.is_inside(cell):
				cells.append(cell)
	return cells


# 获取前方 depth 格、左右 side_radius 格的矩形区域。
func _cells_in_front_box(origin: Vector2i, direction: Vector2i, depth: int, side_radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for step in range(1, depth + 1):
		for side in range(-side_radius, side_radius + 1):
			var cell := origin + direction * step + Vector2i(0, side)
			if board.is_inside(cell):
				cells.append(cell)
	return cells


# 获取前方直线 distance 格。
func _cells_in_front_line(origin: Vector2i, direction: Vector2i, distance: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for step in range(1, distance + 1):
		var cell := origin + direction * step
		if board.is_inside(cell):
			cells.append(cell)
	return cells


# 对范围内所有敌人造成倍率伤害。
func _damage_units_in_cells(caster: BattleUnit, cells: Array[Vector2i], multiplier: float) -> void:
	var targets := _units_in_cells(cells, _opposing_team(caster.team))
	var damage := maxi(1, roundi(float(caster.attack_power) * multiplier))
	for target in targets:
		await target.play_hit_animation()
		var defeated := target.take_damage(damage)
		_show_float_at_unit(target, "-%d" % target.last_damage_taken, Color("#ff6961"))
		_award_xp(caster, 6, "skill hit")
		if defeated:
			await target.play_defeat_animation()
			await target.play_death_animation()
			defeated_unit_names.append(target.unit_name)
			_award_xp(caster, 20, "skill defeat")
			_collect_drop(target)
			units.erase(target)
			target.queue_free()


# 对范围内所有友方回复 1/3 最大生命。
func _heal_units_in_cells(caster: BattleUnit, cells: Array[Vector2i]) -> void:
	var targets := _units_in_cells(cells, caster.team)
	var healing_xp := 0
	for target in targets:
		var heal_amount := maxi(1, ceili(float(target.max_hp) / 3.0))
		var healed := target.heal(heal_amount)
		if healed > 0:
			_show_float_at_unit(target, "+%d" % healed, Color("#6cff9a"))
			healing_xp = mini(18, healing_xp + 6)
		await _play_heal_animation(target)
	if healing_xp > 0:
		_award_xp(caster, healing_xp, "healing")


# 从格子列表里筛出指定阵营单位。
func _units_in_cells(cells: Array[Vector2i], team: String) -> Array[BattleUnit]:
	var result: Array[BattleUnit] = []
	for unit in units:
		if unit.team == team and cells.has(unit.grid_position):
			result.append(unit)
	return result


func _opposing_team(team: String) -> String:
	return "enemy" if team == "player" else "player"


func _skill_color(key: String) -> Color:
	match key:
		"warrior":
			return Color(1.0, 0.84, 0.28, 0.62)
		"mage":
			return Color(1.0, 0.25, 0.08, 0.68)
		"ranger":
			return Color(0.42, 1.0, 0.35, 0.62)
		"cleric":
			return Color(0.6, 1.0, 0.88, 0.65)
	return Color.WHITE


# 范围技能特效：角色蓄力，技能范围闪烁扩散。
func _play_skill_animation(caster: BattleUnit, cells: Array[Vector2i], color: Color) -> void:
	await caster.play_skill_animation()

	var original_scale := caster.sprite.scale
	var charge := create_tween()
	charge.tween_property(caster.sprite, "scale", original_scale * 1.22, 0.12)
	charge.tween_property(caster.sprite, "scale", original_scale, 0.12)
	await charge.finished

	var effects_root := Node2D.new()
	board.add_child(effects_root)
	for cell in cells:
		var poly := Polygon2D.new()
		var size := float(board.cell_size)
		poly.polygon = PackedVector2Array([
			Vector2.ZERO,
			Vector2(size, 0.0),
			Vector2(size, size),
			Vector2(0.0, size),
		])
		poly.position = Vector2(cell * board.cell_size)
		poly.color = color
		poly.scale = Vector2(0.25, 0.25)
		poly.position += Vector2(size, size) * 0.375
		effects_root.add_child(poly)

		var tween := create_tween()
		tween.tween_property(poly, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(poly, "position", Vector2(cell * board.cell_size), 0.12)
		tween.tween_property(poly, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.28)

	await get_tree().create_timer(0.45).timeout
	effects_root.queue_free()


# 治疗命中特效。
func _play_heal_animation(target: BattleUnit) -> void:
	var tween := create_tween()
	tween.tween_property(target.sprite, "modulate", Color(0.55, 1.0, 0.75, 1.0), 0.08)
	tween.parallel().tween_property(target.sprite, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(target.sprite, "modulate", Color.WHITE, 0.12)
	tween.parallel().tween_property(target.sprite, "scale", Vector2.ONE, 0.12)
	await tween.finished


# 防守特效。
func _play_defend_animation(unit: BattleUnit) -> void:
	_show_float_at_unit(unit, "Guard", Color("#85a9ff"))
	var tween := create_tween()
	tween.tween_property(unit.sprite, "modulate", Color(0.55, 0.72, 1.0, 1.0), 0.1)
	tween.parallel().tween_property(unit.sprite, "scale", Vector2(0.92, 1.08), 0.1)
	tween.tween_property(unit.sprite, "modulate", Color.WHITE, 0.14)
	tween.parallel().tween_property(unit.sprite, "scale", Vector2.ONE, 0.14)
	await tween.finished


# 处理单位被点击后的逻辑。
# 参数 unit 是被点击的单位，可能是己方，也可能是敌方。
func _on_unit_selected(unit: BattleUnit) -> void:
	if phase != Phase.PLAYER_TURN:
		return

	if unit.team == "player":
		if unit.has_acted:
			_show_info("%s has already acted." % unit.unit_name)
			_show_unit_info(unit)
			return
		_select_unit(unit)
		return

	if selected_unit != null and action_mode == ActionMode.ATTACK and attackable_cells.has(unit.grid_position):
		_show_info(_preview_attack_result(selected_unit, unit))
		_show_unit_info(unit)
		await _attack(selected_unit, unit)
		_refresh_selection_after_action()
		return

	if unit.team == "enemy":
		_show_unit_info(unit)
		_inspect_enemy_movement(unit)


# 选中一个玩家单位，并刷新它的移动范围和攻击范围。
# 参数 unit 必须是玩家单位，并且本回合还没有行动过。
func _select_unit(unit: BattleUnit) -> void:
	_clear_selection()
	selected_unit = unit
	selected_unit.set_selected(true)
	action_mode = ActionMode.MOVE
	reachable_cells.clear()
	attackable_cells.clear()
	board.set_highlights(reachable_cells, attackable_cells)
	_show_action_menu(unit)
	_show_info("已选择 %s：请从菜单选择行动。" % unit.unit_name)


# 玩家回合点击敌方单位时，预览它下回合可能的移动范围。
# 这不会消耗行动，也不会选中敌人。
func _inspect_enemy_movement(unit: BattleUnit) -> void:
	_clear_selection()
	_show_unit_info(unit)
	reachable_cells = _find_reachable_cells(unit, false)
	attackable_cells.clear()
	board.set_highlights(reachable_cells, attackable_cells)
	_show_info("正在查看 %s 的下回合移动范围。" % unit.unit_name)


# 清除当前选中单位和棋盘高亮。
# 点击棋盘外、结束回合、单位行动完成时都会调用。
func _clear_selection() -> void:
	if selected_unit != null:
		selected_unit.set_selected(false)
	selected_unit = null
	action_mode = ActionMode.MOVE
	reachable_cells.clear()
	attackable_cells.clear()
	board.clear_highlights()
	action_menu.visible = false
	_show_unit_info(null)


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
func _move_unit(unit: BattleUnit, target_cell: Vector2i, show_player_prompt := true) -> void:
	unit.grid_position = target_cell
	unit.has_moved = true
	unit.play_move_animation(0.18)
	var tween := create_tween()
	tween.tween_property(unit, "position", Vector2(target_cell) * board.cell_size + Vector2(board.cell_size, board.cell_size) * 0.5, 0.18).set_trans(Tween.TRANS_SINE)
	await tween.finished
	if show_player_prompt:
		attackable_cells = _find_attack_cells(unit.grid_position, unit.attack_range, true)
		board.set_highlights([], attackable_cells)
		_show_info("%s moved. %s" % [unit.unit_name, _attack_preview_text(unit)])


# 执行一次普通攻击。
# 参数 attacker 是攻击者；defender 是受击者。
# 当前规则：攻击后攻击者本回合行动结束；目标血量为 0 时从战场移除。
func _attack(attacker: BattleUnit, defender: BattleUnit) -> int:
	await attacker.play_attack_animation(defender.position)
	var defender_defeated := defender.take_damage(attacker.attack_power)
	attacker.has_acted = true
	var damage_dealt := defender.last_damage_taken
	_show_float_at_unit(defender, "-%d" % damage_dealt, Color("#ff6961"))
	_show_info("%s attacks %s for %d damage." % [attacker.unit_name, defender.unit_name, attacker.attack_power])
	_award_xp(attacker, 8, "hit")

	if defender_defeated:
		await defender.play_hit_animation()
		await defender.play_defeat_animation()
		await defender.play_death_animation()
		defeated_unit_names.append(defender.unit_name)
		_award_xp(attacker, 20, "defeat")
		_collect_drop(defender)
		units.erase(defender)
		defender.queue_free()
	else:
		await defender.play_hit_animation()
	return damage_dealt


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

		var target := _choose_enemy_target(enemy)
		if target == null:
			break
		_show_info("%s targets %s." % [enemy.unit_name, target.unit_name])
		await get_tree().create_timer(0.2).timeout

		if _distance(enemy.grid_position, target.grid_position) <= enemy.attack_range:
			var damage := await _attack(enemy, target)
			await _after_enemy_attack(enemy, damage)
			_check_battle_end()
			await get_tree().create_timer(0.25).timeout
			continue

		var next_cell := _best_enemy_move(enemy, target.grid_position)
		if next_cell != enemy.grid_position:
			await _move_unit(enemy, next_cell, false)

		if is_instance_valid(target) and _distance(enemy.grid_position, target.grid_position) <= enemy.attack_range:
			var damage := await _attack(enemy, target)
			await _after_enemy_attack(enemy, damage)

		_check_battle_end()
		await get_tree().create_timer(0.25).timeout


# 开始新的玩家回合。
# 重置所有玩家单位的移动和行动状态，然后刷新 UI。
func _start_player_turn() -> void:
	current_turn += 1
	for unit in units:
		if unit.team == "player":
			unit.tick_skill_cooldown()
			unit.reset_turn()
	phase = Phase.PLAYER_TURN
	if current_turn > _max_turns():
		phase = Phase.DEFEAT
		battle_result_reason = "Turn limit exceeded."
		_clear_selection()
		_show_info(_battle_summary())
		_show_result_panel()
	else:
		_show_info("Player turn. %s" % _mission_brief())
	_update_ui()


# 检查战斗是否结束。
# 如果敌人全灭就是胜利；如果玩家单位全灭就是失败。
func _check_battle_end() -> void:
	var player_count := units.filter(func(unit: BattleUnit) -> bool: return unit.team == "player").size()
	var enemy_count := units.filter(func(unit: BattleUnit) -> bool: return unit.team == "enemy").size()

	if enemy_count == 0:
		phase = Phase.VICTORY
		battle_result_reason = "All enemies defeated."
		_clear_selection()
		_show_info(_battle_summary())
		_show_result_panel()
	elif player_count == 0:
		phase = Phase.DEFEAT
		battle_result_reason = "All player units are down."
		_clear_selection()
		_show_info(_battle_summary())
		_show_result_panel()
	elif not _protected_unit_alive():
		phase = Phase.DEFEAT
		battle_result_reason = "%s was defeated." % _protected_unit_name()
		_clear_selection()
		_show_info(_battle_summary())
		_show_result_panel()

	_update_ui()


# 计算单位当前能移动到哪些格子。
# 返回值是格子坐标数组，不包含起点、不包含障碍格、不包含已有单位的格子。
func _find_reachable_cells(unit: BattleUnit, respect_moved := true) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if respect_moved and unit.has_moved:
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
	var best_score := 9999
	var desired_range := enemy.attack_range

	for cell in candidates:
		var distance := _distance(cell, target_cell)
		var score := absi(distance - desired_range)
		if distance > enemy.attack_range:
			score += distance
		if enemy.unit_name.to_lower() == "necromancer" and distance <= 1:
			score += 6
		if score < best_score:
			best_score = score
			best_cell = cell

	return best_cell


func _choose_enemy_target(enemy: BattleUnit) -> BattleUnit:
	var candidates: Array[BattleUnit] = []
	for unit in units:
		if unit.team == "player":
			candidates.append(unit)
	if candidates.is_empty():
		return null

	var enemy_key := enemy.unit_name.to_lower()
	var best_target: BattleUnit = null
	var best_score := 999999.0
	for candidate in candidates:
		var distance := float(_distance(enemy.grid_position, candidate.grid_position))
		var hp_ratio := float(candidate.hp) / float(candidate.max_hp)
		var score := distance * 10.0 + hp_ratio * 20.0
		match enemy_key:
			"goblin":
				score = float(candidate.hp) * 4.0 + distance
				if distance <= float(enemy.attack_range):
					score -= 20.0
			"werewolf":
				score = distance * 7.0 + hp_ratio * 28.0
			"necromancer":
				score = distance * 6.0 + hp_ratio * 12.0
				if candidate.unit_name == "Cleric" or candidate.unit_name == "Mage":
					score -= 25.0
			"vampire":
				score = distance * 8.0 - float(candidate.hp)
		if best_target == null or score < best_score:
			best_target = candidate
			best_score = score
	return best_target


func _after_enemy_attack(enemy: BattleUnit, damage_dealt: int) -> void:
	if enemy.unit_name.to_lower() != "vampire" or damage_dealt <= 0 or not is_instance_valid(enemy):
		return
	var healed := enemy.heal(maxi(1, ceili(float(damage_dealt) * 0.5)))
	if healed > 0:
		_show_float_at_unit(enemy, "+%d" % healed, Color("#d274ff"))
		await _play_heal_animation(enemy)


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


func _show_unit_info(unit: BattleUnit) -> void:
	if unit_info_label == null:
		return
	if unit == null or not is_instance_valid(unit):
		unit_info_label.text = "%s\n\n%s\n\nInventory: %s\n\nSelect a unit to view stats." % [
			_level_name(),
			_mission_brief(),
			_inventory_summary(),
		]
		return
	var skill_line := _skill_preview_text(unit) if _skill_key(unit) != "" else "No skill"
	unit_info_label.text = "%s\n%s\n\nLv %d  XP: %s\nHP: %d / %d\nATK: %d   MOV: %d   RNG: %d\nEquip: %s\nStatus: %s\nSkill: %s" % [
		"ALLY" if unit.team == "player" else "ENEMY",
		unit.unit_name,
		unit.level,
		_xp_display(unit),
		unit.hp,
		unit.max_hp,
		unit.attack_power,
		unit.move_range,
		unit.attack_range,
		unit.get_equipment_summary(),
		_unit_status(unit),
		skill_line,
	]


func _show_result_panel() -> void:
	if result_panel == null or result_label == null:
		return
	result_panel.visible = true
	if start_panel != null:
		start_panel.visible = false
	next_level_button.visible = phase == Phase.VICTORY and current_level_index + 1 < LEVEL_CONFIGS.size()
	retry_button.visible = true
	result_label.text = "%s\n\n%s\n\nGrade: %s\nTurns: %d / %d\nSurvivors: %d\nDefeated: %s\nRewards: %s\nGrowth: %s\nInventory: %s" % [
		"VICTORY" if phase == Phase.VICTORY else "DEFEAT",
		battle_result_reason,
		_result_grade(),
		current_turn,
		_max_turns(),
		units.filter(func(unit: BattleUnit) -> bool: return unit.team == "player").size(),
		"none" if defeated_unit_names.is_empty() else ", ".join(defeated_unit_names),
		"none" if pending_rewards.is_empty() else "\n- " + "\n- ".join(pending_rewards),
		"none" if level_progress_summary.is_empty() else "\n- " + "\n- ".join(level_progress_summary),
		_inventory_summary(),
	]


func _hide_result_panel() -> void:
	if result_panel != null:
		result_panel.visible = false


# 根据当前 phase 刷新回合文字和结束回合按钮状态。
func _update_ui() -> void:
	match phase:
		Phase.LEVEL_START:
			turn_label.text = "Level %d/%d - Briefing" % [current_level_index + 1, LEVEL_CONFIGS.size()]
			end_turn_button.disabled = true
		Phase.PLAYER_TURN:
			turn_label.text = "Turn %d/%d - Player" % [current_turn, _max_turns()]
			end_turn_button.disabled = false
		Phase.ENEMY_TURN:
			turn_label.text = "Turn %d/%d - Enemy" % [current_turn, _max_turns()]
			end_turn_button.disabled = true
		Phase.VICTORY:
			turn_label.text = "Victory"
			end_turn_button.disabled = true
		Phase.DEFEAT:
			turn_label.text = "Defeat"
			end_turn_button.disabled = true


func _mission_brief() -> String:
	return "Objective: %s Defeat all enemies in %d turns. Protect %s." % [
		String(_current_level().get("objective", "Clear the battlefield.")),
		_max_turns(),
		_protected_unit_name(),
	]


func _unit_summary(unit: BattleUnit) -> String:
	var team_name := "Ally" if unit.team == "player" else "Enemy"
	var skill_text := _skill_name(unit) if _skill_key(unit) != "" else "No skill"
	return "%s %s | HP %d/%d | ATK %d | MOV %d | RNG %d | %s | %s" % [
		team_name,
		unit.unit_name,
		unit.hp,
		unit.max_hp,
		unit.attack_power,
		unit.move_range,
		unit.attack_range,
		skill_text,
		_unit_status(unit),
	]


func _preview_attack_result(attacker: BattleUnit, defender: BattleUnit) -> String:
	var damage := _preview_damage(attacker, defender)
	var remaining := maxi(0, defender.hp - damage)
	var kill_text := " Kill confirmed." if remaining == 0 else ""
	return "%s -> %s | %d damage | HP %d -> %d.%s" % [
		attacker.unit_name,
		defender.unit_name,
		damage,
		defender.hp,
		remaining,
		kill_text,
	]


func _preview_damage(attacker: BattleUnit, defender: BattleUnit) -> int:
	var damage := attacker.attack_power
	if defender.is_defending:
		damage = ceili(float(damage) * 0.5)
	return maxi(1, damage)


func _unit_status(unit: BattleUnit) -> String:
	if unit.hp <= 0:
		return "Down"
	if unit.is_defending:
		return "Guarding"
	if unit.has_acted:
		return "Acted"
	if unit.has_moved:
		return "Moved"
	if unit.skill_cooldown_remaining > 0:
		return "CD %d" % unit.skill_cooldown_remaining
	return "Ready"


func _attack_preview_text(unit: BattleUnit) -> String:
	return "Damage %d, range %d. Choose a red target." % [unit.attack_power, unit.attack_range]


func _skill_preview_text(unit: BattleUnit) -> String:
	var key := _skill_key(unit)
	match key:
		"warrior":
			return "3x3 sweep, %d damage, CD %d." % [maxi(1, roundi(float(unit.attack_power) * 1.2)), _skill_cooldown(unit)]
		"mage":
			return "front area, %d damage, CD %d." % [maxi(1, roundi(float(unit.attack_power) * 1.5)), _skill_cooldown(unit)]
		"ranger":
			return "line shot, %d damage, CD %d." % [maxi(1, roundi(float(unit.attack_power) * 1.2)), _skill_cooldown(unit)]
		"cleric":
			return "heal allies in 3x3, CD %d." % _skill_cooldown(unit)
	return "No skill."


func _protected_unit_alive() -> bool:
	for unit in units:
		if unit.team == "player" and unit.unit_name == _protected_unit_name() and unit.hp > 0:
			return true
	return false


func _battle_summary() -> String:
	var surviving_players := units.filter(func(unit: BattleUnit) -> bool: return unit.team == "player").size()
	var defeated_text := "none" if defeated_unit_names.is_empty() else ", ".join(defeated_unit_names)
	return "%s | Turns %d/%d | Survivors %d | Defeated: %s" % [
		battle_result_reason,
		current_turn,
		_max_turns(),
		surviving_players,
		defeated_text,
	]


func _result_grade() -> String:
	if phase != Phase.VICTORY:
		return "C"
	var player_losses := 0
	for name in defeated_unit_names:
		for data in _current_unit_data():
			if String(data.get("name", "")) == name and String(data.get("team", "")) == "player":
				player_losses += 1
	if current_turn <= 6 and player_losses == 0:
		return "S"
	if player_losses == 0:
		return "A"
	return "B"


func _current_level() -> Dictionary:
	return LEVEL_CONFIGS[current_level_index]


func _current_unit_data() -> Array:
	return _current_level().get("units", [])


func _level_name() -> String:
	return String(_current_level().get("name", "Untitled Level"))


func _max_turns() -> int:
	return int(_current_level().get("max_turns", 8))


func _protected_unit_name() -> String:
	return String(_current_level().get("protected_unit", "Cleric"))


func _show_start_panel() -> void:
	if start_panel == null or start_label == null:
		return
	start_panel.visible = true
	start_label.text = "Level %d - %s\n\n%s\n\nParty\n%s\n\nEquipment\n%s" % [
		current_level_index + 1,
		_level_name(),
		_mission_brief(),
		_party_summary(),
		_inventory_summary(),
	]


func _party_summary() -> String:
	var lines: Array[String] = []
	for unit in units:
		if unit.team == "player":
			lines.append("%s HP %d/%d ATK %d MOV %d RNG %d | %s" % [
				unit.unit_name,
				unit.hp,
				unit.max_hp,
				unit.attack_power,
				unit.move_range,
				unit.attack_range,
				unit.get_equipment_summary(),
			])
	return "\n".join(lines)


func _inventory_summary() -> String:
	if party_inventory.is_empty():
		return "empty"
	var lines: Array[String] = []
	for item in party_inventory:
		var equipped_to := String(item.get("equipped_to", ""))
		var suffix := "" if equipped_to == "" else " -> " + equipped_to
		lines.append("%s%s" % [String(item.get("name", "Unknown")), suffix])
	return ", ".join(lines)


func _xp_display(unit: BattleUnit) -> String:
	if unit.level >= unit.max_level:
		return "MAX"
	return "%d/%d" % [unit.xp, unit.xp_to_next_level]


func _award_xp(unit: BattleUnit, amount: int, reason: String) -> void:
	if unit == null or not is_instance_valid(unit) or unit.team != "player":
		return
	var gained_levels := unit.gain_xp(amount)
	_show_float_at_unit(unit, "+%d XP" % amount, Color("#9fd3ff"))
	for new_level in gained_levels:
		var text := "%s reached Lv %d via %s." % [unit.unit_name, new_level, reason]
		level_progress_summary.append(text)
		_show_float_at_unit(unit, "Level Up!", Color("#ffe082"))
	_show_unit_info(unit)


func _collect_drop(defeated_unit: BattleUnit) -> void:
	if defeated_unit == null or not is_instance_valid(defeated_unit):
		return
	var drop_id := String(enemy_drop_by_name.get(defeated_unit.unit_name, ""))
	if drop_id == "" or not EQUIPMENT_POOL.has(drop_id):
		return
	var item := (EQUIPMENT_POOL[drop_id] as Dictionary).duplicate(true)
	party_inventory.append(item)
	var equip_note := _try_auto_equip_drop(item)
	var reward_line := "%s dropped %s" % [defeated_unit.unit_name, String(item.get("name", "Unknown"))]
	if equip_note != "":
		reward_line += " (%s)" % equip_note
	pending_rewards.append(reward_line)


func _try_auto_equip_drop(item: Dictionary) -> String:
	var preferred_unit := String(item.get("preferred_unit", ""))
	var target := _find_player_unit_by_name(preferred_unit)
	if target == null or not target.equipped_item.is_empty():
		return "sent to inventory"
	item["equipped_to"] = target.unit_name
	target.equip_item(item)
	_show_float_at_unit(target, "Equip: %s" % String(item.get("name", "Gear")), Color("#f4d06f"))
	return "equipped to %s" % target.unit_name


func _equipped_item_for_unit(unit_name: String) -> Dictionary:
	for item in party_inventory:
		if String(item.get("equipped_to", "")) == unit_name:
			return item
	return {}


func _find_player_unit_by_name(unit_name: String) -> BattleUnit:
	for unit in units:
		if unit.team == "player" and unit.unit_name == unit_name and unit.hp > 0:
			return unit
	return null


func _show_float_at_unit(unit: BattleUnit, text: String, color: Color) -> void:
	if not is_instance_valid(unit):
		return
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.position = unit.position + Vector2(-18.0, -44.0)
	label.add_theme_font_size_override("font_size", 18)
	if effect_root != null:
		effect_root.add_child(label)
	else:
		board.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0.0, -24.0), 0.55)
	tween.parallel().tween_property(label, "modulate", Color(color.r, color.g, color.b, 0.0), 0.55)
	tween.tween_callback(Callable(label, "queue_free"))
