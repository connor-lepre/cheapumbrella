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

var kgMass = 1.0

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

@onready var sprite = $Sprite2D

func set_path(p: Array):
	if p.size() < 2:
		queue_free()
		return
	path = p.duplicate()
	global_position = path[0][0]
	previous_position = path[0][0]

func _physics_process(delta):
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
	global_position = frame_pos
	_set_sprite_facing(frame_facing)
	collision_with_RigidBody2d()

	frame_index += direction
	if frame_index >= path.size():
		frame_index = path.size() - 2
		direction = -1
	elif frame_index < 0:
		frame_index = 1
		direction = 1

func _set_sprite_facing(facing):
	if facing == Vector2.RIGHT:
		sprite.flip_h = true
	if facing == Vector2.LEFT:
		sprite.flip_h = false

func collision_with_RigidBody2d():
	for i in get_slide_collision_count():
		var c: KinematicCollision2D = get_slide_collision(i)
		var rigid: RigidBody2D = c.get_collider() if c.get_collider() is RigidBody2D else null
		if rigid:
			var pushDir = -c.get_normal()
			var diffVelInPushDir: float = max(0.0, velocity.dot(pushDir) - rigid.linear_velocity.dot(pushDir))
			var massRatio: float = min(1.0, kgMass / rigid.mass)
			var pushForce: float = massRatio * 5.0
			# rigid.apply_impulse(pushDir * diffVelInPushDir * pushForce, c.get_position() - rigid.position) 
			var impulseAmt = pushDir * diffVelInPushDir * pushForce
			rigid.apply_central_impulse(impulseAmt)
