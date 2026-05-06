extends BaseSkeleton

func _ready() -> void:
	health.health_depleted.connect(_die)
	health.damaged.connect(_on_damaged)

	if is_armoured:
		helmet.show()
		$Rig_Medium/Skeleton3D/HeadAttach/HelmetArea.process_mode = Node.PROCESS_MODE_INHERIT

func _die(_amount, zone, impact_vector : Vector3) -> void:
	if is_dead: return
	is_dead = true

	$DeathSound.play()
	
	if $Rig_Medium/Skeleton3D/Skeleton_Minion_Eyes:
		$Rig_Medium/Skeleton3D/Skeleton_Minion_Eyes.queue_free()

	$Rig_Medium/Skeleton3D/Skeleton_Minion_Head.visible = false
	$Rig_Medium/Skeleton3D/HeadAttach/HeadArea.process_mode = Node.PROCESS_MODE_DISABLED
	detach_and_fly(skull_gib, $Rig_Medium/Skeleton3D/HeadAttach/HeadArea, impact_vector)
	
	SignalBus.dummy_killed.emit()
