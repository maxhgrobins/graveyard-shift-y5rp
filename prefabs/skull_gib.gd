extends RigidBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(10.0).timeout
	sink_and_vanish()
	
	
func sink_and_vanish():
	var tween = create_tween()

	tween.tween_property(self, "global_position:y", global_position.y - 2.0, 5.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.finished.connect(func():
		var parent = get_parent()
		if parent is PathFollow3D:
			parent.queue_free()
		queue_free())
