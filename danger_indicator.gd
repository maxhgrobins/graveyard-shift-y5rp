extends Node3D

@onready var camera = get_parent()

func _process(_delta):
	var _targets = get_tree().get_nodes_in_group("enemy")
	if _targets.is_empty():
		visible = false
		return
	
	var _closest_target = _targets[0]
	var _lowest_dist = global_position.distance_to(_closest_target.global_position)
	
	for _target in _targets:
		var _distance = global_position.distance_to(_target.global_position)
		if _distance < _lowest_dist:
			_lowest_dist = _distance
			_closest_target = _target

	# if behind
	var _to_target = (_closest_target.global_position - camera.global_position).normalized()
	var _dot = -camera.global_transform.basis.z.dot(_to_target)

	if _dot < 0.7:
		visible = true
		
		var _local_target = camera.global_transform.affine_inverse() * _closest_target.global_position
		var _direction = Vector2(_local_target.x, _local_target.y).normalized()
		
		var _radius = 0.5
		position.x = _direction.x * _radius
		position.y = _direction.y * _radius
		position.z = -1.0
		
		rotation.z = _direction.angle() + (PI / 2.0)
	else:
		visible = false
		
	
