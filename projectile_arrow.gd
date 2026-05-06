extends ProjectileBase

func _ready():
	SignalBus.in_shop.connect(_clear)

func _clear():
	queue_free()


func _process_visuals(_delta):
	$Sprite3D.visible = is_flying

	# arrow arc
	if velocity.length() > 0.1 and is_flying:
		# prevent colinearity warning from clogging debugger
		if not velocity.normalized().is_equal_approx(Vector3.UP) and not velocity.normalized().is_equal_approx(Vector3.DOWN):
			look_at(global_position + velocity, Vector3.UP)


func _process_movement(delta: float):
	velocity.y -= 9.8 * delta
	super(delta)
	
	
func _on_impact(result):
	# TODO test this - moved out of after impact cos reparenting was happening after detatch head
	reparent(result.collider, true)
	
	super(result)

func _after_impact(_collider: Object):
	is_flying = false
	$Sprite3D.hide()
	set_physics_process(false)
	

func _apply_damage(hurtbox):
	var _damage = GameStats.get_damage()
	if hurtbox.zone == HitData.Zone.HEAD:
		_damage = _damage * GameStats.crit_mult
		
	print("DAMAGE ", _damage)
	hurtbox.health_component.take_damage(_damage, hurtbox.zone, velocity)
