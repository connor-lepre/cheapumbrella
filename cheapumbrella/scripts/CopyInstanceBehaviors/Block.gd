extends CharacterBody2D

var game_mgr = GameManager

func _ready():
	pass

func _physics_process(delta):
	velocity.y += 4800 * delta
	move_and_slide()

func _on_above_checker_body_entered(body):
	if body.is_in_group("Player"):
		queue_free()
		game_mgr.remaining_copy_energy + 1
