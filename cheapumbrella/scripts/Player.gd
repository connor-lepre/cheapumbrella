extends CharacterBody2D

const MOVE_SPEED := 600.0
const JUMP_VELOCITY := -1600.0
const GRAVITY := 4800.0
const GLIDE_FACTOR := 0.3
const COPY_DISTANCE := 160.0
const COPY_SIZE := 64.0

var is_gliding := false
var player_velocity: Vector2
var _facing := 1
var _copy_ready := false

@onready var _umbrella: Sprite2D = $UmbrellaSprite
@onready var _spawn_point: Node2D = get_parent().get_node_or_null("PlayerSpawn")
@onready var _game_manager: Node = get_parent()

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

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_copy_spawn()

func _handle_movement(delta: float) -> void:
	var direction := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	player_velocity.x = direction * MOVE_SPEED
	if direction != 0:
		_facing = sign(direction)

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			player_velocity.y = JUMP_VELOCITY
		else:
			player_velocity.y = 0
		_end_glide()
	else:
		if Input.is_action_pressed("jump"):
			_start_glide()
		else:
			_end_glide()

	if not is_on_floor():
		player_velocity.y += GRAVITY * delta

	if is_gliding and player_velocity.y > 0.0:
		player_velocity.y *= GLIDE_FACTOR

	velocity = player_velocity
	move_and_slide()
	_check_crush()

func _start_glide() -> void:
	if not is_gliding:
		is_gliding = true
		if _umbrella:
			_umbrella.visible = true

func _end_glide() -> void:
	if is_gliding:
		is_gliding = false
		if _umbrella:
			_umbrella.visible = false

func _handle_copy_spawn() -> void:
	if Input.is_action_just_pressed("copy_preview"):
		_copy_ready = true
	if not _copy_ready:
		return
	if Input.is_action_just_pressed("copy_spawn"):
		var dir := _get_quantized_direction()
		var spawn_pos := global_position + dir * COPY_SIZE
		if _can_spawn_at(spawn_pos):
			if _game_manager and _game_manager.has_method("spawn_player_copy"):
				_game_manager.spawn_player_copy(spawn_pos, dir)
		_copy_ready = false

func _get_quantized_direction() -> Vector2:
	var aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim.length() == 0.0:
		var viewport := get_viewport()
		if viewport:
			aim = (viewport.get_mouse_position() - global_position).normalized()
	if aim.length() == 0.0:
		aim = Vector2(_facing, 0)
	var angle := fposmod(aim.angle(), TAU)
	var step := PI / 4.0
	var index := int(round(angle / step)) % 8
	return Vector2.RIGHT.rotated(index * step).normalized()

func _can_spawn_at(pos: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = Vector2(COPY_SIZE, COPY_SIZE)
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0, pos)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var result := space_state.intersect_shape(params)
	return result.is_empty()

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
		var col := get_slide_collision(i)
		var body := col.get_collider()
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
