extends Node2D

@onready var level_manager = $LevelManager
@onready var transition = $Transition

func _ready():
	level_manager.connect("level_completed", Callable(self, "_on_level_completed"))

func _on_level_completed(_level_index):
	# 1. Fade in quickly before changing the level
	await transition.fade_in(0.7)  # Fast fade in
	print("Transitioning to next level...")

	# 2. (optional) short wait if you want a pause with black screen
	await get_tree().create_timer(0.1).timeout

	# 3. Switch to next level
	level_manager.next_level()
	print("Next level should be active.")

	# 4. Fade out slowly
	await transition.fade_out(0.7)  # Slower fade out
