extends CharacterBody2D

const SPEED := 800.0
const JUMP_VELOCITY := -1500.0
const GRAVITY := 5000.0
const GLIDE_GRAVITY := 200.0
const RECORD_THRESHOLD := 0.5
const MAX_TOTAL_RECORD_TIME := 2.0
const RESET_HOLD_TIME := 1.0

@export var max_copies := 4
var available_copies := 4

@onready var COPIES_SCENE = preload("res://Scenes/Copies.tscn")
@onready var hud_scene = preload("res://Scenes/UI/PlayerHUD.tscn")
var player_hud = null

@onready var facing = Vector2.LEFT
@onready var player_sprite: AnimatedSprite2D = $PlayerSprite
@onready var umbrella = $PlayerSprite/Umbrella
@onready var helmet = $helmet

var is_moving := false
var is_gliding := false
var is_jumping := false
var was_on_floor := false
var coyote_time := 0.0
var coyote_time_max := 0.3

var reset_hold_timer := 0.0
var spawn_point: Vector2

var was_recording_pressed := false
var is_recording := false
var current_recording := []
var time_left := MAX_TOTAL_RECORD_TIME

var physics_fps := 60.0

var copies_container: Node = null
@onready var root = get_tree().get_current_scene()

func _ready():
	print("Player ready")
	physics_fps = Engine.get_physics_ticks_per_second()

	if helmet:
		helmet.body_entered.connect(helmet_push)

	player_hud = get_tree().get_current_scene().get_node_or_null("PlayerHud")
	update_copy_ui()

	# Spawn point setup
	var start_node = root.get_node_or_null("SpawnPoint")
	spawn_point = start_node.global_position if start_node else global_position

func _physics_process(delta):
	handle_input(delta)
	move_and_slide()
	collision_with_RigidBody2d()
	sprite_flip(facing)
	sprite_anim_switch(is_gliding, is_moving, is_jumping)
	hide_show_umbrella(is_gliding)
	handle_recording()
	handle_reset_hold(delta)

func handle_input(delta):
	var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.x = direction * SPEED
	if abs(velocity.x) > 0.1:
		is_moving = true
		if direction > 0:
			facing = Vector2.RIGHT
		elif direction < 0:
			facing = Vector2.LEFT
	else:
		is_moving = false

	if not was_on_floor and is_on_floor():
		is_jumping = false

	if is_on_floor():
		coyote_time = coyote_time_max
	else:
		coyote_time = max(0.0, coyote_time - delta)

	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_time > 0.0):
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		coyote_time = 0.0

	is_gliding = Input.is_action_pressed("jump") and not is_on_floor() and velocity.y > 5
	velocity.y += (GLIDE_GRAVITY if is_gliding else GRAVITY) * delta
	was_on_floor = is_on_floor()

func collision_with_RigidBody2d():
	for i in get_slide_collision_count():
		var c: KinematicCollision2D = get_slide_collision(i)
		var rigid: RigidBody2D = c.get_collider() if c.get_collider() is RigidBody2D else null
		if rigid:
			var pushDir = -c.get_normal()
			var diffVelInPushDir: float = max(0.0, velocity.dot(pushDir) - rigid.linear_velocity.dot(pushDir))
			var massRatio: float = min(1.0, 1.0 / rigid.mass)
			var pushForce: float = massRatio * 4.0
			var maxImpulse: float = 400.0
			var impulseAmt = pushDir * diffVelInPushDir * pushForce
			impulseAmt = impulseAmt.limit_length(maxImpulse)
			rigid.apply_central_impulse(impulseAmt)

func helmet_push(body):
	if body is RigidBody2D:
		body.apply_central_impulse(Vector2(0, -800))

func handle_recording():
	if available_copies <= 0:
		update_copy_ui()
		return

	var strength = Input.get_action_strength("record")
	var is_pressed = strength > RECORD_THRESHOLD

	if is_pressed and not was_recording_pressed and not is_recording:
		is_recording = true
		current_recording.clear()
		time_left = MAX_TOTAL_RECORD_TIME
		print("🎥 Started recording copy")

	elif not is_pressed and is_recording:
		is_recording = false
		print("🛑 Manual end for copy")
		if spawn_copy(current_recording):
			available_copies -= 1
			update_copy_ui()
		reset_player_position_after_recording()

	was_recording_pressed = is_pressed

	if is_recording:
		current_recording.append([
			global_position,
			facing,
			is_moving,
			is_jumping,
			is_gliding
		])
		var delta_time = 1.0 / physics_fps
		time_left -= delta_time

		if time_left <= 0.0:
			is_recording = false
			time_left = 0.0
			print("⏱ Recording ended for copy")
			if spawn_copy(current_recording):
				available_copies -= 1
				update_copy_ui()
			reset_player_position_after_recording()

