extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -800.0
const GRAVITY := 1200.0
const GLIDE_GRAVITY := 200.0
const RECORD_THRESHOLD := 0.5
const SKIP_TIME_AT_START := 2
const MAX_TOTAL_RECORD_TIME := 5.0  # Total allowed recording time in seconds

var spawn_point: Vector2
var is_gliding := false
var is_recording := false
var recording := []
var total_recorded_time := 0.0
var physics_fps := 60.0  # default fallback

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
	

func _physics_process(delta):
	handle_input(delta)
	handle_recording()
	move_and_slide()

func handle_input(delta):
	var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.x = direction * SPEED

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	is_gliding = Input.is_action_pressed("jump") and not is_on_floor() and velocity.y > 0
	velocity.y += (GLIDE_GRAVITY if is_gliding else GRAVITY) * delta

func handle_recording():
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
		total_recorded_time += 1.0 / physics_fps

		if total_recorded_time >= MAX_TOTAL_RECORD_TIME:
			is_recording = false
			print("⏱ Recording ended (time limit reached)")
			spawn_ghost()
			reset_player_position_after_recording()

func reset_player_position_after_recording():
	if recording.size() == 0:
		return

	var origin: Vector2 = recording[0]

	# Optional: bump the player slightly upward to avoid ghost collision
	origin.y -= 2.0  # Adjust if needed
	global_position = spawn_point

	print("Resetting to spawn:", global_position)

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
