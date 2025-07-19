extends Node

signal level_completed
signal win_triggered
signal lose_triggered

const THROW_METER_SCENE = preload("res://Scenes/UI/ThrowMeter.tscn")
const AVAILABLE_COPIES_SCENE = preload("res://Scenes/UI/AvailableCopies.tscn")

var level_scenes := [
	preload("res://Scenes/Levels/Level0.tscn"),
	preload("res://Scenes/Levels/Level1.tscn"),
	preload("res://Scenes/Levels/Level2.tscn"),
	preload("res://Scenes/Levels/Level3.tscn"),
	preload("res://Scenes/Levels/Level4.tscn"),
	preload("res://Scenes/Levels/Level5.tscn"),
	# New levels here
	
	
	# Don't put levels below these two
	preload("res://Scenes/Levels/LevelWin.tscn"),
	preload("res://Scenes/Levels/LevelLose.tscn")
]

var current_level: Node = null
var current_index: int = -1

# Set lose and win index at the class level
var lose_index := level_scenes.size() - 1
var win_index := level_scenes.size() - 2

func _ready():
	next_level()  # Start at Level 0

func _activate_level(index: int) -> void:
	if current_level:
		var to_free = current_level
		current_level = null
		to_free.queue_free()

	# Reset timer for first playable level
	if index == 0:
		GlobalTimer.reset()

	var new_level = level_scenes[index].instantiate()
	print("Instantiated level:", new_level, "Script is:", new_level.get_script())

	if new_level.has_signal("timer_zero"):
		new_level.connect("timer_zero", Callable(self, "_on_level_timer_zero"))
	else:
		print("No timer_zero signal found on new_level! Its script is:", new_level.get_script())

	# Reset timer guard before adding the level to the scene tree
	if "timer_already_zero" in new_level:
		new_level.timer_already_zero = false
		print("Set timer_already_zero to", new_level.timer_already_zero)

	add_child(new_level)

	var player = new_level.get_node_or_null("Player")
	
	# THROW METER
	var throw_meter = THROW_METER_SCENE.instantiate()
	throw_meter.name = "ThrowMeter"
	new_level.add_child(throw_meter)
	throw_meter.position = Vector2(-975.0, 1044.0)
	throw_meter.set_power(0.0)
	
	# AVAILABLE COPIES
	var available_copies_ui = AVAILABLE_COPIES_SCENE.instantiate()
	available_copies_ui.name = "AvailableCopies"
	new_level.add_child(available_copies_ui)
	available_copies_ui.position = Vector2(600.0, 918)
	
	# Assign UI refs to player if player exists
	if player:
		player.throw_meter = throw_meter
		player.copies_ui = available_copies_ui
		player.update_copy_ui()
		print("Assigned throw_meter and available_copies to player:", throw_meter, available_copies_ui)
	
	new_level.set_is_current(true)
	current_level = new_level
	current_index = index
	GlobalTimer.paused = false

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
	if current_index == win_index:
		emit_signal("win_triggered")
		get_tree().quit()
	elif current_index == lose_index:
		GlobalTimer.reset()
		call_deferred("_activate_level", -1)
		return

func goto_level(index: int) -> void:
	if index >= 0 and index < level_scenes.size():
		call_deferred("_activate_level", index)

func next_level() -> void:
	GlobalTimer.paused = true
	var next_index = current_index + 1
	if next_index < level_scenes.size():
		call_deferred("_activate_level", next_index)
	else:
		print("🎉 All levels complete!")
		GlobalTimer.paused = true
		
func _on_level_timer_zero():
	print("LevelManager: Timer hit zero, loading lose scene")
	emit_signal("lose_triggered")
	call_deferred("_activate_level", lose_index)
