extends ProjectileBase

var spin_speed : float = 10.0

func _process_visuals(delta: float):
	$MeshContainer.rotate_y(spin_speed * delta)
