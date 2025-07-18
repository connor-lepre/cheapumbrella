extends Node

@export var base_scene := preload("res://levels/base_scene.tscn")
@export var tutorial_scene := preload("res://Levels/tutorial_two.tscn")

var level_scenes = []
var current_index := 0
var current_scene_instance: Node = null

func _ready():
	level_scenes = [base_scene, tutorial_scene]
	load_scene_by_index(0)

func load_scene_by_index(index):
	if current_scene_instance:
		current_scene_instance.queue_free()

	current_index = index
	current_scene_instance = level_scenes[index].instantiate()
	add_child(current_scene_instance)

	# Wait one frame to ensure scene and its children (like Goal) are ready
	await get_tree().process_frame

	# Find goal node via group
	var goals = get_tree().get_nodes_in_group("goals")
	if goals.is_empty():
		print("⚠️ No goal found in scene!")
		return

	var goal = goals[0]

	# Connect signals from the goal node
	if goal.has_signal("ball_scored"):
		goal.connect("ball_scored", _on_goal_scored)
	if goal.has_signal("required_goal_scored"):
		goal.connect("required_goal_scored", _on_goal_scored)

	print("✅ Connected to goal in scene")

func _on_goal_scored(_data = null):
	print("🎯 Goal scored — advancing scene")
	current_index += 1

	if current_index >= level_scenes.size():
		print("🎉 All levels complete!")
		return

	# Use deferred call to avoid physics flushing errors
	call_deferred("load_scene_by_index", current_index)
