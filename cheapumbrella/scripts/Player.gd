extends CharacterBody2D

const MOVE_SPEED := 600.0
const JUMP_VELOCITY := -1600.0
const GRAVITY := 4800.0
const GLIDE_FACTOR := 0.6
const BOOST_POWER := 2400.0
const BOOST_DURATION := 0.25

var is_gliding := false
var player_velocity: Vector2
var has_boosted := false
var boost_timer: float = 0.0

var game_mgr = GameManager

var copy_types: Dictionary = preload("res://data/copy_types.gd").copy_types
var _copy_keys: Array
var _selected_copy_idx: int = 0

var _ghost: Node2D
var _last_side: int = 1
var _player_half_width: float = 16.0

var _copy_bar: Control
var _copy_type_label: Label

var _facing := 1

var _aiming := false # unused placeholder

@onready var _umbrella: Sprite2D = $UmbrellaSprite
@onready var _spawn_point: Node2D = get_parent().get_node_or_null("PlayerSpawn")
@onready var _game_manager: Node = get_parent()
@onready var _path_visualizer: Node2D = get_parent().get_node_or_null("CopiesRoot/PathVisualizer")


func _ready() -> void:
	
	if _umbrella:
		_umbrella.visible = false
	else:
		push_warning("UmbrellaSprite node missing")
	game_mgr.remaining_copy_energy = game_mgr.max_copy_energy
	_copy_keys = copy_types.keys()

	if has_node("CopyBar"):
		_copy_bar = $CopyBar
	if has_node("CopyTypeLabel"):
		_copy_type_label = $CopyTypeLabel
	add_to_group("Player")
	collision_layer = 1
	collision_mask = 6

	if _spawn_point == null:
		push_warning("PlayerSpawn node not found")

	if _game_manager == null:
		push_warning("GameManager node not found")

	if _path_visualizer == null:
		push_warning("PathVisualizer node not found")
	else:
		_path_visualizer.hide()

	_update_copy_bar()
	_update_copy_label()


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_copy_actions(delta)
	
	# Handle boost timer
	if boost_timer > 0.0:
		player_velocity.x = _facing * BOOST_POWER
		boost_timer -= delta
	else:
			# Boost finished, allow normal movement code to set velocity.x
		pass

		# Handle boost input
	if Input.is_action_just_pressed("boost"):
		if not has_boosted:
			_boost()

		# Reset boost when landing
	if is_on_floor():
		has_boosted = false

func _handle_movement(delta: float) -> void:
	var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if boost_timer <= 0.0:
		player_velocity.x = direction * MOVE_SPEED
		if direction != 0:
			_facing = sign(direction)

	# 1. JUMP (ground only)
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			player_velocity.y = JUMP_VELOCITY
		else:
			player_velocity.y = 0
		_end_glide()
		has_boosted = false

	# 2. GLIDE (air only)
	elif not is_on_floor():
		if Input.is_action_just_pressed("jump"):
			if not is_gliding:
				_start_glide()
			else:
				_end_glide()

	# 3. GRAVITY (always, except when just jumped)
	if not is_on_floor():
		player_velocity.y += GRAVITY * delta

	# 4. APPLY GLIDE (if gliding and falling)
	if is_gliding and player_velocity.y > 0.0:
		player_velocity.y *= GLIDE_FACTOR

	self.velocity = player_velocity
	move_and_slide()
	_check_crush()


func _boost() -> void:
	boost_timer = BOOST_DURATION
	player_velocity.x = _facing * BOOST_POWER
	has_boosted = true

func _start_glide() -> void:
	if not is_gliding:
		is_gliding = true
		if _umbrella:
			_umbrella.visible = true
		else:
			push_warning("Missing umbrella sprite when starting glide")


func _end_glide() -> void:
	if is_gliding:
		is_gliding = false
		if _umbrella:
			_umbrella.visible = false
		else:
			push_warning("Missing umbrella sprite when ending glide")


