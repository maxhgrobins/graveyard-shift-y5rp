extends Sprite3D

@export var scale_factor: float = 0.5
@export var min_scale: float = 1.0

@export var spin_speed: float = 2.0
@export var pulse_speed: float = 3.0
@export var min_opacity: float = 0.2
  
var rotation_angle: float = 0.0
func _process(delta):
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
		
	get_parent().look_at(camera.global_position, Vector3.UP, true)
	
	var dist = global_position.distance_to(camera.global_position)
	var dynamic_scale = min_scale + (dist * scale_factor)
	scale = Vector3.ONE * dynamic_scale

	rotation_angle += spin_speed * delta
	rotate_object_local(Vector3.FORWARD, spin_speed * delta)

	var time = Time.get_ticks_msec() / 1000.0
	var pulse = (sin(time * pulse_speed) + 1.0) / 2.0 # Normalizes sin to 0.0 - 1.0
	modulate.a = lerp(min_opacity, 0.3, pulse)
	
	
