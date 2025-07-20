extends CharacterBody2D

const SPEED := 800.0
const JUMP_VELOCITY := -1300.0
const GRAVITY := 5000.0
const GLIDE_GRAVITY := 200.0
const RECORD_THRESHOLD := 0.5
const MAX_TOTAL_RECORD_TIME := 0.9
const RESET_HOLD_TIME := 0.5

@export var max_copies := 3
var available_copies := 3

@onready var COPIES_SCENE = preload("res://Scenes/Copies.tscn")
@onready var TOKEN_ACTIVE_IMAGE = preload("res://Assets/Sprites/ui/copy-token.png")
@onready var TOKEN_USED_IMAGE = preload("res://Assets/sprites/ui/copy-token-used.png")

@onready var facing = Vector2.LEFT
@onready var player_sprite: AnimatedSprite2D = $PlayerSprite
@onready var umbrella = $PlayerSprite/Umbrella
@onready var copy_hint = $PlayerSprite.get_node_or_null("CopyHint")
@onready var retry_timer_label = $PlayerSprite.get_node_or_null("RetryTimer")
@onready var retry_cooldown := 0.0
@onready var copy_hint_lag_time := 0.08
@onready var copy_hint_pos_buffer := []
@onready var throw_meter = get_parent().get_node_or_null("ThrowMeter")
@onready var available_copies_ui = get_tree().get_current_scene().get_node_or_null("AvailableCopies")
@onready var copies_ui = null

@onready var sfx_walk: AudioStreamPlayer2D = get_node_or_null("SFX/Walk")
@onready var sfx_glide: AudioStreamPlayer2D = get_node_or_null("SFX/Glide")
@onready var sfx_jump: AudioStreamPlayer2D = get_node_or_null("SFX/Jump")
var walk_step_timer := 0.0
var walk_interval := 0.4 # Time between steps, adjust as needed

var is_moving := false
var is_gliding := false
var was_gliding := false
var is_jumping := false
var was_on_floor := false
var coyote_time := 0.0
var coyote_time_max := 0.3

# Ball holding state
var held_ball: RigidBody2D = null    # Reference to the held ball, or null if not holding
var ball_hold_timer := 0.0
const PICKUP_DISTANCE := 120.0 # Tweak as needed

var reload_hold_timer := 0.0
var retry_hold_timer := 0.0
var spawn_point: Vector2
var prev_checkpoint: Vector2

var was_recording_pressed := false
var is_recording := false
var current_recording := []
var time_left := MAX_TOTAL_RECORD_TIME

# Throw charge variables
var throw_charge := 0.0
const THROW_MIN_FORCE := 0.1   # 10% of full force
const THROW_MAX_TIME := 0.6    # How many seconds to reach full charge (adjust to taste)
var is_charging_throw := false

var physics_fps := 60.0

var copies_container: Node = null
@onready var root = get_tree().get_current_scene()

func _ready():
	print("Player ready")
	print("Player throw_meter is: ", throw_meter)
	physics_fps = Engine.get_physics_ticks_per_second()
	add_to_group("Player")

	var ball = null
	for node in get_tree().get_nodes_in_group("ball"):
		ball = node
		break

	copies_ui = get_tree().get_current_scene().get_node_or_null("PlayerHud")
	update_copy_ui()

	# Spawn point setup
	var start_node = get_parent().get_node_or_null("SpawnPoint")
	spawn_point = start_node.global_position if start_node else global_position
	print("Player using spawn point at:", spawn_point)

