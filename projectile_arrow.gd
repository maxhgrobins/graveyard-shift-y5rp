extends ProjectileBase


func _process_visuals(_delta):
	$Sprite3D.visible = is_flying

	# arrow arc
	if velocity.length() > 0.1:
		# prevent colinearity warning from clogging debugger
		if not velocity.normalized().is_equal_approx(Vector3.UP) and not velocity.normalized().is_equal_approx(Vector3.DOWN):
			look_at(global_position + velocity, Vector3.UP)


func _process_movement(delta: float):
	velocity.y -= 9.8 * delta
	super(delta)


func _after_impact(collider: Object):
	$Sprite3D.visible = false
	reparent(collider, true)
	set_physics_process(false)
