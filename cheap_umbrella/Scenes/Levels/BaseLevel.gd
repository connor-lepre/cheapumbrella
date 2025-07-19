extends Node2D

@onready var player_scene = preload("res://Scenes/player.tscn")
@onready var spawn_point = $SpawnPoint
@onready var copies = $Copies
@onready var camera = $Camera

var player: Node = null
var is_current: bool = false

func _ready():
	print("BaseLevel", self.name, "ready, player at", spawn_point.global_position)
	set_is_current(false)
	player = player_scene.instantiate()
	player.name = "Player"
	player.global_position = spawn_point.global_position

	if copies:
		player.set("copies_container", copies)

	add_child(player)

	# Ensure visibility matches current state
	set_is_current(is_current)

func set_is_current(value):
	print(self.name, "set_is_current:", value)
	is_current = value
	set_process(is_current)
	set_physics_process(is_current)
	visible = is_current

	# Enable/disable all rigidbodies in this level
	set_all_rigidbodies_enabled(is_current)

	if camera:
		camera.enabled = is_current
	if player:
		player.visible = is_current
		
func set_all_rigidbodies_enabled(state: bool):
	for child in get_children():
		# Check direct children
		if child is RigidBody2D:
			child.freeze = not state
			child.sleeping = not state
		# Check children of children (if you nest)
		for gchild in child.get_children():
			if gchild is RigidBody2D:
				gchild.freeze = not state
				gchild.sleeping = not state
