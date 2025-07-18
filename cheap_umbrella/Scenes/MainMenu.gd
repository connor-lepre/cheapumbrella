extends Control

@onready var buttons = $MenuLayer/VBoxContainer/Buttons
@onready var start_game_button = $MenuLayer/VBoxContainer/Buttons/Start
var menu_focus_set := false

@onready var wordmark = $MenuLayer/VBoxContainer/VBoxContainer/Logo/Wordmark
@onready var top_sprite = $MenuLayer/VBoxContainer/VBoxContainer/Logo/SpriteTop
@onready var bottom_sprite = $MenuLayer/VBoxContainer/VBoxContainer/Logo/SpriteBottom

@onready var hooplicate_sfx = $Hooplicate

@onready var screen_width = get_viewport_rect().size.x

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

func _ready():
	 # Set all positions off-screen (to the left)
	wordmark.position.x = -wordmark.size.x
	top_sprite.position.x = top_sprite.size.x + screen_width
	bottom_sprite.position.x = bottom_sprite.size.x + screen_width

	var tween = create_tween()
	tween.tween_property(wordmark, "position:x", 0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(top_sprite, "position:x", 900, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(bottom_sprite, "position:x", 980, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	hooplicate_sfx.play()

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scenes/Sandbox.tscn")


func _on_tutorial_pressed():
	pass # Nothing for now


func _on_quit_pressed():
	get_tree().quit()
