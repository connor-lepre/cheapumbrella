extends RigidBody2D

@export var spawn_delay := 1.0
var spawn_position: Vector2
var is_respawning := false

var is_held := false

func _ready():
	spawn_position = global_position

func _physics_process(delta):
	pass

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


func apply_throw(force: Vector2):
	linear_velocity = Vector2.ZERO
	apply_central_impulse(force)
