extends ProjectileBase

@export var spin_speed : float = 10.0
@export var max_distance: float = 50.0

@onready var max_dist_sq: float = pow(30.0, 2)

var target_player : Node3D
var passed_player: bool = false
var last_distance: float = 9999.0


func _process_visuals(delta: float):
	$MeshContainer.rotate_y(spin_speed * delta)
	
	if global_position.length_squared() > max_dist_sq:
		queue_free()
	
func _process(delta : float) -> void:
	super(delta)
	
	if passed_player or not is_instance_valid(target_player):
		return
		
	var current_distance = global_position.distance_to(target_player.global_position)
	
	if current_distance > last_distance:
		fade_out_audio()
		remove_from_group("enemy")
		passed_player = true
		
	last_distance = current_distance


func fade_out_audio(duration: float = 2.0):
	var tween = get_tree().create_tween()
	tween.tween_property($AudioStreamPlayer3D, "volume_db", -80.0, duration)
	tween.tween_callback($AudioStreamPlayer3D.stop)
