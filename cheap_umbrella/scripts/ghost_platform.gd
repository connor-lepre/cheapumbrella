extends CharacterBody2D

var path: Array = []
var current_index := 0
var direction := 1
var move_speed := 200.0

func set_path(p: Array):
	if p.size() < 2:
		queue_free()
		return
	path = p.duplicate()
	global_position = path[0]

func _physics_process(delta):
	if path.size() < 2:
		return

	var target = path[current_index]
	var move_vec = (target - global_position).normalized() * move_speed
	velocity = move_vec
	move_and_slide()

	if global_position.distance_to(target) < 2.0:
		current_index += direction
		if current_index >= path.size():
			current_index = path.size() - 1
			direction = -1
		elif current_index < 0:
			current_index = 0
			direction = 1
