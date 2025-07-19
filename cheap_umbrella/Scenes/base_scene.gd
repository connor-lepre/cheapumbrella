extends Node2D

@onready var player_scene = preload("res://Scenes/player.tscn")
@onready var spawn_point = $SpawnPoint
@onready var copies = $Copies

func _ready():
	var player = player_scene.instantiate()
	player.name = "Player"  # Give it a specific name
	player.global_position = spawn_point.global_position
	
	# Pass the GhostPlatforms node (optional)
	if copies:
		player.set("copies_container", copies)
	
	add_child(player)
