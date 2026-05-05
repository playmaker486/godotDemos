# 单位脚本，挂在 scenes/unit.tscn 的 Unit 节点上。
# Unit 是 Area2D，所以它可以接收鼠标点击事件。
class_name BattleUnit
extends Area2D

# 当玩家点击这个单位时发出。
# Game 脚本会监听这个信号，然后决定是选中己方单位还是攻击敌方单位。
signal selected(unit: BattleUnit)

# 真正显示角色图片的节点。
# 它会播放 assets/generated/unit_frames 中的真实逐帧 PNG 动画。
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

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

# 技能当前剩余冷却回合数。
# 为 0 时可以释放技能；释放后由 Game 脚本设置成职业对应冷却。
var skill_cooldown_remaining := 0

# 当前生命值。
# setup() 会把它初始化为 max_hp。
var hp := max_hp

# 本回合是否已经移动过。
# 用来防止单位在同一回合无限移动。
var has_moved := false

# 本回合是否已经完成行动。
# 当前规则里，攻击后就算完成行动。
var has_acted := false

# 是否处于防守状态。
# 防守会消耗行动，并让下一次受到的伤害减半。
var is_defending := false

# 棋盘格子的像素大小。
# 单位需要知道它，才能把格子坐标转换为节点位置。
var cell_size := 64

# 是否正被玩家选中。
# 只影响占位绘制的黄色外圈，不影响战斗逻辑。
var is_selected := false

# 鼠标是否悬停在单位上。
# 只影响占位绘制的白色外圈，不影响战斗逻辑。
var is_hovered := false

# 角色图片的基础偏移。
# 有些素材因为武器、弓、盾会让透明外框不居中，所以这里保存修正后的默认位置。
var sprite_base_position := Vector2.ZERO

# 当前是否处于非待机动画中。
var is_playing_action_animation := false


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
	_apply_sprite_frames()
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
	is_defending = false
	_play_idle_animation()
	queue_redraw()


# 让单位受到伤害。
# 参数 amount 是伤害值；返回 true 表示单位血量已经归零。
func take_damage(amount: int) -> bool:
	var final_amount := amount
	if is_defending:
		final_amount = ceili(float(amount) * 0.5)
		is_defending = false
	hp = max(hp - final_amount, 0)
	queue_redraw()
	return hp == 0


# 回复生命值。
# 参数 amount 是治疗量；返回实际回复了多少点生命。
func heal(amount: int) -> int:
	var old_hp := hp
	hp = min(hp + amount, max_hp)
	queue_redraw()
	return hp - old_hp


# 进入防守状态并消耗本回合行动。
func defend() -> void:
	is_defending = true
	has_acted = true
	queue_redraw()


# 玩家新回合开始时减少技能冷却。
func tick_skill_cooldown() -> void:
	if skill_cooldown_remaining > 0:
		skill_cooldown_remaining -= 1


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


# 根据单位名字加载生成好的逐帧动画。
# 名字来自 game.gd 的 unit_data，所以新增角色时要同时补这里的匹配或生成同名目录。
func _apply_sprite_frames() -> void:
	sprite.position = Vector2.ZERO
	match unit_name.to_lower():
		"warrior":
			pass
		"mage":
			sprite.position = Vector2(-6.0, 0.0)
		"ranger":
			sprite.position = Vector2(6.0, -1.0)
		"cleric":
			pass
		"werewolf":
			pass
		"goblin":
			sprite.position = Vector2(-3.0, -5.0)
		"necromancer":
			pass
		"vampire":
			pass
		_:
			pass
	sprite_base_position = sprite.position
	sprite.sprite_frames = _build_sprite_frames(unit_name.to_lower())
	_play_idle_animation()


# 从 PNG 帧文件构建 SpriteFrames。
# 文件路径格式：assets/generated/unit_frames/<unit>/<animation>_<index>.png
func _build_sprite_frames(unit_key: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	for animation_name in frames.get_animation_names():
		frames.remove_animation(animation_name)

	_add_animation_frames(frames, unit_key, "idle", 4, 6.0, true)
	_add_animation_frames(frames, unit_key, "move", 4, 10.0, true)
	_add_animation_frames(frames, unit_key, "attack", 4, 12.0, false)
	_add_animation_frames(frames, unit_key, "hit", 3, 14.0, false)
	_add_animation_frames(frames, unit_key, "defeat", 4, 10.0, false)
	_add_animation_frames(frames, unit_key, "death", 4, 10.0, false)
	return frames


func _add_animation_frames(frames: SpriteFrames, unit_key: String, animation_name: String, frame_count: int, fps: float, loops: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loops)
	for index in range(frame_count):
		var texture := load("res://assets/generated/unit_frames/%s/%s_%d.png" % [unit_key, animation_name, index]) as Texture2D
		frames.add_frame(animation_name, texture)


func _play_idle_animation() -> void:
	is_playing_action_animation = false
	sprite.position = sprite_base_position
	sprite.scale = Vector2.ONE
	sprite.rotation = 0.0
	sprite.modulate = Color.WHITE
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


# 播放移动动画。
# duration 是移动持续时间，Game 脚本会同时移动 Unit 节点本身；这里负责让 Sprite2D 上下跳动，做出走路帧感。
func play_move_animation(duration: float) -> void:
	is_playing_action_animation = true
	sprite.play("move")
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(_play_idle_animation)


# 播放攻击动画。
# target_position 是目标单位在同一个父节点下的位置，用它计算攻击方向。
func play_attack_animation(target_position: Vector2) -> void:
	is_playing_action_animation = true
	sprite.play("attack")
	await sprite.animation_finished
	_play_idle_animation()


# 播放受击动画。
# 目前用红色闪烁和轻微抖动表现，后续可以换成真正的受击帧图。
func play_hit_animation() -> void:
	is_playing_action_animation = true
	sprite.play("hit")
	await sprite.animation_finished
	_play_idle_animation()


# 播放击败动画。
# 这个动画表示单位已经被打倒，但还没有从场景树移除。
func play_defeat_animation() -> void:
	is_playing_action_animation = true
	sprite.play("defeat")
	await sprite.animation_finished


# 播放死亡动画。
# 动画结束后 Game 脚本会 queue_free() 移除这个单位。
func play_death_animation() -> void:
	is_playing_action_animation = true
	sprite.play("death")
	await sprite.animation_finished


# 绘制单位占位美术。
# 现在角色本体已经改为 Sprite2D，这里只保留选中圈、悬停圈和血条。
func _draw() -> void:
	var radius := cell_size * 0.32
	var ring_color := Color("#f4e38b") if is_selected else Color("#1f2630")
	if has_acted:
		ring_color = ring_color.darkened(0.35)

	draw_circle(Vector2(0.0, 8.0), radius * 0.85, Color(0.0, 0.0, 0.0, 0.28))
	draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 48, ring_color, 3.0)

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