func _handle_copy_actions(_delta: float) -> void:
	if Input.is_action_just_pressed("next_copy"):
		_selected_copy_idx = (_selected_copy_idx + 1) % _copy_keys.size()
		_update_copy_label()
	elif Input.is_action_just_pressed("prev_copy"):
		_selected_copy_idx = (_selected_copy_idx - 1 + _copy_keys.size()) % _copy_keys.size()
		_update_copy_label()

	if Input.is_action_pressed("aim_left"):
		_last_side = -1
	elif Input.is_action_pressed("aim_right"):
		_last_side = 1

	if Input.is_action_just_pressed("copy_start"):
		_spawn_ghost()

	if _ghost:
		_update_ghost_position()

	if Input.is_action_just_pressed("copy_stop"):
		if _ghost:
			_place_copy()


func respawn() -> void:
	if _spawn_point:
		global_position = _spawn_point.global_position
		velocity = Vector2.ZERO
		_end_glide()
	else:
		push_warning("No spawn point for respawn")

func _check_crush() -> void:
	var copy_above := false
	var copy_below := false
	var env_above := false
	var env_below := false
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var body = col.get_collider()
		if body == null:
			continue
		if body.is_in_group("Copy"):
			if col.get_normal().y > 0:
				copy_above = true
			elif col.get_normal().y < 0:
				copy_below = true
		elif body.is_in_group("Environment"):
			if col.get_normal().y > 0:
				env_above = true
			elif col.get_normal().y < 0:
				env_below = true
				if (copy_above and env_below) or (copy_below and env_above):
					respawn()

func _update_copy_bar() -> void:
	if _copy_bar == null:
		return
	var bg = _copy_bar.get_node_or_null("CopyTimeBar")
	var fill = _copy_bar.get_node_or_null("RemainingTimeBar")
	if bg and fill:
		var ratio: float = 0.0
		if game_mgr.max_copy_energy > 0:
			ratio = float(game_mgr.remaining_copy_energy) / float(game_mgr.max_copy_energy)
		fill.size.x = bg.size.x * ratio

func _update_copy_label() -> void:
	if _copy_type_label == null:
		return
	if _copy_keys.size() == 0:
		_copy_type_label.text = ""
	else:
		_copy_type_label.text = _copy_keys[_selected_copy_idx]

func _spawn_ghost() -> void:
	if _ghost:
		_ghost.queue_free()
	_ghost = preload("res://scripts/GhostPreview.gd").new()
	var dims: Vector2 = copy_types[_copy_keys[_selected_copy_idx]].dimensions
	_ghost.size = dims
	get_parent().add_child(_ghost)
	_update_ghost_position()

func _update_ghost_position() -> void:
	if _ghost == null:
		return
	var dims: Vector2 = copy_types[_copy_keys[_selected_copy_idx]].dimensions
	var side = _last_side
	var offset_x = side * (_player_half_width + dims.x * 0.5 + 32.0)
	_ghost.global_position = Vector2(global_position.x + offset_x, global_position.y)

func _place_copy() -> void:
	var type_name = _copy_keys[_selected_copy_idx]
	var data = copy_types[type_name]
	var cost: int = data.get("copy cost", 1)
	if game_mgr.remaining_copy_energy < cost:
		push_warning("Not enough energy")
		_ghost.queue_free()
		_ghost = null
		return
	if _game_manager and _game_manager.has_method("spawn_copy"):
		var copy = _game_manager.spawn_copy(type_name, _ghost.global_position)
		if copy:
			game_mgr.remaining_copy_energy -= cost
			_update_copy_bar()
			if copy.has_signal("copy_removed"):
				copy.copy_removed.connect(_on_copy_removed)
	_ghost.queue_free()
	_ghost = null

func _on_copy_removed(cost: int) -> void:
	game_mgr.remaining_copy_energy = min(game_mgr.remaining_copy_energy + cost, game_mgr.max_copy_energy)
	_update_copy_bar()
