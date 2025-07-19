extends Node2D

enum GoalType { STANDARD, TEMPORARY, REQUIRED }
@export var goal_type: GoalType = GoalType.STANDARD
@export var is_required: bool = false # Optional, for clarity in editor
signal required_goal_scored

@onready var rim_check = $Goal/RimCheck
@onready var net_check = $Goal/NetCheck
@onready var rim_bounce_check = $Rim/RimSoundArea
@onready var backboard_check = $Backboard/BackboardSoundArea
@onready var score_fx = $ScoreFX
@onready var first_score_fx = $FirstScoreFX

# Audio nodes
@onready var rim_sfx = $SFX/RimSFX
@onready var backboard_sfx = $SFX/BackboardSFX
@onready var net_sfx = $SFX/NetSFX
@onready var score_sfx = $SFX/ScoreSFX
@onready var score_part_sfx = $SFX/ScorePartSFX

@onready var checkpoint_scene = preload("res://Scenes/Checkpoint.tscn")
var first_score := false
signal ball_scored

var balls_in_rim := {}

func _ready():
	add_to_group("goals")  # for level manager
	rim_check.body_entered.connect(_on_rim_check_entered)
	rim_check.body_exited.connect(_on_rim_check_exited)
	net_check.body_entered.connect(_on_net_check_entered)
	rim_bounce_check.body_entered.connect(_on_rim_bounce_check_entered)
	backboard_check.body_entered.connect(_on_backboard_check_entered)

func _on_rim_check_entered(body):
	if body.is_in_group("ball") and body.linear_velocity.y > 0:
		balls_in_rim[body.get_instance_id()] = true
		print("Body in rim check:", body)

func _on_rim_check_exited(body):
	var id = body.get_instance_id()
	if id in balls_in_rim:
		balls_in_rim.erase(id)

func _on_rim_bounce_check_entered(body):
	if body.is_in_group("ball") and body.linear_velocity.length() > 0:
		print("Rim bounce")
		rim_sfx.play()
		
func _on_backboard_check_entered(body):
	if body.is_in_group("ball") and body.linear_velocity.length() > 0:
		print("Backboard bounce")
		backboard_sfx.play()

func _on_net_check_entered(body):
	var id = body.get_instance_id()
	if id in balls_in_rim and body.linear_velocity.y > 0:
		emit_signal("ball_scored", body)
		score_sfx.play()
		net_sfx.play()

		# First-score FX and hiding
		if not first_score:
			if first_score_fx:
				first_score_fx.visible = true
				first_score_fx.emitting = false
			first_score = true
			print("First score on this net")

		# Regular score FX
		if score_fx:
			score_fx.emitting = false
			score_fx.emitting = true
			score_part_sfx.play()

		# Handle Goal Type
		match goal_type:
			GoalType.STANDARD:
				# Do nothing extra, keep basket
				pass
			GoalType.TEMPORARY:
				# Disable further scoring/collisions
				$Goal.set_deferred("monitoring", false)
				# Play FX, then delete after short delay (or wait for signal if you prefer)
				await get_tree().create_timer(0.6).timeout  # Tune delay to your FX duration
				queue_free()
			GoalType.REQUIRED:
				is_required = false
				emit_signal("required_goal_scored", self)
				# Spawn checkpoint here
				var checkpoint = checkpoint_scene.instantiate()
				checkpoint.global_position = global_position + Vector2(0, -64) # Adjust as needed
				get_tree().current_scene.add_child(checkpoint)

		balls_in_rim.erase(id)