func _physics_process(delta):
	handle_input(delta)
	handle_ball_interaction(delta)
	move_and_slide()
	collision_with_RigidBody2d()
	sprite_flip(facing)
	sprite_anim_switch(is_gliding, is_moving, is_jumping)
	hide_show_umbrella(is_gliding)
	handle_recording()
	handle_retry_hold(delta)
	update_copy_hint(delta)
	
	# Walk SFX
	if is_moving and is_on_floor():
		walk_step_timer -= delta
		if walk_step_timer <= 0.0:
			play_walk_step()
			walk_step_timer = walk_interval
	else:
		walk_step_timer = 0.0
		
	# Glide SFX
	if is_gliding and not was_gliding:
		sfx_glide.play()
	was_gliding = is_gliding

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
		sfx_jump.play()

	is_gliding = Input.is_action_pressed("jump") and not is_on_floor() and velocity.y > 5
	velocity.y += (GLIDE_GRAVITY if is_gliding else GRAVITY) * delta
	was_on_floor = is_on_floor()
	
	# Menu UI Focus
	if Input.is_action_just_pressed("menu"):
		if root.has_method("toggle_menu_ui_focus"):
			root.toggle_menu_ui_focus()

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

#func helmet_push(body):
	#if body is RigidBody2D:
		#body.apply_central_impulse(Vector2(0, -800))

func handle_ball_interaction(delta):
	if held_ball and is_instance_valid(held_ball):
		held_ball.global_position = global_position
		held_ball.freeze_ball(true)

		# Drop
		if Input.is_action_just_pressed("drop"):
			drop_ball()

		# Start charging throw
		if Input.is_action_just_pressed("shoot"):
			is_charging_throw = true
			throw_charge = 0.0

		# While charging
		if is_charging_throw and Input.is_action_pressed("shoot"):
			throw_charge += delta
			throw_charge = min(throw_charge, THROW_MAX_TIME)
			if throw_meter:
				throw_meter.set_power(throw_charge / THROW_MAX_TIME)
				throw_meter.visible = true  # Ensures it stays visible during charge

		# On throw release
		if is_charging_throw and Input.is_action_just_released("shoot"):
			shoot_ball_with_charge()
			is_charging_throw = false
			throw_charge = 0.0
			if throw_meter:
				throw_meter.set_power(0.0)

	else:
		var ball = get_nearby_ball()
		if Input.is_action_just_pressed("grab") and ball:
			pickup_ball(ball)
			print("Grabbed ball")

		elif Input.is_action_just_pressed("drop") and ball:
			dribble_ball(ball)
			print("Dribbled ball")

func get_nearby_ball():
	# Naive: loop all balls, find nearest within distance
	for ball in get_tree().get_nodes_in_group("ball"):
		if ball.global_position.distance_to(global_position) < PICKUP_DISTANCE and not ball.is_held:
			return ball
	return null

func pickup_ball(ball):
	held_ball = ball
	held_ball.is_held = true
	ball_hold_timer = 0.0
	held_ball.freeze_ball(true)
	held_ball.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	held_ball.global_position = global_position

func drop_ball():
	if held_ball:
		held_ball.is_held = false
		held_ball.freeze_ball(false)
		# Use *current* movement for x direction
		var move_x = clamp(velocity.x, -900, 900)  # Adjust clamp as needed
		var drop_force = Vector2(move_x, 200)
		held_ball.apply_throw(drop_force)
		held_ball = null
		ball_hold_timer = 0.0

func dribble_ball(ball):
	# Applies a bounce force downward and a bit forward, **based on current movement**
	var move_x = clamp(velocity.x, -1200, 1200)  # Adjust for "push" left/right
	var dribble_force = Vector2(move_x, 420)   # Y value = bounce height
	ball.apply_throw(dribble_force)
		
func shoot_ball_with_charge():
	if held_ball:
		# Place ball above player and unfreeze
		held_ball.global_position = global_position + Vector2(0, -32)
		held_ball.freeze_ball(false)
		var direction_x = facing.x if facing.x != 0 else 1
		var t = throw_charge / THROW_MAX_TIME
		t = clamp(t, THROW_MIN_FORCE, 1.0)  # Ensure min/max limits
		var throw_force = Vector2(direction_x * 800, -800) * t
		held_ball.apply_throw(throw_force, 50.0 * t)
		held_ball.is_held = false
		held_ball = null

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

func play_walk_step():
	sfx_walk.pitch_scale = randf_range(0.95, 1.05)
	if sfx_walk:
		sfx_walk.play()

func hide_show_umbrella(is_gliding):
	if umbrella:
		umbrella.visible = is_gliding
		
