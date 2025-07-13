extends Node2D

var _points: Array[Vector2] = []

func _ready() -> void:
	visible = false

func _draw() -> void:
	if _points.size() == 0:
		return
	draw_polyline(_points, Color.WHITE)
	for p in _points:
		draw_circle(p, 4.0, Color.YELLOW)

func set_points(points: Array[Vector2]) -> void:
	_points = points.duplicate()
	queue_redraw()
