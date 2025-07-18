extends ParallaxBackground

@export var start_time_sec := 120  # 2:00 in seconds
var time_left := 0.0
var player_score := 0

@onready var shotclock = $ParallaxLayer/Timer
@onready var score = $ParallaxLayer/Score

func _ready():
	time_left = start_time_sec
	update_shotclock()

	var baskets_node = get_parent().get_node("Baskets")
	for basket in baskets_node.get_children():
		if basket.has_signal("ball_scored"):
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
	score.text = "Score:%d" % [player_score]
