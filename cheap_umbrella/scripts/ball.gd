extends RigidBody2D

@export var spawn_delay := 1.0
var spawn_position: Vector2
var is_respawning := false

@onready var trail = $Trail
const TRAIL_LENGTH = 2000

var is_held := false

func _ready():
	spawn_position = global_position

func respawn():
	if is_respawning:
		return

	print("📦 Crate will respawn...")
	is_respawning = true
	visible = false

	await get_tree().create_timer(spawn_delay).timeout

	global_position = spawn_position
	visible = true
	is_respawning = false

func freeze_ball(state: bool):
	freeze = state  # Godot 4 property for RigidBody2D


func apply_throw(force: Vector2, torque: float = 0.0):
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	apply_central_impulse(force)
	apply_torque_impulse(torque)