func sprite_flip(facing):
	if player_sprite:
		player_sprite.flip_h = facing == Vector2.RIGHT

func sprite_anim_switch(is_gliding, is_moving, is_jumping):
	if player_sprite:
		if is_gliding:
			player_sprite.play("glide")
		elif is_moving:
			player_sprite.play("move")
		elif is_jumping:
			player_sprite.play("jump")
		else:
			player_sprite.play("idle")

func hide_show_umbrella(is_gliding):
	if umbrella:
		umbrella.visible = is_gliding

func spawn_copy(recording: Array) -> bool:
	if recording.size() < 2:
		print("Recording too short — no copy spawned.")
		return false

	if copies_container == null:
		copies_container = get_tree().get_current_scene().get_node_or_null("copyPlatforms")
		if copies_container == null:
			push_error("❌ copyPlatforms node not found in scene root.")
			return false

	if copies_container.get_child_count() >= max_copies:
		print("🚫 Max copy count reached. No new copy spawned.")
		return false

	var copy = COPIES_SCENE.instantiate()
	copy.set_path(recording)
	copy.global_position = recording[0][0] - Vector2(0, 64)
	copies_container.add_child(copy)
	print("✅ Copy added to copyPlatforms at position:", copy.global_position)
	return true

func reset_player_position_after_recording():
	global_position = spawn_point

func update_copy_ui():
	if player_hud == null:
		return
	var hbox = player_hud.get_node("AvailableCopies")
	if hbox.get_child_count() == 0:
		push_error("AvailableCopies HBox must have at least one child as a template token.")
		return
	print("updating tokens: available_copies =", available_copies)
	# Remove extras
	while hbox.get_child_count() > max_copies:
		hbox.get_child(hbox.get_child_count() - 1).queue_free()
	# Add missing
	while hbox.get_child_count() < max_copies:
		var token = hbox.get_child(0).duplicate()
		hbox.add_child(token)
		print("Added token:", token)
	# Show/hide tokens (left to right)
	for i in range(max_copies):
		var token = hbox.get_child(i)
		token.visible = (i < available_copies)
		print("Token", i, "visible:", token.visible)

func handle_reset_hold(delta):
	if Input.is_action_pressed("reset_level"):
		reset_hold_timer += delta
		if reset_hold_timer >= RESET_HOLD_TIME:
			print("🔁 Reset triggered")
			reset_hold_timer = 0.0
			available_copies = max_copies
			update_copy_ui()
			reload_scene()
	else:
<<<<<<< Updated upstream
		reset_hold_timer = 0.0
=======
		reload_hold_timer = 0.0

func handle_retry_hold(delta):
	if Input.is_action_pressed("retry"):
		retry_hold_timer += delta
		if retry_hold_timer >= RESET_HOLD_TIME:
			print("🔁 Retry triggered")
			retry_hold_timer = 0.0
			available_copies = max_copies
			update_copy_ui()
			respawn()
			for child in copies_container.get_children():
				child.queue_free()
			move_ball_in_front()
			
	else:
		retry_hold_timer = 0.0

func move_ball_in_front():
	var ball = null
	for node in get_tree().get_nodes_in_group("ball"):
		ball = node
		break
	if ball:
		var offset = facing.x if facing.x != 0 else 1
		ball.global_position = global_position + Vector2(offset * 64, 0)
		ball.linear_velocity = Vector2.ZERO
		ball.angular_velocity = 0.0
		# Optionally, call a method like ball.respawn() if you want to reset anything else.

func set_checkpoint(pos: Vector2):
	prev_checkpoint = pos
	print("Checkpoint set at: ", pos)
>>>>>>> Stashed changes

func respawn():
	print("💀 Player hit killplane - respawning")
	global_position = spawn_point
	velocity = Vector2.ZERO

func reload_scene():
	get_tree().reload_current_scene()
