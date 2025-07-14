extends Node2D

var size: Vector2 = Vector2(64, 64)
var valid: bool = true

func _draw() -> void:
    var col := valid ? Color(1,1,1,0.4) : Color(1,0,0,0.4)
    draw_rect(Rect2(-size*0.5, size), col)

func set_valid(v: bool) -> void:
    if valid == v:
        return
    valid = v
    queue_redraw()
