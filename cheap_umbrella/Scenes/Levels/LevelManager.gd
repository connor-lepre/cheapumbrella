extends Node

var levels = []
var current_index = 0

func _ready():
	# Collect all Level children
	for child in get_children():
		if child.name.begins_with("Level"):  # Only add Level nodes
			levels.append(child)
	print("Levels collected:", levels.size())

	# Deactivate all levels at startup
	for level in levels:
		if "is_current" in level:
			level.is_current = false
		else:
			level.set_process(false)
			level.set_physics_process(false)
			level.visible = false

	# Activate first level
	_activate_level(0)

func _activate_level(index):
	for i in range(levels.size()):
		if "set_is_current" in levels[i]:
			levels[i].set_is_current(i == index)
		else:
			levels[i].set_process(i == index)
			levels[i].set_physics_process(i == index)
			levels[i].visible = (i == index)

	# Connect to goal signal in current level
	var basket = levels[index].get_node_or_null("Basket")
	if basket:
		var goal = basket.get_node_or_null("Goal")
		if goal:
			if goal.has_signal("ball_scored"):
				goal.connect("ball_scored", _on_goal_scored, [], CONNECT_ONE_SHOT)
			if goal.has_signal("required_goal_scored"):
				goal.connect("required_goal_scored", _on_goal_scored, [], CONNECT_ONE_SHOT)
		else:
			print("⚠️ No Goal node found in Basket!")
	else:
		print("⚠️ No Basket found in current level!")

	current_index = index

func _on_goal_scored(_data = null):
	var next_index = current_index + 1
	if next_index < levels.size():
		_activate_level(next_index)
	else:
		print("🎉 All levels complete!")
