extends Control

@onready var bar_fill = $MeterFill

var power := 0.0  # Value from 0.0 to 1.0

func set_power(val: float):
	power = clamp(val, 0.0, 1.0)
	bar_fill.size.y = $MeterBG.size.y * power
