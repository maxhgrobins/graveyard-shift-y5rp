extends BaseSkeleton


func _process_behavior(delta: float):
	if anim_tree and anim_tree.get_current_node() != "Walk":
		return

	var _parent = get_parent()
	if _parent is PathFollow3D:
		_parent.progress += move_speed * delta
