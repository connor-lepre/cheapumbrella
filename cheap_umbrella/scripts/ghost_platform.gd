extends CharacterBody2D

@export var push_multiplier_x := 50
@export var push_multiplier_y := 200
var launched_objects := {}  # Track what we've already launched
var path: Array = []
var frame_index := 0
var direction := 1
var move_speed := 200.0
var tick := 0
const FRAME_SPEED := 1
const PHYSICS_FPS := 60.0

var previous_position := Vector2.ZERO
var estimated_velocity := Vector2.ZERO

var raw_push_force = Vector2(
	estimated_velocity.x * push_multiplier_x,
	estimated_velocity.y * push_multiplier_y
)

# Cap upward push (positive Y) more than horizontal
var push_force = Vector2(
	raw_push_force.x,
	clamp(raw_push_force.y, -100, 50)  # Limit upward force especially
)


func set_path(p: Array):
	if p.size() < 2:
		queue_free()
		return
	path = p.duplicate()
	global_position = path[0]
	previous_position = path[0]

func _physics_process(delta):
	if path.size() < 2:
		return

	tick += 1
	if tick < FRAME_SPEED:
		return
	tick = 0

	# Estimate velocity
	estimated_velocity = (path[frame_index] - previous_position) * PHYSICS_FPS
	previous_position = global_position

	global_position = path[frame_index]
	push_objects()

	frame_index += direction
	if frame_index >= path.size():
		frame_index = path.size() - 2
		direction = -1
	elif frame_index < 0:
		frame_index = 1
		direction = 1

func push_objects():
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		if collider and collider.has_method("add_external_velocity"):
			# Check if we've already launched this object recently
			var object_id = collider.get_instance_id()
			if object_id in launched_objects:
				continue  # Skip if already launched this frame cycle
			
			var raw_push_force = Vector2(
				estimated_velocity.x * push_multiplier_x,
				estimated_velocity.y * push_multiplier_y
			)
			
			# Special handling for upward launches
			var push_force = Vector2.ZERO
			if estimated_velocity.y < -50:  # Ghost moving upward significantly
				# Give one big launch kick and then remember we launched it
				push_force = Vector2(
					raw_push_force.x,
					raw_push_force.y  # Don't clamp upward launches
				)
				launched_objects[object_id] = true  # Mark as launched
				print("🚀 Ghost launching with force: ", push_force)
			else:
				# Normal pushing for other directions
				push_force = Vector2(
					raw_push_force.x,
					clamp(raw_push_force.y, -200, 200)
				)
			
			if abs(normal.x) > 0.7 or abs(normal.y) > 0.7:
				collider.add_external_velocity(push_force, 1.2)  # Even higher multiplier for instant kick
