extends Node3D
class_name BaseSkeleton

var anim_tree : AnimationNodeStateMachinePlayback
@onready var health : Sprite3D = $HealthComponent
@onready var helmet : MeshInstance3D = $Rig_Medium/Skeleton3D/HeadAttach/Skeleton_Warrior_Helmet

@export var skull_gib : PackedScene
@export var helmet_gib : PackedScene
@export var move_speed : float = 2.0
@export var down_time : float = 3.0

## Export for test_gym
@export var target_player : Node3D = null
var is_dead = false
var is_downed = false
@export var is_armoured = false

var crit_queue : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false	# TODO hack to stop 1 frame of wrong anim. seems to only be fixed by changing anim in editor
	
	move_speed = move_speed * GameStats.get_speed_multiplier()
	anim_tree = $AnimationTree["parameters/playback"]
	health.health_depleted.connect(_die)
	health.damaged.connect(_on_damaged)
	if anim_tree:
		anim_tree.start("Spawn")
		$GPUParticles3D.emitting = true

	self.visible = true


func set_armoured(armoured : bool):
	if armoured:
		helmet.show()
		$Rig_Medium/Skeleton3D/HeadAttach/HelmetArea.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		helmet.hide()
		$Rig_Medium/Skeleton3D/HeadAttach/HelmetArea.process_mode = Node.PROCESS_MODE_DISABLED



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dead or is_downed:
		# if has walking sound node (TODO make var that indicates it is sound)
		if has_node("Walking"):
			$Walking.stop()
		return
		
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


func _on_damaged(_amount: int, hit_zone: HitData.Zone, vector: Vector3):
	if is_dead: return
	
	match hit_zone:
		#HitData.Zone.BODY:
			#_knockdown(down_time)
		# TODO: handled by the health component????
		HitData.Zone.HEAD:
			_critical_hit()
		HitData.Zone.ARMOR:
			_handle_armor_hit(vector)


func _handle_armor_hit(vector: Vector3):
	is_armoured = false
	$Rig_Medium/Skeleton3D/HeadAttach/Skeleton_Warrior_Helmet.hide()
	$Rig_Medium/Skeleton3D/HeadAttach/HelmetArea.process_mode = Node.PROCESS_MODE_DISABLED
	detach_and_fly(helmet_gib, $Rig_Medium/Skeleton3D/HeadAttach/HelmetArea, vector)


## TODO Do juice here
func _critical_hit() -> void:
	is_downed = true
	crit_queue += 1
	
	if anim_tree:
		anim_tree.travel("Crit")
	$CritSound.play()
	
	if anim_tree:
		anim_tree.travel("Walk")
	# wait for anim
	await get_tree().create_timer(1.5).timeout
	crit_queue -= 1
	
	# crit queue means if you hit skele multiple times, they remain stunned.
	# TODO this is a little jank. could be cleaner using a timer node...
	if crit_queue == 0: is_downed = false



## OLD this used to happen when bodyshotting enemies.
## keep and maybe go back? maybe make into a bool for playtesting
func _knockdown(duration) -> void:
	if is_downed:
		return
		
	is_downed = true
	if anim_tree:
		anim_tree.travel("Death")
	#anim.play(ANIM_DEATH)
	$DeathSound.play()
	$Walking.stop()
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		
	# if killed while down
	if not is_dead:
		is_downed = false
		if anim_tree:
			anim_tree.travel("Resurrect")
		$RiseSound.play()
		$Moans.play()


func _die(_amount, zone, impact_vector : Vector3) -> void:
	if is_dead: return
	is_dead = true
	
	SignalBus.skeleton_killed.emit()
	GameStats.skeletons_killed += 1
	
	if has_node("Walking"):
		$Walking.stop()
	$DeathSound.play()
	
	if anim_tree:
		anim_tree.travel("Death")
	
	if $Rig_Medium/Skeleton3D/Skeleton_Minion_Eyes:
		$Rig_Medium/Skeleton3D/Skeleton_Minion_Eyes.queue_free()
	if $Rig_Medium/Skeleton3D/Skeleton_Minion_Jaw:
		$Rig_Medium/Skeleton3D/Skeleton_Minion_Jaw.queue_free()
	
	health.hide()
	
	if zone == HitData.Zone.HEAD:
		$Rig_Medium/Skeleton3D/Skeleton_Minion_Head.visible = false
		$Rig_Medium/Skeleton3D/HeadAttach/HeadArea.process_mode = Node.PROCESS_MODE_DISABLED
		detach_and_fly(skull_gib, $Rig_Medium/Skeleton3D/HeadAttach/HeadArea, impact_vector)

	await get_tree().create_timer(5.0).timeout
	sink_and_vanish()


func detach_and_fly(mesh_node : PackedScene, hurtbox: Hurtbox, impact: Vector3) -> void:
	var _gib = mesh_node.instantiate()
	get_tree().root.add_child(_gib)
	
	_gib.global_transform = $Rig_Medium/Skeleton3D/HeadAttach.global_transform
	_gib.position += Vector3(0,0.8,0)
	
	# clear arrows
	for child in hurtbox.get_children():
		if "is_flying" in child:
			child.queue_free()
	
	_gib.linear_velocity = impact * 0.1 + Vector3.UP * 5.0
	_gib.angular_velocity = impact.normalized().cross(Vector3.UP) * 10.0


func sink_and_vanish() -> void:
	var _tween = create_tween()
	_tween.tween_property(self, "global_position:y", global_position.y - 2.0, 5.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.finished.connect(func():
		var _parent = get_parent()
		if _parent is PathFollow3D:
			_parent.queue_free()
		queue_free())
