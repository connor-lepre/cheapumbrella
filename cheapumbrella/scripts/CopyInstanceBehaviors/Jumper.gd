extends CharacterBody2D

@export var jump_force := -1200
@export var jump_interval := 2.0

var jump_timer := 0.0

func _physics_process(delta):
	jump_timer += delta

	if is_on_floor():
		if jump_timer >= jump_interval:
			velocity.y = jump_force
			jump_timer = 0.0
		else:
			velocity.y = 0  # Prevent "sinking" into the floor
	else:
		velocity.y += 4800 * delta  # Gravity

	move_and_slide()

func _on_above_checker_body_exited(body):
	if body.is_in_group("Player"):
			queue_free()
