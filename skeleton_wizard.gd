extends BaseSkeleton

@export var magic_projectile : PackedScene
@export var cast_interval : float = 6.0

func _ready():
	super()
	var _cast_timer = Timer.new()
	_cast_timer.wait_time = cast_interval
	_cast_timer.timeout.connect(_cast_spell)
	add_child(_cast_timer)
	_cast_timer.start()


func _process_behavior(_delta: float):
	look_at_player()


func _cast_spell():
	if is_dead or is_downed or not target_player: return
	
	if anim_tree: anim_tree.travel("Cast_Spell")
	
	var _target = target_player.global_position
	_target.y = 0
	
	await get_tree().create_timer(1.0).timeout
	if is_dead or is_downed: return
	
	var _projectile = magic_projectile.instantiate()
	get_tree().root.add_child(_projectile)
	_projectile.global_position = _target
	
	# Note: Your magic_beam_scene should probably have an internal AnimationPlayer 
	# that plays a 1-second "warning circle" animation before actually turning on its damage hitbox.
