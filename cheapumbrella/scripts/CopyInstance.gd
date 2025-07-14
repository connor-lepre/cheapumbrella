extends CharacterBody2D

signal copy_removed(cost: int)

var type_name: String
var type_data: Dictionary
var copy_cost: int = 1
var behavior: String = ""
var land_count: int = 0
var jump_cooldown: float = 0.0
var direction: int = 1

@onready var collider: CollisionShape2D = $CopyCollider
@onready var sprite: Sprite2D = $CopySprite
@onready var above_checker: Area2D = $AboveChecker

func setup(name: String, data: Dictionary) -> void:
    type_name = name
    type_data = data
    copy_cost = data.get("copy cost", 1)
    behavior = data.get("behavior", "")
    var dims: Vector2 = data.get("dimensions", Vector2(32,32))
    if collider and collider.shape is RectangleShape2D:
        var rect: RectangleShape2D = collider.shape
        rect.size = dims
        collider.shape = rect
    if sprite:
        if sprite.texture:
            sprite.scale = dims / 32.0
    if above_checker and above_checker.get_node("AboveShape"):
        var rect2 := above_checker.get_node("AboveShape").shape
        if rect2 is RectangleShape2D:
            rect2.size.x = dims.x
            above_checker.get_node("AboveShape").shape = rect2

func _ready() -> void:
    add_to_group("Copy")
    collision_layer = 2
    collision_mask = 1 | 4
    if above_checker:
        above_checker.body_entered.connect(_on_above)

func _physics_process(delta: float) -> void:
    if behavior == "walker":
        velocity.x = 100 * direction
        velocity.y += 2400 * delta
        self.velocity = velocity
        move_and_slide()
        if is_on_wall():
            direction *= -1
    elif behavior == "jumper":
        velocity.y += 2400 * delta
        if is_on_floor():
            if jump_cooldown <= 0.0:
                velocity.y = -800
                jump_cooldown = 2.0
        jump_cooldown = max(jump_cooldown - delta, 0.0)
        self.velocity = velocity
        move_and_slide()
    else:
        velocity.y += 2400 * delta
        self.velocity = velocity
        move_and_slide()

func _on_above(body: Node) -> void:
    if not body.is_in_group("Player"):
        return
    if body.velocity.y <= 0:
        return
    land_count += 1
    if land_count >= 3:
        emit_signal("copy_removed", copy_cost)
        queue_free()
