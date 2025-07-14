## Throwable copy used by the player before placement.
extends CharacterBody2D

const GRAVITY := 2400.0
const THROW_SPEED := 2400.0

enum CopyState { FLYING, LANDED, SHRUNK }
var state: CopyState = CopyState.FLYING

@onready var collider: CollisionShape2D = $CopyCollider
@onready var sprite: Sprite2D = $CopySprite
@onready var above_checker: Area2D = $AboveChecker

var _original_extents := 64.0
var land_grace_time := 0.15 # seconds

func _ready() -> void:
	add_to_group("Copy")
	collision_layer = 2
	collision_mask = 1 | 4
	if collider and collider.shape is RectangleShape2D:
		_original_extents = (collider.shape as RectangleShape2D).extents.y
	if above_checker:
		above_checker.body_entered.connect(_on_above_checker_body_entered)

## Gives the copy an initial velocity as it is thrown by the player.
func init_throw(direction: Vector2) -> void:
	velocity = direction.normalized() * THROW_SPEED
	print("THROW: direction =", direction, " velocity =", velocity)
	state = CopyState.FLYING
	land_grace_time = 0.15

func _physics_process(delta: float) -> void:
	match state:
		CopyState.FLYING:
			velocity.y += GRAVITY * delta
			self.velocity = velocity
			move_and_slide()
			if land_grace_time > 0.0:
				land_grace_time -= delta
			elif is_on_floor():
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
	if "velocity" in body:
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
