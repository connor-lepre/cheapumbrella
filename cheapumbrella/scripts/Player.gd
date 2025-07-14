extends CharacterBody2D

const MOVE_SPEED := 600.0
const JUMP_VELOCITY := -1600.0
const GRAVITY := 4800.0
const GLIDE_FACTOR := 0.6
const BOOST_POWER := 1200.0
const BOOST_DURATION := 0.25

var is_gliding := false
var player_velocity: Vector2
var has_boosted := false
var boost_timer: float = 0.0
 

var _facing := 1

var _aiming := false
var _aim_direction: Vector2 = Vector2.RIGHT

@onready var _umbrella: Sprite2D = $UmbrellaSprite
@onready var _spawn_point: Node2D = get_parent().get_node_or_null("PlayerSpawn")
@onready var _game_manager: Node = get_parent()
@onready var _path_visualizer: Node2D = get_parent().get_node_or_null("CopiesRoot/PathVisualizer")


func _ready() -> void:
	
	if _umbrella:
		_umbrella.visible = false
	else:
		push_warning("UmbrellaSprite node missing")
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


func _handle_copy_actions(delta: float) -> void:
	if Input.is_action_just_pressed("copy_start") and not _aiming:
		_aiming = true
		_aim_direction = Vector2(_facing, 0)
		if _path_visualizer:
			_path_visualizer.show()
		_update_aim_visual()

	if _aiming:
		var dir = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
		)
		if dir.length() > 0.1:
			_aim_direction = _quantize_direction(dir)
		_update_aim_visual()

	if Input.is_action_just_pressed("copy_stop") and _aiming:
		if _game_manager and _game_manager.has_method("spawn_player_copy"):
			var spawn_pos = global_position + Vector2(0, -32)
			_game_manager.spawn_player_copy(spawn_pos, _aim_direction)
		else:
			push_warning("Cannot spawn player copy - manager missing or invalid")
		_aiming = false
		if _path_visualizer:
			_path_visualizer.hide()

func _quantize_direction(dir: Vector2) -> Vector2:
	var angle = dir.angle()
	var step = PI / 4.0
	var idx = round(angle / step)
	var new_angle = idx * step
	return Vector2.RIGHT.rotated(new_angle).normalized()

func _update_aim_visual() -> void:
	if _path_visualizer and _aiming:
		var start = global_position
		var end = start + _aim_direction.normalized() * 64.0
		var points: Array[Vector2] = [start, end]
		_path_visualizer.set_points(points)

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
