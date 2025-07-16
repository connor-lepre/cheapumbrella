extends RigidBody2D

@export var spawn_delay := 1.0
var spawn_position: Vector2
var is_respawning := false

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
