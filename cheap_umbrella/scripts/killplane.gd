extends Area2D

func _ready():
	# Connect the signal for when bodies enter the killplane
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("💀 Something hit the killplane: ", body.name, " (", body.get_class(), ")")
	
	# Unified check for anything with a respawn() method
	if body.has_method("respawn"):
		print("🔄 Respawning: ", body.name)
		body.respawn()
	else:
		print("⚠️ Unknown object hit killplane: ", body.name, " - no respawn method found")
