extends ParallaxBackground

@export var start_time_sec := 120  # 2:00 in seconds
var time_left := 0.0

@onready var label = $ParallaxLayer/Timer

func _ready():
	time_left = start_time_sec
	update_label()

func _process(delta):
	if time_left > 0:
		time_left -= delta
		time_left = max(time_left, 0)
		update_label()

func update_label():
	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60
	label.text = "%d:%02d" % [minutes, seconds]
