extends Node2D

@onready var player_scene = preload("res://Scenes/player.tscn")
@onready var spawn_point = $SpawnPoint
@onready var copies = $Copies
@onready var camera = $Camera
@onready var shotclock_timer: Label = $UI/Right/RightPanel/RightPanel/Timer/Shotclock/Timer
signal timer_zero
@onready var timer_already_zero := false
@export var enable_timer := true

@onready var return_to_menu_btn: Button = $UI/Right/RightPanel/RightPanel/NavButtons/ReturnToMenu
var menu_ui_focused := false

var player: Node = null
var is_current: bool = false

func _ready():
	timer_already_zero = false
	print("BaseLevel", self.name, "ready, player at", spawn_point.global_position)
	set_is_current(false)
	player = player_scene.instantiate()
	player.name = "Player"
	player.global_position = spawn_point.global_position
	GlobalTimer.paused = false
	update_shotclock()
	
	return_to_menu_btn.pressed.connect(_on_return_to_menu_pressed)

	if copies:
		player.set("copies_container", copies)

	add_child(player)

	# Ensure visibility matches current state
	set_is_current(is_current)

func _process(delta):
	if not enable_timer:
		return  # Don't run timer logic in non-gameplay scenes

	if not GlobalTimer.paused and GlobalTimer.time_left > 0:
		GlobalTimer.time_left -= delta
		GlobalTimer.time_left = max(GlobalTimer.time_left, 0)
		update_shotclock()
	
	if not timer_already_zero and GlobalTimer.time_left <= 0:
		print("TIMER ZERO: signaling LevelManager")
		timer_already_zero = true
		emit_signal("timer_zero")


func update_shotclock():
	if shotclock_timer:
		var minutes = int(GlobalTimer.time_left) / 60
		var seconds = int(GlobalTimer.time_left) % 60
		shotclock_timer.text = "%d:%02d" % [minutes, seconds]

func set_is_current(value):
	print(self.name, "set_is_current:", value)
	is_current = value
	set_process(is_current)
	set_physics_process(is_current)
	visible = is_current

	# Enable/disable all rigidbodies in this level
	set_all_rigidbodies_enabled(is_current)

	if camera:
		camera.enabled = is_current
	if player:
		player.visible = is_current
		
func set_all_rigidbodies_enabled(state: bool):
	for child in get_children():
		# Check direct children
		if child is RigidBody2D:
			child.freeze = not state
			child.sleeping = not state
		# Check children of children (if you nest)
		for gchild in child.get_children():
			if gchild is RigidBody2D:
				gchild.freeze = not state
				gchild.sleeping = not state
				
func toggle_menu_ui_focus():
	if not menu_ui_focused:
	# Grab focus on Start Over
		return_to_menu_btn.grab_focus()
		menu_ui_focused = true
	else:
	# Release focus from any button
		get_viewport().set_input_as_handled()
		if return_to_menu_btn.has_focus():
			return_to_menu_btn.release_focus()
		menu_ui_focused = false
		
func _on_start_over_pressed():
	# Deactivate this level, go to Level 0, reset timer
	if has_node("/root/LevelManager"):
		GlobalTimer.reset()
		get_parent()._activate_level(0)

func _on_return_to_menu_pressed():
	# Return to menu
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
