extends Marker3D

@export var dummy : PackedScene

func spawn_dummy():
	#  clear previous dummy
	if get_child_count() > 0:
		get_child(0).queue_free()
		
	var instance = dummy.instantiate()
	add_child(instance)
