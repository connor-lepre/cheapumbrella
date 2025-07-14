extends Node

const COPY_SCENES = {
	"Block": preload("res://scenes/Block.tscn"),
	"Platform": preload("res://scenes/Platform.tscn"),
	"Walker": preload("res://scenes/Walker.tscn"),
	"Jumper": preload("res://scenes/Jumper.tscn")
}

@export var player_copy_scn: PackedScene

var max_copy_energy: int = 3
var remaining_copy_energy: int

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

func spawn_copy(type_name: String, position: Vector2) -> Node:
	var scene = COPY_SCENES.get(type_name)
	if scene == null:
		push_error("No scene found for copy type: %s" % type_name)
		return null
	if copies_root == null:
		push_error("CopiesRoot node missing")
		return null
	var copy = scene.instantiate()
	copies_root.add_child(copy)
	if copy.has_method("setup"):
		var data_res = preload("res://data/copy_types.gd")
		var d = data_res.copy_types[type_name]
		copy.setup(type_name, d)
	copy.global_position = position
	active_copies += 1
	if copy.has_signal("copy_removed"):
		copy.copy_removed.connect(_on_copy_removed)
	return copy

func _on_copy_removed(_cost: int) -> void:
	active_copies = max(active_copies - 1, 0)

func _on_goal_body_entered(body: Node) -> void:
	if body and body.name == "Player":
		print("Goal reached!")
