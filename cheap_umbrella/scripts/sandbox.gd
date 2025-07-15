extends Node2D

@onready var spawn_point = $SpawnPoint
@onready var ghost_platforms = $GhostPlatforms

func _ready():
	var player_scene = preload("res://Scenes/player.tscn")
	var player = player_scene.instantiate()
	player.name = "Player"  # Give it a specific name
	player.global_position = spawn_point.global_position
	
	# Pass the GhostPlatforms node (optional)
	if ghost_platforms:
		player.set("ghost_container", ghost_platforms)
	
	add_child(player)
