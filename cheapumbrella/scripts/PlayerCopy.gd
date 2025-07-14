extends CharacterBody2D

@export var speed: float = 200.0
@export var max_distance: float = 160.0

var _direction: Vector2
var _distance: float = 0.0
var _moving := false
var _forward := true
var _start_pos: Vector2

@onready var _sprite: Sprite2D = $CopySprite
@onready var _collider: CollisionShape2D = $CopyCollider

func init_copy(start_pos: Vector2, direction: Vector2) -> void:
	global_position = start_pos
	_direction = direction.normalized()
	_distance = 0.0
	_forward = true
	_start_pos = start_pos
	_moving = true
	add_to_group("Copy")
	collision_layer = 2
	collision_mask = 4

func _physics_process(delta: float) -> void:
	if not _moving:
		return

	var step := speed * delta
	var travel = min(step, max_distance - _distance)
	var motion = _direction * (travel if _forward else -travel)
	var collision := move_and_collide(motion)
	_distance += travel

	if collision or _distance >= max_distance:
		_forward = not _forward
		_distance = 0.0
		
		# Optionally, snap to exact endpoints:
		# if _forward:
		#     global_position = _start_pos
		# else:
		#     global_position = _start_pos + _direction * max_distance
