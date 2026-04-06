extends Node3D

@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var health : HealthComponent = $HealthComponent
@export var skull_gib : PackedScene
@export var move_speed : float = 2.0

var target_player : Node3D = null

var spawned : bool = false

var is_dead = false
var is_downed = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("Rig_Medium_Special/Skeletons_Spawn_Ground")
	health.health_depleted.connect(_die)
	health.damaged.connect(_on_damaged)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dead or is_downed or not target_player: return
		
	# 1. Get direction to the player
	var direction = global_position.direction_to(target_player.global_position)
	direction.y = 0 # Keep them grounded

	# 2. Move towards the player
	global_position += direction * move_speed * delta

	# 3. Always face the player
	look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
			
	if anim.current_animation != "Rig_Medium_Special/Skeletons_Walking" and anim.current_animation != "Rig_Medium_Special/Skeletons_Death_Resurrect":
		anim.play("Rig_Medium_Special/Skeletons_Walking")

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


func _knockdown():
	if is_downed:
		return
		
	is_downed = true
	anim.play("Rig_Medium_Special/Skeletons_Death")
	
	# Wait for 3 seconds, then resurrect
	await get_tree().create_timer(3.0).timeout
	
	if not is_dead: # Check if they were headshot while down
		anim.play("Rig_Medium_Special/Skeletons_Death_Resurrect")
		is_downed = false
		
func _die(_a, _b, impact_vector : Vector3):
	is_dead = true
	
	if not is_downed:
		anim.play("Rig_Medium_Special/Skeletons_Death")
	
	if $Rig_Medium/Skeleton3D/Skeleton_Minion_Eyes:
		$Rig_Medium/Skeleton3D/Skeleton_Minion_Eyes.queue_free()
	detach_and_fly(skull_gib, impact_vector)

	await get_tree().create_timer(5.0).timeout
	sink_and_vanish()

	
func detach_and_fly(mesh_node, impact: Vector3):
	$Rig_Medium/Skeleton3D/Skeleton_Minion_Head.visible = false
	
	# 2. Instance the dedicated physics head
	var head = skull_gib.instantiate()
	get_tree().root.add_child(head)
	
	# 3. Place it exactly where the skeleton's head is VISUALLY
	head.global_transform = $Rig_Medium/Skeleton3D/HeadAttach.global_transform
	head.position += Vector3(0,0.8,0)
	
	# 4. Apply the physics
	# Because the SkullProp scene is centered, this spins perfectly!
	head.linear_velocity = impact * 0.1 + Vector3.UP * 5.0
	head.angular_velocity = impact.normalized().cross(Vector3.UP) * 10.0
	
func sink_and_vanish():
	var tween = create_tween()
	# move down by 2 meters over 3 seconds
	tween.tween_property(self, "global_position:y", global_position.y - 2.0, 3.0)
	tween.finished.connect(queue_free)
