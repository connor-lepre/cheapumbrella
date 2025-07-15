extends CharacterBody2D

const GRAVITY := 2000.0
const FRICTION_STRENGTH := 3000.0
const MAX_VELOCITY_X := 600.0
const MASS := 1.5
const RESPAWN_DELAY := 1.0

var is_being_pushed := false
var spawn_position: Vector2
var is_respawning := false

func _ready():
	spawn_position = global_position

func _physics_process(delta):
	if is_respawning:
		return  # Don't simulate while waiting to respawn

	is_being_pushed = false

	velocity.y += GRAVITY * delta

	if is_on_floor() and not is_being_pushed:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION_STRENGTH * delta)

	velocity.x = clamp(velocity.x, -MAX_VELOCITY_X, MAX_VELOCITY_X)

	move_and_slide()

func apply_push(force: Vector2):
	is_being_pushed = true
	velocity.x += force.x / MASS

func respawn():
	if is_respawning:
		return

	print("💀 Crate hit killplane - respawning")
	is_respawning = true
	visible = false
	velocity = Vector2.ZERO

	await get_tree().create_timer(RESPAWN_DELAY).timeout

	global_position = spawn_position
	velocity = Vector2.ZERO
	visible = true
	is_respawning = false
	print("📦 Crate respawned at: ", spawn_position)
