extends Control

@onready var bar_fill = $MeterFill
@onready var stylebox = bar_fill.get("theme_override_styles/panel")

# Color stops (customize these!)
const COLOR_MIN = Color("FFDA6D")
const COLOR_MID = Color("FF9148")
const COLOR_MAX = Color("FF6D91")

var power := 0.0

func _ready():
	power = 0.0

func set_power(val: float):
	power = clamp(val, 0.0, 1.0)
	bar_fill.size.y = $MeterBG.size.y * power
	update_fill_color()

func update_fill_color():
	var col : Color
	if power < 0.5:
		# Interpolate from min (red) to mid (yellow)
		col = COLOR_MIN.lerp(COLOR_MID, power * 2.0)
	else:
		# Interpolate from mid (yellow) to max (green)
		col = COLOR_MID.lerp(COLOR_MAX, (power - 0.5) * 2.0)
	if stylebox:
		stylebox.bg_color = col
