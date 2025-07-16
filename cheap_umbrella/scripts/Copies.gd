extends "res://scripts/player.gd"

var tick := 0
const FRAME_SPEED := 1
const PHYSICS_FPS := 60.0
var frame_index := 0
var direction := 1
var path: Array = []
var previous_position := Vector2.ZERO
var estimated_velocity := Vector2.ZERO

func set_path(p: Array):
	if p.size() < 2:
		queue_free()
		return
	path = p.duplicate()
	global_position = path[0][0]
	previous_position = path[0][0]

func _physics_process(delta):
	_update_from_path(delta)
	
func _update_from_path(delta):
	if path.size() < 2:
		return
	tick += 1
	if tick < FRAME_SPEED:
		return
	tick = 0

	# Estimate velocity
	estimated_velocity = (path[frame_index][0] - previous_position) * PHYSICS_FPS
	previous_position = global_position

	var frame_pos = path[frame_index][0]
	var frame_facing = path[frame_index][1]
	var frame_is_moving = path[frame_index][2]
	var frame_is_jumping = path[frame_index][3]
	var frame_is_gliding = path[frame_index][4]

	global_position = frame_pos
	
	sprite_flip(frame_facing)
	sprite_anim_switch(frame_is_gliding, frame_is_moving, frame_is_jumping)
	hide_show_umbrella(frame_is_gliding)
	
	collision_with_RigidBody2d()

	frame_index += direction
	if frame_index >= path.size():
		frame_index = path.size() - 2
		direction = -1
	elif frame_index < 0:
		frame_index = 1
		direction = 1
