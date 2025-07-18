extends Area2D

signal checkpoint_entered(pos: Vector2)

@onready var checkpoint_sprite = $CheckpointSprite  # Make sure this matches your node tree

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if body.has_method("set_checkpoint"):
			# Only play animation if this checkpoint is new
			if body.prev_checkpoint != global_position:
				checkpoint_sprite.play("set")
			body.set_checkpoint(global_position)
			emit_signal("checkpoint_entered", global_position)
