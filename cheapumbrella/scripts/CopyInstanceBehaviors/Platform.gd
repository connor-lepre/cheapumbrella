extends CharacterBody2D

@onready var top_check: Area2D = $AboveChecker

func _ready():
	if top_check:
		top_check.body_entered.connect(_on_top_check_body_entered)

func _physics_process(delta):
	velocity.y += 4800 * delta
	move_and_slide()

func _on_top_check_body_entered(body):
	if body.is_in_group("Player"):
		if body.velocity.y > 0:
			queue_free()
