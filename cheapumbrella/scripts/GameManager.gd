extends Node

@export var player_copy_scn: PackedScene

var copies_root: Node2D
var active_copies := 0

@onready var copies_label: Label = $UI/UICanvas/CopiesActive if has_node("UI/UICanvas/CopiesActive") else null

func _ready() -> void:
    copies_root = get_node_or_null("CopiesRoot")
    var goal = get_node_or_null("Goal")
    if goal:
        goal.body_entered.connect(_on_goal_body_entered)

func _process(_delta: float) -> void:
    if copies_label:
        copies_label.text = "Copies active: %d" % active_copies

func spawn_player_copy(base_position: Vector2, rel_points: Array) -> void:
    if player_copy_scn == null:
        printerr("Player copy scene missing")
        return
    if copies_root == null:
        printerr("CopiesRoot node missing")
        return
    var copy = player_copy_scn.instantiate()
    copies_root.add_child(copy)
    if copy.has_method("init_copy"):
        copy.init_copy(base_position, rel_points)
    else:
        printerr("PlayerCopy missing init_copy method")
    active_copies += 1
    print("Copy spawned at %s" % base_position)

func _on_goal_body_entered(body: Node) -> void:
    if body.name == "Player":
        print("Goal reached!")
