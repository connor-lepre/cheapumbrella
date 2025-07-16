extends RigidBody2D

@export var spawn_delay := 1.0
var spawn_position: Vector2
var is_respawning := false

func _ready():
	spawn_position = global_position

func apply_push(force: Vector2):
	# Adds impulse to crate (mass is considered automatically)
	apply_central_impulse(force)

func respawn():
	if is_respawning:
		return

	print("📦 Crate will respawn...")
	is_respawning = true
	visible = false
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

	await get_tree().create_timer(spawn_delay).timeout

	global_position = spawn_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = false
	visible = true
	is_respawning = false
