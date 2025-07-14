extends Line2D

var _points: Array[Vector2] = []

func _ready() -> void:
	visible = false

func _draw() -> void:
	if _points.size() < 2:
		return
	draw_line(_points[0], _points[1], Color.CYAN, 2.0)
