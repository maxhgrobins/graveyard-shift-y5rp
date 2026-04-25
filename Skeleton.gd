extends Node3D

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
	await get_tree().process_frame
	self.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dead or anim_tree.get_current_node() != "Walk":
		$Walking.stop()
		return
	
	if not $Walking.playing:
		$Walking.play()
	
	is_downed = false
	
	var parent = get_parent()
	if parent is PathFollow3D:
		parent.progress += move_speed * delta
		
	elif target_player:
		var direction = global_position.direction_to(target_player.global_position)
		direction.y = 0

		global_position += direction * move_speed * delta

		look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)


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
	
	var head_gib = mesh_node.instantiate()
	get_tree().root.add_child(head_gib)
	
	head_gib.global_transform = $Rig_Medium/Skeleton3D/HeadAttach.global_transform
	head_gib.position += Vector3(0,0.8,0)
	
	var head_hurtbox = $Rig_Medium/Skeleton3D/HeadAttach/HeadArea
	for child in head_hurtbox.get_children():
		if "is_flying" in child:
			child.queue_free()
	
	head_gib.linear_velocity = impact * 0.1 + Vector3.UP * 5.0
	head_gib.angular_velocity = impact.normalized().cross(Vector3.UP) * 10.0


func sink_and_vanish() -> void:
	var tween = create_tween()

	tween.tween_property(self, "global_position:y", global_position.y - 2.0, 5.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.finished.connect(func():
		var parent = get_parent()
		if parent is PathFollow3D:
			parent.queue_free()
		queue_free())
