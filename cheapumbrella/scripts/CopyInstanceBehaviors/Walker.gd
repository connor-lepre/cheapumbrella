extends CharacterBody2D

@export var walk_speed := 100
var direction := 1

@onready var top_check: Area2D = $AboveChecker

func _ready():
	if top_check:
		top_check.body_entered.connect(_on_top_check_body_entered)

func _physics_process(delta):
	velocity.y += 4800 * delta
	velocity = Vector2(walk_speed * direction, self.velocity.y / 4800 * delta)
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if abs(col.get_normal().x) > 0.7:
			direction *= -1
			break

func _on_top_check_body_entered(body):
	if body.is_in_group("Player"):
		if body.velocity.y > 0:
			queue_free()
