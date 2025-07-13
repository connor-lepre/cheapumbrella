extends CharacterBody2D

const MOVE_SPEED := 300.0
const JUMP_VELOCITY := -800.0
const GRAVITY := 2400.0
const GLIDE_FACTOR := 0.6

const MIN_COPY_TIME := 1.0
const MAX_COPY_TIME := 5.0
const POINT_INTERVAL := 1.0

var is_gliding := false
var player_velocity: Vector2

var _recording := false
var _record_timer := 0.0
var _next_point := 0.0
var _record_points: Array[Vector2] = []

@onready var _umbrella: Sprite2D = $UmbrellaSprite
@onready var _spawn_point: Node2D = get_parent().get_node_or_null("PlayerSpawn")
@onready var _game_manager: Node = get_parent()
@onready var _path_visualizer: Node2D = get_parent().get_node_or_null("CopiesRoot/PathVisualizer")

func _ready() -> void:
	if _umbrella:
		_umbrella.visible = false
	else:
		push_warning("UmbrellaSprite node missing")

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
	_handle_copy_recording(delta)

func _handle_movement(delta: float) -> void:
	var direction := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	player_velocity.x = direction * MOVE_SPEED
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			player_velocity.y = JUMP_VELOCITY
		_end_glide()
	else:
		if Input.is_action_just_pressed("jump"):
			if not is_gliding:
				_start_glide()
			else:
				_end_glide()

	self.velocity = player_velocity
	player_velocity.y += GRAVITY * delta
	if is_gliding and player_velocity.y > 0.0:
			# Slow the fall while gliding
		player_velocity.y *= GLIDE_FACTOR
	move_and_slide()

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

func _handle_copy_recording(delta: float) -> void:
	if Input.is_action_just_pressed("copy_action"):
		if _recording:
			if _record_timer >= MIN_COPY_TIME:
				_stop_recording()
			else:
				print("Copy recording too short to stop")
		else:
			_start_recording()

	if _recording:
		_record_timer += delta
		if _record_timer >= _next_point:
			_record_points.append(global_position)
			_next_point += POINT_INTERVAL
			if _path_visualizer and _path_visualizer.has_method("set_points"):
				_path_visualizer.set_points(_record_points)
		if _record_timer >= MAX_COPY_TIME:
			_stop_recording()

func _start_recording() -> void:
	_recording = true
	_record_timer = 0.0
	_next_point = 0.0
	_record_points.clear()
	_record_points.append(global_position)
	if _path_visualizer and _path_visualizer.has_method("set_points"):
		_path_visualizer.show()
		_path_visualizer.set_points(_record_points)
	print("Copy recording started")

func _stop_recording() -> void:
	_recording = false
	if _path_visualizer:
		_path_visualizer.hide()
	if _record_points.size() < 2:
		print("Not enough points to create copy")
		return
	var base := _record_points[0]
	var rel_points: Array = []
	for p in _record_points:
		rel_points.append(p - base)
	if _game_manager and _game_manager.has_method("spawn_player_copy"):
		_game_manager.spawn_player_copy(base, rel_points)
	else:
		push_warning("Cannot spawn player copy - manager missing or invalid")
	if _spawn_point:
		global_position = _spawn_point.global_position
		velocity = Vector2.ZERO
	_end_glide()
	print("Copy recording stopped")
