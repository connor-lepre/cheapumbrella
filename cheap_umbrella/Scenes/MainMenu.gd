extends Control


func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scenes/Sandbox.tscn")


func _on_tutorial_pressed():
	pass # Nothing for now


func _on_quit_pressed():
	get_tree().quit()
