extends BaseSkeleton

var is_attacking: bool = false

func _process_behavior(delta: float):
	if is_attacking:
		return
	if anim_tree and anim_tree.get_current_node() != "Walk":
		return

	var _parent = get_parent()
	if _parent is PathFollow3D:
		_parent.progress += move_speed * delta
		
		if _parent.progress_ratio >= 1.0:
			_attack()
			
			
func _attack():
	is_attacking = true
	
	anim_tree.travel("Attack")
	await get_tree().create_timer(1.0).timeout
	
	is_attacking = false
	_deal_damage()
	
func _deal_damage():
	SignalBus.change_health.emit(-1, self)
	
