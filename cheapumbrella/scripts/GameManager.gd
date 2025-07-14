extends Node

@export var player_copy_scn: PackedScene

var copies_root: Node2D
var active_copies := 0

@onready var copies_label: Label = $UI/UICanvas/CopiesActive if has_node("UI/UICanvas/CopiesActive") else null

func _ready() -> void:
	copies_root = get_node_or_null("CopiesRoot")
	if copies_root == null:
		push_warning("CopiesRoot node not found")

	if player_copy_scn == null:
		var res = load("res://scenes/PlayerCopy.tscn")
		if res is PackedScene:
			player_copy_scn = res
		else:
			push_error("Failed to load PlayerCopy.tscn")

	var goal = get_node_or_null("Goal")
	if goal:
		if goal.has_signal("body_entered"):
			goal.body_entered.connect(_on_goal_body_entered)
		else:
			push_warning("Goal node missing body_entered signal")
	else:
		push_warning("Goal node not found")

func _process(_delta: float) -> void:
	if copies_label:
		copies_label.text = "Copies active: %d" % active_copies

func _input(event):
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()

func spawn_player_copy(position: Vector2, direction: Vector2) -> void:
        if player_copy_scn == null:
                push_error("Player copy scene not loaded")
                return
        if copies_root == null:
                push_error("CopiesRoot node missing")
                return
        var copy = player_copy_scn.instantiate()
        if copy == null:
                push_error("Failed to instance PlayerCopy")
                return
        copies_root.add_child(copy)
        if copy.has_method("init_throw"):
                copy.global_position = position
                copy.init_throw(direction)
        else:
                push_warning("PlayerCopy missing init_throw method")
        active_copies += 1
        print("Copy spawned at %s" % position)

func _on_goal_body_entered(body: Node) -> void:
	if body and body.name == "Player":
		print("Goal reached!")
