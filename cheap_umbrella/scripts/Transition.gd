extends ColorRect

func _ready():
	visible = true
	modulate.a = 0.0

func fade_in(duration := 0.3):
	self.visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, duration)
	await tween.finished

func fade_out(duration := 0.3):
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	await tween.finished
	self.visible = false
