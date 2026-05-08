extends BaseSkeleton

@export var amplitude : float = 2.0
@export var frequency : float = 3.0

var time_alive : float = 0.0

func _process_behavior(delta: float):
	time_alive += delta
	if not target_player: return

	var _forward_dir = global_position.direction_to(target_player.global_position).normalized()
	var _right_dir = _forward_dir.cross(Vector3.UP).normalized()
	var _weave_offset = _right_dir * sin(time_alive * frequency) * amplitude * delta
	
	global_position += (_forward_dir * move_speed * delta) + _weave_offset
	
	look_at(target_player.global_position, Vector3.UP)
	
	if target_player.global_position.distance_to(global_position) < 1.0:
		SignalBus.change_health.emit(-1, self)

func _knockdown(duration):
	## TODO Decide how to pass this info around properly
	_die(0,0,Vector3.ZERO)
