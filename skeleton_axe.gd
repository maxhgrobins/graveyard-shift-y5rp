extends BaseSkeleton

@export var axe_projectile_scene : PackedScene
@export var throw_interval : float = 4.0


func _ready() -> void:
	super()
	var _throw_timer = Timer.new()
	_throw_timer = Timer.new()
	_throw_timer.wait_time = throw_interval
	_throw_timer.timeout.connect(_on_throw)
	add_child(_throw_timer)
	_throw_timer.start()


func _process_behavior(_delta: float):
	print("processing")
	look_at_player()


func _on_throw():
	if is_dead or is_downed or not target_player: return
	
	if anim_tree: anim_tree.travel("Throw")
	
	await get_tree().create_timer(0.5).timeout 
	if is_dead or is_downed: return
	
	var _axe = axe_projectile_scene.instantiate()
	get_tree().root.add_child(_axe) # Spawn into world
	
	## TODO REPLACE WITH DYNAMIC HEIGHT
	_axe.global_position = global_position + Vector3(0, 1.2, 0)
	
	var _throw_dir = global_position.direction_to(target_player.global_position)
	_throw_dir.y = 0
	#if _axe.has_method("launch"):
		#_axe.launch(_throw_dir.normalized())
