extends RigidBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(10.0).timeout
	sink_and_vanish()
	
	
func sink_and_vanish():
	var _tween = create_tween()

	_tween.tween_property(self, "global_position:y", global_position.y - 2.0, 5.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.finished.connect(func():
		var _parent = get_parent()
		if _parent is PathFollow3D:
			_parent.queue_free()
		queue_free())
