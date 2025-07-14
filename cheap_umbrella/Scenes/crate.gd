extends CharacterBody2D

const GRAVITY := 1200.0
const FRICTION := 500.0
const MAX_PUSH := 60.0
const PUSH_DECAY := 600.0

var external_velocity := Vector2.ZERO
var vertical_velocity := 0.0

func _physics_process(delta):
	# Gravity
	vertical_velocity += GRAVITY * delta

	# Smooth side push decay
	external_velocity = external_velocity.move_toward(Vector2.ZERO, PUSH_DECAY * delta)

	# Combine vertical and horizontal motion
	velocity = Vector2(external_velocity.x, vertical_velocity)

	# Move and update vertical velocity
	move_and_slide()
	if is_on_floor():
		vertical_velocity = 0.0

func add_external_velocity(push: Vector2, multiplier: float = 0.1):
	if abs(push.x) > 0.1:
		external_velocity.x += clamp(push.x * multiplier, -MAX_PUSH, MAX_PUSH)
