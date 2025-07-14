extends CharacterBody2D

var speed: float = 200.0

var _direction: int = 1
var _segment_index: int = 0
var _segment_t: float = 0.0

var _segment_time: float = 0.1
var _points: Array[Vector2] = []
var _total_distance: float = 0.0
var _base_position: Vector2
var _initialized: bool = false


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
	add_to_group("Copy")
	collision_layer = 2
	collision_mask = 1



func _has_valid_path() -> bool:
	if _path == null or _follow == null:
		push_error("Copy path nodes missing")
		return false
	if _points.size() < 2:
		push_warning("PlayerCopy has invalid path")
		return false
	return true


func init_copy(base_position: Vector2, rel_points: Array) -> void:
	if _initialized:
		push_warning("PlayerCopy already initialized")
		return
	if rel_points.size() < 2:
		push_warning("Copy path requires at least 2 points")
		return
	
	_base_position = base_position
	global_position = base_position

	if _path == null or _follow == null or _sprite == null:
		push_error("Copy nodes missing; cannot initialize")
		return

	# store relative points and create a NEW Curve2D for this copy
	_points.clear()
	for p in rel_points:
		_points.append(p)
	var curve = Curve2D.new()
	for p in _points:
		curve.add_point(p)
	_path.curve = curve

	_total_distance = 0.0
	for i in range(_points.size() - 1):
		_total_distance += _points[i].distance_to(_points[i + 1])
	if _total_distance <= 0.0:
		push_warning("Invalid copy path length")
		_path.curve.clear_points()
		return

	_segment_index = 0
	_segment_t = 0.0
	_direction = 1

	var num_segments := _points.size() - 1
	_segment_time = (_total_distance / speed) / num_segments
	if _segment_time <= 0.0:
		_segment_time = 0.01

	_follow.progress = 0.0
	_sprite.modulate.a = 0.6
	_initialized = true



func _physics_process(delta: float) -> void:
	if not _initialized or not _has_valid_path():
		return

	var time_left := delta
	while time_left > 0.0:
		var remaining := _segment_time * (1.0 - _segment_t)
		var step = min(time_left, remaining)
		_segment_t += step / _segment_time
		time_left -= step

		if _segment_t >= 1.0:
			_segment_t -= 1.0
			_segment_index += _direction

			if _segment_index + _direction >= _points.size() or _segment_index + _direction < 0:
				_direction *= -1
				if _segment_index + _direction < 0:
					_segment_index = 0
				elif _segment_index + _direction >= _points.size():
					_segment_index = _points.size() - 2

	var start := _points[_segment_index]
	var finish := _points[_segment_index + _direction]
	var local_pos := start.lerp(finish, _segment_t)
	var target := _base_position + local_pos
	var motion := target - global_position

	global_position = target
	velocity = motion / delta

	if _path and _follow:
		var offset = 0.0
		if _path.curve:
			offset = _path.curve.get_closest_offset(local_pos)
		_follow.progress = offset
