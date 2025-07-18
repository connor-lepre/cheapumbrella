extends Node2D

@onready var player_scene = preload("res://Scenes/player.tscn")
@onready var spawn_point = $SpawnPoint
@onready var copies = $Copies
@onready var camera = $Camera

var player: Node = null
var is_current: bool = false

func _init():
	visible = false
	set_process(false)
	set_physics_process(false)

func _ready():
	player = player_scene.instantiate()
	player.name = "Player"
	player.global_position = spawn_point.global_position

	camera.enabled = false

	if copies:
		player.set("copies_container", copies)

	add_child(player)

func set_is_current(value):
	is_current = value
	set_process(is_current)
	set_physics_process(is_current)
	visible = is_current
	if camera:
		camera.enabled = is_current
	if player:
		player.visible = is_current
