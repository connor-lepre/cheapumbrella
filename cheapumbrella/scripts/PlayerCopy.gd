extends CharacterBody2D

const GRAVITY := 4800.0
const THROW_SPEED := 2400.0

enum CopyState { FLYING, LANDED, SHRUNK }
var state: CopyState = CopyState.FLYING

@onready var collider: CollisionShape2D = $CopyCollider
@onready var sprite: Sprite2D = $CopySprite
@onready var above_checker: Area2D = $AboveChecker

var _original_extents := 32.0

func _ready() -> void:
	add_to_group("Copy")
	collision_layer = 2
	collision_mask = 1
	if collider and collider.shape is RectangleShape2D:
		_original_extents = (collider.shape as RectangleShape2D).extents.y
	if above_checker:
		above_checker.body_entered.connect(_on_above_checker_body_entered)

func init_throw(direction: Vector2) -> void:
	velocity = direction.normalized() * THROW_SPEED
	state = CopyState.FLYING

func _physics_process(delta: float) -> void:
	match state:
		CopyState.FLYING:
			velocity.y += GRAVITY * delta
			self.velocity = velocity
			move_and_slide()
			if is_on_floor():
				_land()
		CopyState.LANDED, CopyState.SHRUNK:
			self.velocity = Vector2.ZERO
			move_and_slide()

func _land() -> void:
	state = CopyState.LANDED
	velocity = Vector2.ZERO

func _on_above_checker_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	var player_vel := Vector2.ZERO
	if body.has_property("velocity"):
		player_vel = body.velocity
	if player_vel.y <= 0:
		return
	if state == CopyState.LANDED:
		_shrink()
	elif state == CopyState.SHRUNK:
		queue_free()

func _shrink() -> void:
	state = CopyState.SHRUNK
	if collider and collider.shape is RectangleShape2D:
		var rect: RectangleShape2D = collider.shape
		var old_ext = rect.extents.y
		rect.extents.y *= 0.5
		collider.shape = rect
		global_position.y += old_ext - rect.extents.y
		if above_checker:
			above_checker.position.y = -rect.extents.y
	if sprite:
		sprite.scale.y *= 0.5
