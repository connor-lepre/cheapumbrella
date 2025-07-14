extends CharacterBody2D

const RETURN_SPEED := 4.0
var speed: float = 200.0
var _direction: int = 1
var _progress: float = 0.0
var _length: float = 0.0
var _base_position: Vector2
var _initialized: bool = false
var _nudge: float = 0.0
var _width: float = 64.0

@onready var _path: Path2D = $CopyPath
@onready var _follow: PathFollow2D = $CopyPath/CopyPathFollow
@onready var _sprite: Sprite2D = $CopySprite
@onready var _above_checker: Area2D = $AboveChecker


func _ready() -> void:
	if _path == null:
		push_error("CopyPath node missing")
	if _follow == null:
		push_error("CopyPathFollow node missing")
	if _sprite == null:
		push_error("CopySprite node missing")
	if _above_checker == null:
		push_warning("AboveChecker node missing")
	add_to_group("Copy")
	collision_layer = 2
	collision_mask = 1
	var rect = $CopyCollider.shape
	if rect is RectangleShape2D:
		_width = rect.size.x


func _has_valid_path() -> bool:
	if _path == null or _follow == null:
		push_error("Copy path nodes missing")
		return false
	if _length <= 0 or _path.curve.get_point_count() < 2:
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
	_path.curve.clear_points()
	for p in rel_points:
		_path.curve.add_point(p)
	_length = _path.curve.get_baked_length()
	if _length <= 0:
		push_warning("Invalid copy path length")
		_path.curve.clear_points()
		return
	_follow.progress = 0.0
	_progress = 0.0
	_sprite.modulate.a = 0.6
	_nudge = 0.0
	_initialized = true


func _physics_process(delta: float) -> void:
	if not _initialized or not _has_valid_path():
		return

	var step := speed * delta * _direction
	var unclamped := _progress + step
	var hit_end := unclamped < 0.0 or unclamped > _length
	var next_progress = clamp(unclamped, 0.0, _length)

	var next_local := _path.curve.sample_baked(next_progress)
	var base_target := _base_position + next_local

	_update_nudge(base_target, delta)

	var target := base_target + Vector2(_nudge, 0.0)
	var motion := target - global_position

	_progress = next_progress
	_follow.progress = _progress
	global_position = target
	velocity = motion / delta

	if hit_end:
		_direction *= -1


func _update_nudge(base_target: Vector2, delta: float) -> void:
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = $CopyCollider.shape
	params.transform = Transform2D(0.0, base_target + Vector2(_nudge, 0.0))
	var results := get_world_2d().direct_space_state.intersect_shape(params)
	var pushed := false
	for r in results:
		var b = r.collider
		if b and b.is_in_group("Player"):
			pushed = true
			if b.global_position.y > base_target.y:
				if b.has_method("respawn"):
					b.respawn()
			var diff = b.global_position.x - base_target.x
			if abs(diff) > _width:
				queue_free()
				return
			_nudge = clamp(diff, -_width, _width)
			break
	if not pushed:
		_nudge = lerp(_nudge, 0.0, delta * RETURN_SPEED)
