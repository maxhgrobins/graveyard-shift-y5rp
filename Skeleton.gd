extends Node3D

@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var health : HealthComponent = $HealthComponent
@export var skull_gib : PackedScene
@export var move_speed : float = 2.0
@export var down_time : float = 3.0

var target_player : Node3D = null
var is_dead = false
var is_downed = true

const ANIM_WALK = "Rig_Medium_Special/Skeletons_Walking"
const ANIM_SPAWN = "Rig_Medium_Special/Skeletons_Spawn_Ground"
const ANIM_RESURRECT = "Rig_Medium_Special/Skeletons_Death_Resurrect"
const ANIM_DEATH = "Rig_Medium_Special/Skeletons_Death"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play(ANIM_SPAWN)
	health.health_depleted.connect(_die)
	health.damaged.connect(_on_damaged)
	anim.animation_finished.connect(_on_animation_finished)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dead or is_downed: return
	
	var parent = get_parent()
	if parent is PathFollow3D:
		parent.progress += move_speed * delta
		
	elif target_player:
		var direction = global_position.direction_to(target_player.global_position)
		direction.y = 0

		global_position += direction * move_speed * delta

		look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
			
	if anim.current_animation != ANIM_WALK and anim.current_animation != ANIM_RESURRECT:
		anim.play(ANIM_WALK)

func _on_damaged(amount: int, hit_zone: HitData.Zone, vector: Vector3):
	if is_dead: return
	match hit_zone:
		HitData.Zone.BODY:
			_knockdown()
		# TODO: handled by the health component????
		#HitData.Zone.HEAD:
			#_die(impact)
		# TODO: Armour
		#HitData.Zone.ARMOR:
			#_handle_armor_hit(impact)

##TEST
#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#if anim_name == "Rig_Medium_Special/Skeletons_Death_Resurrect":
		#is_downed = false

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == ANIM_SPAWN or anim_name == ANIM_RESURRECT:
		is_downed = false
			

func _knockdown():
	if is_downed:
		return
		
	is_downed = true
	anim.play(ANIM_DEATH)
	
	await get_tree().create_timer(down_time).timeout
	
	if not is_dead: # Check if they were headshot while down
		anim.play(ANIM_RESURRECT)
		
func _die(_a, _b, impact_vector : Vector3):
	is_dead = true
	
	if not is_downed:
		anim.play(ANIM_DEATH)
	
	if $Rig_Medium/Skeleton3D/Skeleton_Minion_Eyes:
		$Rig_Medium/Skeleton3D/Skeleton_Minion_Eyes.queue_free()
	detach_and_fly(skull_gib, impact_vector)

	await get_tree().create_timer(5.0).timeout
	sink_and_vanish()

	
func detach_and_fly(mesh_node, impact: Vector3):
	$Rig_Medium/Skeleton3D/Skeleton_Minion_Head.visible = false
	
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
	
func sink_and_vanish():
	var tween = create_tween()

	tween.tween_property(self, "global_position:y", global_position.y - 2.0, 3.0)
	tween.finished.connect(func():
		var parent = get_parent()
		if parent is PathFollow3D:
			parent.queue_free()
		queue_free())
