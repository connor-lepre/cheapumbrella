extends Node

signal level_completed

# List your level scenes here (expand as needed)
var level_scenes := [
	preload("res://Scenes/Levels/Level0.tscn"),
	preload("res://Scenes/Levels/Level1.tscn"),
	preload("res://Scenes/Levels/Level2.tscn"),
	preload("res://Scenes/Levels/Level3.tscn"),
	preload("res://Scenes/Levels/Level4.tscn"),
	preload("res://Scenes/Levels/Level5.tscn")
]

var current_level: Node = null
var current_index: int = -1

func _ready():
	next_level()  # Start at Level 0

func _activate_level(index: int) -> void:
	# Remove previous level if it exists
	if current_level:
		print("Freeing previous level:", current_level.name)
		current_level.queue_free()
		current_level = null

	print("Instancing level index:", index)
	var new_level = level_scenes[index].instantiate()
	add_child(new_level)
	new_level.set_is_current(true)
	current_level = new_level
	current_index = index

	# Connect signals from Basket (or any other node as needed)
	var basket = current_level.get_node_or_null("Basket")
	if basket:
		if basket.has_signal("ball_scored"):
			print("Connecting ball_scored from", basket.name, "to LevelManager._on_goal_scored")
			basket.connect("ball_scored", Callable(self, "_on_goal_scored"), CONNECT_ONE_SHOT)
		else:
			print("Basket found, but no ball_scored signal!")
	else:
		print("⚠️ No Basket found in current level!")

func _on_goal_scored(_data = null) -> void:
	print("LevelManager: Received ball_scored signal, current_index:", current_index)
	emit_signal("level_completed", current_index)

func next_level() -> void:
	var next_index = current_index + 1
	if next_index < level_scenes.size():
		_activate_level(next_index)
	else:
		print("🎉 All levels complete!")
