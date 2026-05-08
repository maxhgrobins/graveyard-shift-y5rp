extends BaseSkeleton

@export var axe_projectile_scene : PackedScene
@export var throw_interval : float = 4.0
@export var throw_force : float = 5.0
@export var vertical_chance : float = 0.5

func _ready() -> void:
	add_to_group("enemy_projectiles")
	super()
	var _throw_timer = Timer.new()
	_throw_timer = Timer.new()
	_throw_timer.wait_time = throw_interval
	_throw_timer.timeout.connect(_on_throw)
	add_child(_throw_timer)
	_throw_timer.start()


func _process_behavior(_delta: float):
	look_at_player()


func _on_throw():
	if is_dead or is_downed or not target_player: return
	
	if anim_tree: anim_tree.travel("Throw")
	
	await get_tree().create_timer(0.85).timeout
	if is_dead or is_downed: return
	
	var _axe : Node3D = axe_projectile_scene.instantiate()
	get_tree().root.add_child(_axe)
	
	_axe.global_position = $ThrowPoint.global_position
	
	##TODO replace magic vector with dynamic height
	# look_at since projectiles move forwards. temp height offset
	var _height_offset : Vector3 = Vector3(0, 0, 0)
	_axe.look_at(target_player.global_position + _height_offset, Vector3.UP)
	
	if randf() < 0.5: 
		_axe.rotate_object_local(Vector3.FORWARD, deg_to_rad(-90))
	
	if _axe.has_method("launch"):
		_axe.shooter_collider = $Rig_Medium/Skeleton3D/HeadAttach/HeadArea
		_axe.launch(throw_force)
		
	_axe.add_to_group("enemy_projectiles")
