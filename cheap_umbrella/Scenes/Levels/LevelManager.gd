extends Node

signal level_completed

const THROW_METER_SCENE = preload("res://Scenes/UI/ThrowMeter.tscn")
const AVAILABLE_COPIES_SCENE = preload("res://Scenes/UI/AvailableCopies.tscn") 
const WIN_SCENE = preload("res://Scenes/Levels/Win.tscn")
const LOSE_SCENE = preload("res://Scenes/Levels/Lose.tscn")

@onready var win_scene = WIN_SCENE
@onready var lose_scene = LOSE_SCENE

# List your level scenes here (expand as needed)
var level_scenes := [
	preload("res://Scenes/Levels/Level0.tscn"),
	preload("res://Scenes/Levels/Level1.tscn"),
	preload("res://Scenes/Levels/Level2.tscn"),
	preload("res://Scenes/Levels/Level3.tscn"),
	preload("res://Scenes/Levels/Level4.tscn"),
	preload("res://Scenes/Levels/Level5.tscn"),
	# Any new levels here
	
	# Win state
	preload("res://Scenes/Levels/Level99.tscn")
	
	# Lose state
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
	
	var player = new_level.get_node_or_null("Player")
	
	# THROW METER
	var throw_meter = THROW_METER_SCENE.instantiate()
	throw_meter.name = "ThrowMeter"
	new_level.add_child(throw_meter)
	throw_meter.position = Vector2(-975.0, 1036.0)
	throw_meter.set_power(0.0)
	
	# AVAILABLE COPIES
	var available_copies_ui = AVAILABLE_COPIES_SCENE.instantiate()
	available_copies_ui.name = "AvailableCopies"
	new_level.add_child(available_copies_ui)
	available_copies_ui.position = Vector2(600.0, 910) # Adjust as needed to the right of ThrowMeter
	
	# Assign UI refs to player if player exists
	if player:
		player.throw_meter = throw_meter
		player.copies_ui = available_copies_ui
		player.update_copy_ui()
		print("Assigned throw_meter and available_copies to player:", throw_meter, available_copies_ui)
	
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
	if current_index >= 0 and level_scenes[current_index].resource_path.ends_with("Level99.tscn"):
		get_tree().quit()

func next_level() -> void:
	var next_index = current_index + 1
	if next_index < level_scenes.size():
		_activate_level(next_index)
	else:
		print("🎉 All levels complete!")
