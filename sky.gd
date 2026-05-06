extends Node3D

@onready var night_timer : Timer = $"../NightTimer"
@onready var sky_colour : Color = $"../WorldEnvironment".environment.sky.sky_material.sky_top_color
@export var morning_colour : Color = Color("071837ff")
@export var morning_angle : float = 170.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not night_timer.is_stopped():
		var _night_progress = (night_timer.wait_time - night_timer.time_left) / night_timer.wait_time
		
		var _rotation = lerp(80.5, 170.0, _night_progress)
		rotation_degrees.z = _rotation
		
		if _rotation > 160.0:
			var _colour_ratio = remap(_rotation, 160, morning_angle, 0.0, 1.0)
			$"../WorldEnvironment".environment.sky.sky_material.sky_top_color = sky_colour.lerp(morning_colour, _colour_ratio)

func _reset_sky():
	$"../WorldEnvironment".environment.sky.sky_material.sky_top_color = sky_colour
	rotation_degrees.z = 80.5
