extends CharacterBody2D

const SPEED := 800.0
const JUMP_VELOCITY := -1500.0
const GRAVITY := 5000.0
const GLIDE_GRAVITY := 200.0
const RECORD_THRESHOLD := 0.5
const SKIP_TIME_AT_START := 2
const MAX_TOTAL_RECORD_TIME := 2.0
const RESET_HOLD_TIME := 1.0

const PUSH_MULTIPLIER_X := 20
const PUSH_MULTIPLIER_Y := 0
const PUSH_FORCE_LIMIT := 60

@export var max_ghosts := 4

@onready var push_force = 1.0

@onready var facing = Vector2.LEFT
@onready var player_sprite = $Sprite2D
@onready var umbrella = $Sprite2D/Umbrella
@onready var helmet = $helmet
var is_moving := false
var is_gliding := false
var is_jumping := false
signal moving
signal gliding
signal jumping

var kgMass = 1.0



var reset_hold_timer := 0.0
var spawn_point: Vector2

var physics_fps := 60.0
var was_recording_pressed := false

var previous_position := Vector2.ZERO
var estimated_velocity := Vector2.ZERO

var ghost_container: Node = null

var current_ghost_index := 0
var is_recording_per_ghost := []
var recordings := []
var time_left_per_ghost := []
var timer_labels := []

func _ready():
	print("Player ready")
	physics_fps = Engine.get_physics_ticks_per_second()

	helmet.body_entered.connect(helmet_push)

	var start_node = get_tree().get_current_scene().get_node_or_null("SpawnPoint")
	spawn_point = start_node.global_position if start_node else global_position

	# Setup timers
	for i in range(max_ghosts):
		var label = get_tree().get_current_scene().get_node_or_null("CanvasLayer/Timer" + str(i + 1))
		timer_labels.append(label)
		time_left_per_ghost.append(MAX_TOTAL_RECORD_TIME)
		is_recording_per_ghost.append(false)
		recordings.append([])

	for label in timer_labels:
		if label:
			label.text = "—"

	previous_position = global_position
	update_timer_ui()

func _physics_process(delta):
	# Input, movement, gliding
	handle_input(delta)

	# Movement
	move_and_slide()
	collision_with_RigidBody2d()

	# Push crates using ghost-style force
	#push_crates_ghost_style()
	
	# Sprite handling
	sprite_flip()
	sprite_anim_switch()
	hide_show_umbrella()

	# Estimate velocity AFTER movement
	estimated_velocity = global_position - previous_position
	previous_position = global_position

	# Recording & level reset
	handle_recording()
	handle_reset_hold(delta)

func handle_input(delta):
	var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.x = direction * SPEED
	
	if abs(velocity.x) > 0.1 and is_on_floor():
		is_moving = true
	else:
		is_moving = false

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		emit_signal("jumping")

	is_gliding = Input.is_action_pressed("jump") and not is_on_floor() and velocity.y > 0
	velocity.y += (GLIDE_GRAVITY if is_gliding else GRAVITY) * delta

func collision_with_RigidBody2d():
	for i in get_slide_collision_count():
		var c: KinematicCollision2D = get_slide_collision(i)
		var rigid: RigidBody2D = c.get_collider() if c.get_collider() is RigidBody2D else null
		if rigid:
			var pushDir = -c.get_normal()
			var diffVelInPushDir: float = max(0.0, velocity.dot(pushDir) - rigid.linear_velocity.dot(pushDir))
			var massRatio: float = min(1.0, kgMass / rigid.mass)
			var pushForce: float = massRatio * 5.0
			# rigid.apply_impulse(pushDir * diffVelInPushDir * pushForce, c.get_position() - rigid.position) 
			var impulseAmt = pushDir * diffVelInPushDir * pushForce
			rigid.apply_central_impulse(impulseAmt)
			
func helmet_push(body):
	
	if body.get_parent() is RigidBody2D:
		body.get_parent().apply_central_impulse(Vector2(0, -500))
		print("helmet push was called and an impulse was attempted")

#func push_crates_ghost_style():
	#for i in range(get_slide_collision_count()):
		#var collision = get_slide_collision(i)
		#var collider = collision.get_collider()
		#var normal = collision.get_normal()
		#
		#if collider and collider.has_method("apply_push"):
			#var is_side_push = abs(normal.x) > 0.6
			#if not is_side_push:
				#continue
