var copy_types = {
	"Block": {
		"dimensions": Vector2(64, 64),
		#"sprite": "res://path/to/block_sprite.png",
		"behavior": "platform",
		"copy cost": 1
	},
	"Platform": {
		"dimensions": Vector2(128, 64),
		#"sprite": "res://path/to/platform_sprite.png",
		"behavior": "platform",
		"copy cost": 1
	},
	"Walker": {
		"dimensions": Vector2(64, 64),
		#"sprite": "res://path/to/walker_sprite.png",
		"behavior": "walker",
		"copy cost": 1
	},
	"Jumper": {
		"dimensions": Vector2(64, 64),
		#"sprite": "res://path/to/jumper_sprite.png",
		"behavior": "jumper",
		"copy cost": 1
	}
}
