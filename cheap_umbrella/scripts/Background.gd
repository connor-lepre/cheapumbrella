extends Node2D

@export var start_time_sec := 60  # 2:00 in seconds
var time_left := 0.0
var player_score := 0

@onready var shotclock = $ShotClock/Timer
@onready var score = $ShotClock/Score

func _ready():
	time_left = start_time_sec
	update_shotclock()
	update_score() # Ensure score is correct at start

	# Look for Basket in the scene tree
	var basket = get_parent().get_node("Basket")
	if basket and basket.has_signal("ball_scored"):
		basket.ball_scored.connect(_on_ball_scored)

func _process(delta):
	if time_left > 0:
		time_left -= delta
		time_left = max(time_left, 0)
		update_shotclock()

func update_shotclock():
	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60
	shotclock.text = "%d:%02d" % [minutes, seconds]

func _on_ball_scored(body):
	player_score += 1
	update_score()

func update_score():
	score.text = "Score: %d" % [player_score]
