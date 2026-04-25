extends ProjectileBase

var spin_speed : float = 15.0

func _process_visuals(delta: float):
	$AxeMesh.rotate_x(spin_speed * delta)
