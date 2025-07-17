extends Node2D

@onready var rim_check = $Goal/RimCheck
@onready var net_check = $Goal/NetCheck
@onready var score_fx = $ScoreFX
@onready var first_score_fx = $FirstScoreFX
var first_score := false
signal ball_scored

var balls_in_rim := {}

func _ready():
	rim_check.body_entered.connect(_on_rim_check_entered)
	rim_check.body_exited.connect(_on_rim_check_exited)
	net_check.body_entered.connect(_on_net_check_entered)

func _on_rim_check_entered(body):
	if body.is_in_group("ball") and body.linear_velocity.y > 0:
		balls_in_rim[body.get_instance_id()] = true
		print("Body in rim check:", body)

func _on_rim_check_exited(body):
	var id = body.get_instance_id()
	if id in balls_in_rim:
		balls_in_rim.erase(id)

func _on_net_check_entered(body):
	var id = body.get_instance_id()
	if id in balls_in_rim and body.linear_velocity.y > 0:
		emit_signal("ball_scored", body)
		if not first_score:
			first_score_fx.visible = true
			first_score_fx.emitting = false
			first_score = true
			print("First score on this net")
		print("ball scored")
		if score_fx:
			score_fx.emitting = false
			score_fx.emitting = true
		balls_in_rim.erase(id)
