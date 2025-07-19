extends Node2D

@onready var level_manager = $LevelManager
@onready var transition = $Transition

func _ready():
	level_manager.connect("level_completed", Callable(self, "_on_level_completed"))

func _on_level_completed(_level_index):
	await get_tree().create_timer(2.0).timeout
	await transition.fade_in(0.6)
	print("Transitioning to next level...")
	level_manager.next_level()
	print("Next level should be active.")
	await transition.fade_out(0.6)
