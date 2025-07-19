extends Node2D

@onready var level_manager = $LevelManager
@onready var transition = $Transition
@onready var win_sfx = $GlobalAudio/SFX/Win
@onready var lose_sfx = $GlobalAudio/SFX/Lose

var debug_level_index := 0

func _ready():
	level_manager.connect("level_completed", Callable(self, "_on_level_completed"))
	level_manager.connect("win_triggered", Callable(self, "_on_win_triggered"))
	level_manager.connect("lose_triggered", Callable(self, "_on_lose_triggered"))

func _on_win_triggered():
	win_sfx.play()
	print("WIN SFX PLAYED")

func _on_lose_triggered():
	lose_sfx.play()
	print("LOSE SFX PLAYED")

func _input(event):
	if event.is_action_pressed("debug_next_level"):
		debug_level_index += 1
		if debug_level_index >= level_manager.level_scenes.size():
			debug_level_index = 0
		print("Debug: Jumping to level", debug_level_index)
		level_manager.goto_level(debug_level_index)
	elif event.is_action_pressed("debug_prev_level"):
		debug_level_index -= 1
		if debug_level_index < 0:
			debug_level_index = level_manager.level_scenes.size() - 1
		print("Debug: Jumping to level", debug_level_index)
		level_manager.goto_level(debug_level_index)
	if event.is_action_pressed("debug_pause_timer"):
		GlobalTimer.paused = !GlobalTimer.paused
		print("DEBUG: Timer pause toggled. Now paused =", GlobalTimer.paused)

func _on_level_completed(level_index):
	await transition.fade_in(0.7)
	print("Transitioning to next level...")

	# Pause for black screen (optional)
	await get_tree().create_timer(0.1).timeout

	# Determine if Win or Lose
	var win_index = level_manager.win_index
	var lose_index = level_manager.lose_index

	# Next level transition
	level_manager.next_level()
	print("Next level should be active.")

	await transition.fade_out(0.7)
