extends Control

@onready var buttons = $MenuLayer/VBoxContainer/Buttons
@onready var start_game_button = $MenuLayer/VBoxContainer/Buttons/Start
var menu_focus_set := false

func _unhandled_input(event):
	# Mouse input clears focus
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		menu_focus_set = false
		var focused = get_viewport().gui_get_focus_owner()
		if focused and focused is Button:
			focused.release_focus()
		return

	# Controller input sets focus (joypad axes/buttons)
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not menu_focus_set:
			start_game_button.grab_focus()
			menu_focus_set = true
		return

	# Keyboard input sets focus (arrows, tab, etc.)
	if event is InputEventKey:
		if not menu_focus_set:
			start_game_button.grab_focus()
			menu_focus_set = true
		return


func _on_start_pressed():
	get_tree().change_scene_to_file("res://Levels/LevelManager.tscn")


func _on_tutorial_pressed():
	pass # Nothing for now


func _on_quit_pressed():
	get_tree().quit()