#
			## Only push if you're actually trying to move
			#if abs(velocity.x) < 5:
				#continue
#
			#var push_force = Vector2(velocity.x * .5, 0)  # Smooth force instead of burst
			#collider.apply_push(push_force)


func handle_recording():
	if current_ghost_index >= max_ghosts:
		for i in range(max_ghosts):
			if timer_labels[i]:
				timer_labels[i].text = "X"
		return

	var strength = Input.get_action_strength("record")
	var is_pressed = strength > RECORD_THRESHOLD

	if is_pressed and not was_recording_pressed and not is_recording_per_ghost[current_ghost_index]:
		is_recording_per_ghost[current_ghost_index] = true
		recordings[current_ghost_index].clear()
		time_left_per_ghost[current_ghost_index] = MAX_TOTAL_RECORD_TIME
		print("🎥 Started recording ghost", current_ghost_index + 1)

	elif not is_pressed and is_recording_per_ghost[current_ghost_index]:
		is_recording_per_ghost[current_ghost_index] = false
		print("🛑 Manual end for ghost", current_ghost_index + 1)
		spawn_ghost(recordings[current_ghost_index])
		reset_player_position_after_recording()

	was_recording_pressed = is_pressed

	if current_ghost_index < max_ghosts and is_recording_per_ghost[current_ghost_index]:
		recordings[current_ghost_index].append([global_position, facing])
		var delta_time = 1.0 / physics_fps
		time_left_per_ghost[current_ghost_index] -= delta_time
		update_timer_ui()

		if time_left_per_ghost[current_ghost_index] <= 0.0:
			is_recording_per_ghost[current_ghost_index] = false
			time_left_per_ghost[current_ghost_index] = 0.0
			print("⏱ Recording ended for ghost", current_ghost_index + 1)
			spawn_ghost(recordings[current_ghost_index])
			reset_player_position_after_recording()

func sprite_flip():
	if Input.is_action_pressed("move_right"):
		facing = Vector2.RIGHT
		player_sprite.flip_h = true
	if Input.is_action_pressed("move_left"):
		facing = Vector2.LEFT
		player_sprite.flip_h = false

func sprite_anim_switch():
	if is_gliding:
		player_sprite.play("glide")
	elif is_moving:
		player_sprite.play("move")
	else:
		player_sprite.play("idle")
		
func hide_show_umbrella():
	if is_gliding:
		umbrella.visible = true
	else:
		umbrella.visible = false

func spawn_ghost(recording: Array):
	if recording.size() < 2:
		print("Recording too short — no ghost spawned.")
		return

	if ghost_container == null:
		ghost_container = get_tree().get_current_scene().get_node_or_null("GhostPlatforms")
		if ghost_container == null:
			print("❌ GhostPlatforms node not found in scene root.")
			return

	if ghost_container.get_child_count() >= max_ghosts:
		print("🚫 Max ghost count reached. No new ghost spawned.")
		return

	var ghost_scene = preload("res://Scenes/GhostPlatforms.tscn")
	var ghost = ghost_scene.instantiate()
	ghost.set_path(recording)
	ghost.global_position = recording[0][0] - Vector2(0, 64)

	ghost_container.add_child(ghost)
	print("✅ Ghost added to GhostPlatforms.")
	current_ghost_index += 1
	if current_ghost_index >= max_ghosts:
		print("✅ All ghosts used.")
		current_ghost_index = max_ghosts
	update_timer_ui()

func reset_player_position_after_recording():
	global_position = spawn_point

func update_timer_ui():
	for i in range(max_ghosts):
		var label = timer_labels[i]
		if label == null:
			continue
		if i < current_ghost_index:
			label.text = "X"
		elif i == current_ghost_index and is_recording_per_ghost[i]:
			var clamped_time = max(0.0, time_left_per_ghost[i])
			var display_time = floor(clamped_time * 10) / 10.0
			label.text = str(display_time) + "s"
		else:
			label.text = "READY"

func handle_reset_hold(delta):
	if Input.is_action_pressed("reset_level"):
		reset_hold_timer += delta
		if reset_hold_timer >= RESET_HOLD_TIME:
			print("🔁 Reset triggered")
			reset_hold_timer = 0.0
			reload_scene()
	else:
		reset_hold_timer = 0.0
		

func respawn():
	print("💀 Player hit killplane - respawning")
	global_position = spawn_point
	velocity = Vector2.ZERO

func reload_scene():
	get_tree().reload_current_scene()
