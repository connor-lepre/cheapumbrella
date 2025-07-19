extends Node2D

@onready var return_to_menu_btn: Button = $Control/ReturnToMenu
@onready var quit_game_btn: Button = $Control/QuitGame

func _ready():
	return_to_menu_btn.grab_focus()
	return_to_menu_btn.pressed.connect(_on_return_to_menu_pressed)
	quit_game_btn.pressed.connect(_on_quit_game_pressed)

func _on_return_to_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_quit_game_pressed():
	get_tree().quit()
