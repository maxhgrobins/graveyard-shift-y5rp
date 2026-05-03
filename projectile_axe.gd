extends ProjectileBase

@export var spin_speed : float = 10.0
@export var max_distance: float = 50.0

@onready var max_dist_sq: float = pow(30.0, 2)


func _process_visuals(delta: float):
	$MeshContainer.rotate_y(spin_speed * delta)
	
	if global_position.length_squared() > max_dist_sq:
		queue_free()
