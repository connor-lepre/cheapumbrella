extends Node2D

@onready var goal_body = $Goal
@onready var score_fx = $ScoreFX
signal ball_scored
var balls_in_collider = {}

func _ready():
	goal_body.body_entered.connect(_on_goal_body_entered)
	goal_body.body_exited.connect(_on_goal_body_exited)
	
func _on_goal_body_entered(body):
	if body.is_in_group("ball"):
		if body.linear_velocity.y > 0:
			balls_in_collider[body.get_instance_id()] = true

func _on_goal_body_exited(body):
	var id = body.get_instance_id()
	if id in balls_in_collider and balls_in_collider[id]:
		emit_signal("ball_scored", body)
		print("Ball scored")
		score_fx.emitting = false
		score_fx.emitting = true
		balls_in_collider.erase(id)
