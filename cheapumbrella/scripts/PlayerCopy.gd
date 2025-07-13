extends CharacterBody2D

var speed: float = 200.0
var _direction: int = 1
var _progress: float = 0.0
var _length: float = 0.0
var _base_position: Vector2

@onready var _path: Path2D = $CopyPath
@onready var _follow: PathFollow2D = $CopyPath/CopyPathFollow
@onready var _sprite: Sprite2D = $CopySprite

func _ready() -> void:
	if _path == null:
		push_error("CopyPath node missing")
	if _follow == null:
		push_error("CopyPathFollow node missing")
	if _sprite == null:
		push_error("CopySprite node missing")

func init_copy(base_position: Vector2, rel_points: Array) -> void:
	_base_position = base_position
	global_position = base_position
	if _path == null or _follow == null or _sprite == null:
		push_error("Copy nodes missing; cannot initialize")
		return
	_path.curve.clear_points()
	for p in rel_points:
		_path.curve.add_point(p)
	_length = _path.curve.get_baked_length()
	_follow.progress = 0.0
	_sprite.modulate.a = 0.6

func _physics_process(delta: float) -> void:
	if _length <= 0 or _path == null or _follow == null:
		return
	_progress += speed * delta * _direction
	if _progress > _length:
		_progress = _length
		_direction = -1
	elif _progress < 0:
		_progress = 0
		_direction = 1
	_follow.progress = _progress
	var target := _base_position + _follow.position
	velocity = (target - global_position) / delta
	move_and_slide()
