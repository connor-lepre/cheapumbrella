extends CharacterBody2D

const SPEED := 400.0
const JUMP_VELOCITY := -1500.0
const GRAVITY := 5000
const GLIDE_GRAVITY := 200.0
const RECORD_THRESHOLD := 0.5
const SKIP_TIME_AT_START := 2
const MAX_TOTAL_RECORD_TIME := 5.0
const RESET_HOLD_TIME := 2.0

var reset_hold_timer := 0.0
var spawn_point: Vector2
var is_gliding := false
var is_recording := false
var recording := []
var physics_fps := 60.0
var total_recorded_time: float = 0.0
var time_left := MAX_TOTAL_RECORD_TIME
var timer_ui: Node = null
var can_record := true

func _ready():
	print("Player ready")
	is_recording = false
	recording.clear()
	total_recorded_time = 0.0
	physics_fps = Engine.get_physics_ticks_per_second()
	
	var start_node = get_tree().get_current_scene().get_node_or_null("SpawnPoint")
	if start_node:
		spawn_point = start_node.global_position
	else:
		print("⚠️ SpawnPoint not found in scene!")
	
	timer_ui = get_tree().get_current_scene().get_node_or_null("CanvasLayer/CopyTimerUI")
	update_timer_ui()

func _physics_process(delta):
	# Block downward push-through when on floor
	if is_on_floor() and velocity.y > 0:
		velocity.y = 0

	handle_input(delta)
	handle_recording()
	move_and_slide()
	handle_reset_hold(delta)

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		var normal = collision.get_normal()

		if collider and collider.has_method("add_external_velocity"):
			# Push crates horizontally
			if abs(normal.x) > 0.7:
				var push_force = velocity.x * 5
				collider.add_external_velocity(Vector2(push_force, 0))

		# Block being shoved through ground
		if normal.y < -0.7 and velocity.y > 0:
			velocity.y = 0
			global_position.y -= 4

func handle_input(delta):
	var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.x = direction * SPEED

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	is_gliding = Input.is_action_pressed("jump") and not is_on_floor() and velocity.y > 0
	velocity.y += (GLIDE_GRAVITY if is_gliding else GRAVITY) * delta

func handle_recording():
	if not can_record:
		return

	var strength = Input.get_action_strength("record")

	if strength > RECORD_THRESHOLD and not is_recording:
		is_recording = true
		recording.clear()
		total_recorded_time = 0.0
		print("🎥 Recording started")

	elif strength <= RECORD_THRESHOLD and is_recording:
		is_recording = false
		print("🛑 Recording ended (manual)")
		spawn_ghost()
		reset_player_position_after_recording()

	if is_recording:
		recording.append(global_position)
		var delta_time = 1.0 / physics_fps
		total_recorded_time += delta_time
		time_left -= delta_time
		update_timer_ui()

		if time_left <= 0.0:
			time_left = 0.0
			can_record = false
			is_recording = false
			print("⏱ Recording ended (time limit reached)")
			spawn_ghost()
			reset_player_position_after_recording()

func reset_player_position_after_recording():
	var skip_frames := int(SKIP_TIME_AT_START * physics_fps)
	var safe_index = clamp(skip_frames, 0, recording.size() - 1)
	global_position = spawn_point

func spawn_ghost():
	if recording.size() < 2:
		print("Recording too short — no ghost spawned.")
		return

	print("📦 Spawning ghost with", recording.size(), "points.")
	var ghost_scene = preload("res://Scenes/GhostPlatforms.tscn")
	var ghost = ghost_scene.instantiate()
	ghost.set_path(recording)
	ghost.global_position = recording[0] - Vector2(0, 64)

	var scene_root = get_tree().get_current_scene()
	var ghost_container = scene_root.get_node_or_null("GhostPlatforms")

	if ghost_container:
		ghost_container.add_child(ghost)
		print("✅ Ghost added to GhostPlatforms.")
	else:
		print("❌ GhostPlatforms node not found in scene root.")

func update_timer_ui():
	if timer_ui == null:
		return
	var display_time = max(0, floor(time_left * 10) / 10.0)
	timer_ui.text = str(display_time) + "s"

func handle_reset_hold(delta):
	if Input.is_action_pressed("reset_level"):
		reset_hold_timer += delta
		if reset_hold_timer >= RESET_HOLD_TIME:
			print("🔁 Reset triggered")
			reset_hold_timer = 0.0
			reload_scene()
	else:
		reset_hold_timer = 0.0

func reload_scene():
	get_tree().reload_current_scene()
