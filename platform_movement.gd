extends StaticBody3D

@export var lower_speed : float = 1.0
@export var target_height : float = -5.6

var is_moving = false

func _process(delta):
	if is_moving and global_position.y > target_height:
		global_position.y -= lower_speed * delta
