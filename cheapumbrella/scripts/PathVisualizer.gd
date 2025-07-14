extends Node2D

var _points: Array[Vector2] = []

func _ready() -> void:
	visible = false

func _draw() -> void:
        if _points.size() < 2:
                return
        draw_line(_points[0], _points[1], Color.CYAN, 2.0)

func set_points(points: Array[Vector2]) -> void:
	_points.clear()
	for p in points:
		_points.append(p)
	queue_redraw()
