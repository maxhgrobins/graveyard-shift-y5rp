extends Node3D
class_name BaseSkeleton

@onready var anim_tree : AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var health : HealthComponent = $HealthComponent

@export var skull_gib : PackedScene
@export var move_speed : float = 2.0
@export var down_time : float = 3.0

var target_player : Node3D = null
var is_dead = false
var is_downed = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false
	health.health_depleted.connect(_die)
	health.damaged.connect(_on_damaged)
	anim_tree.start("Spawn")
	# trying to prevent 1 frame of wrong anim?
	#await get_tree().process_frame
	self.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dead or is_downed:
		if has_node("Walking") : $Walking.stop()
		return
	else:
		is_downed = false
		
	if has_node("Walking") and not $Walking.playing:
		$Walking.play()
	
	_process_behavior(delta)


## Default behaviour is to walk towards player. Overridden by children
func _process_behavior(delta : float) -> void:
	if target_player:
		var _direction = global_position.direction_to(target_player.global_position)
		_direction.y = 0
		global_position += _direction * move_speed * delta
		look_at_player()

## For aiming
func look_at_player():
	if target_player:
		var _target_pos = target_player.global_position
		look_at(Vector3(_target_pos.x, global_position.y, _target_pos.z), Vector3.UP)
		print("looking")


func _on_damaged(amount: int, hit_zone: HitData.Zone, vector: Vector3):
	if is_dead: return
	match hit_zone:
		HitData.Zone.BODY:
			_knockdown(down_time)
		# TODO: handled by the health component????
		#HitData.Zone.HEAD:
			#_die(impact)
		# TODO: Armour
		#HitData.Zone.ARMOR:
			#_handle_armor_hit(impact)


func _knockdown(duration) -> void:
	if is_downed:
		return
		
	is_downed = true
	anim_tree.travel("Death")
	#anim.play(ANIM_DEATH)
	$DeathSound.play()
	$Walking.stop()
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		
		if not is_dead: # Check if they were headshot while down
			anim_tree.travel("Resurrect")
			$RiseSound.play()
			$Moans.play()


func _die(_amount, _zone, impact_vector : Vector3) -> void:
	if is_dead: return
	is_dead = true

	SignalBus.skeleton_killed.emit()
	$Walking.stop()
	$DeathSound.play()
	
	anim_tree.travel("Death")
	
	if $Rig_Medium/Skeleton3D/Skeleton_Minion_Eyes:
		$Rig_Medium/Skeleton3D/Skeleton_Minion_Eyes.queue_free()
	detach_and_fly(skull_gib, impact_vector)

	await get_tree().create_timer(5.0).timeout
	sink_and_vanish()


func detach_and_fly(mesh_node, impact: Vector3) -> void:
	$Rig_Medium/Skeleton3D/Skeleton_Minion_Head.visible = false
	$Rig_Medium/Skeleton3D/HeadAttach/HeadArea.process_mode = Node.PROCESS_MODE_DISABLED
	
	var _head_gib = mesh_node.instantiate()
	get_tree().root.add_child(_head_gib)
	
	_head_gib.global_transform = $Rig_Medium/Skeleton3D/HeadAttach.global_transform
	_head_gib.position += Vector3(0,0.8,0)
	
	var _head_hurtbox = $Rig_Medium/Skeleton3D/HeadAttach/HeadArea
	for child in _head_hurtbox.get_children():
		if "is_flying" in child:
			child.queue_free()
	
	_head_gib.linear_velocity = impact * 0.1 + Vector3.UP * 5.0
	_head_gib.angular_velocity = impact.normalized().cross(Vector3.UP) * 10.0


func sink_and_vanish() -> void:
	var _tween = create_tween()

	_tween.tween_property(self, "global_position:y", global_position.y - 2.0, 5.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.finished.connect(func():
		var _parent = get_parent()
		if _parent is PathFollow3D:
			_parent.queue_free()
		queue_free())