func update_copy_hint(delta):
	# Maintain a buffer of positions for lag
	copy_hint_pos_buffer.append(global_position)
	
	var max_buffer = int(copy_hint_lag_time * physics_fps)
	if copy_hint_pos_buffer.size() > max_buffer:
		copy_hint_pos_buffer.pop_front()
	
	if is_recording:
		copy_hint.visible = true
		# Lagged position: use oldest position in buffer if available
		if copy_hint_pos_buffer.size() >= max_buffer:
			copy_hint.global_position = copy_hint_pos_buffer[0]
		else:
			copy_hint.global_position = global_position
		# Flip based on facing direction (assuming horizontal flip is correct)
		copy_hint.flip_h = (facing == Vector2.RIGHT)
	else:
		copy_hint.visible = false

func spawn_copy(recording: Array) -> bool:
	if recording.size() < 2:
		print("Recording too short — no copy spawned.")
		return false

	if copies_container == null:
		copies_container = get_tree().get_current_scene().get_node_or_null("Copies")
		if copies_container == null:
			push_error("❌ Copies node not found in scene root.")
			return false

	if copies_container.get_child_count() >= max_copies:
		print("🚫 Max copy count reached. No new copy spawned.")
		return false

	var copy = COPIES_SCENE.instantiate()
	copy.set_path(recording)
	copy.global_position = recording[0][0] - Vector2(0, 64)
	copies_container.add_child(copy)
	print("✅ Copy added to Copies at position:", copy.global_position)
	return true

func reset_player_position_after_recording():
	global_position = spawn_point

func update_copy_ui():
	if copies_ui == null:
		return
	var hbox = copies_ui
	if hbox.get_child_count() == 0:
		push_error("AvailableCopies HBox must have at least one child as a template token.")
		return

	# Ensure exactly max_copies tokens
	while hbox.get_child_count() > max_copies:
		hbox.get_child(hbox.get_child_count() - 1).queue_free()
	while hbox.get_child_count() < max_copies:
		var token = hbox.get_child(0).duplicate()
		hbox.add_child(token)

	# Update each token image/state
	for i in range(max_copies):
		var token = hbox.get_child(i)
		if token is TextureRect:
			if i < available_copies:
				token.texture = TOKEN_ACTIVE_IMAGE
				token.modulate = Color(1, 1, 1, 1)  # Full color
			else:
				token.texture = TOKEN_USED_IMAGE
				token.modulate = Color(1, 1, 1, 1)  # Or lower alpha if desired (e.g. Color(1, 1, 1, 0.3))
		token.visible = true  # Always show all tokens

	# Hide extra (shouldn’t be needed but for safety)
	for i in range(hbox.get_child_count()):
		if i >= max_copies:
			hbox.get_child(i).visible = false


func handle_retry_hold(delta):
	# Cooldown active: decrement and block input/label
	if retry_cooldown > 0.0:
		retry_cooldown -= delta
		retry_timer_label.visible = false
		retry_hold_timer = 0.0
		return

	if Input.is_action_pressed("retry"):
		retry_hold_timer += delta
		retry_timer_label.visible = true

		# One dot per 0.05s held, max 6
		var dots_count = int(retry_hold_timer / 0.07)
		dots_count = clamp(dots_count, 0, 5)
		retry_timer_label.text = "🞀".repeat(dots_count)

		if retry_hold_timer >= RESET_HOLD_TIME:
			print("🔁 Retry triggered")
			retry_hold_timer = 0.0
			retry_timer_label.visible = false
			available_copies = max_copies
			update_copy_ui()
			respawn()
			for child in copies_container.get_children():
				child.queue_free()
			move_ball_in_front()
			# Set buffer/cooldown for next retry
			retry_cooldown = 0.5  # half a second buffer before new retry allowed
	else:
		retry_hold_timer = 0.0
		retry_timer_label.visible = false




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

func respawn():
	if prev_checkpoint:
		global_position = prev_checkpoint
	else:
		global_position = spawn_point
	velocity = Vector2.ZERO

func reload_scene():
	get_tree().reload_current_scene()
