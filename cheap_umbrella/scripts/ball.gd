extends RigidBody2D

@export var spawn_delay := 1.0
@export var bounce_cooldown := 0.08 # in seconds
@export var min_bounce_velocity := 85.0

var spawn_position: Vector2
var is_respawning := false
var last_bounce_time := 0.0

@onready var trail = $Trail
@onready var bounce_sfx = $BounceSFX

var is_held := false

func _ready():
	spawn_position = global_position
	contact_monitor = true
	max_contacts_reported = 8
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	# Only play sound if cooldown has elapsed
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_bounce_time < bounce_cooldown:
		return
	last_bounce_time = now

	var velocity = linear_velocity.length()
	if velocity > min_bounce_velocity:
		var t = min(velocity / 1200.0, 1.0)
		bounce_sfx.volume_db = lerp(-24, 6, t)
		bounce_sfx.pitch_scale = lerp(0.8, 1.2, t)
		bounce_sfx.play()

func respawn():
	if is_respawning:
		return
	is_respawning = true
	visible = false

	await get_tree().create_timer(spawn_delay).timeout

	global_position = spawn_position
	visible = true
	is_respawning = false

func freeze_ball(state: bool):
	freeze = state  # Godot 4 property for RigidBody2D
	if state and bounce_sfx.playing:
		bounce_sfx.stop()

func apply_throw(force: Vector2, torque: float = 0.0):
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	apply_central_impulse(force)
	apply_torque_impulse(torque)
