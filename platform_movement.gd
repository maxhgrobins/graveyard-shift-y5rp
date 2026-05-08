extends AnimatableBody3D

@export var move_duration : float = 2.0
@export var shop_height : float = -5.6
@export var graveyard_height : float = 0.0

@export var lid_start : float = 5.0

@onready var lid : StaticBody3D = $"../Shop/hole/lid"

signal lift_arrived(location: String)

func lower_lift():
	_move_lift(shop_height, "shop")


func raise_lift():
	_move_lift(graveyard_height, "graveyard")


func _move_lift(target: float, destination: String):
	var tween = create_tween()
	tween.set_parallel()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(self, "global_position:y", target, move_duration)
	if target == graveyard_height:
		tween.tween_property(lid, "global_position:x", lid_start, move_duration)
	else:
		tween.tween_property(lid, "global_position:x", 0.0, move_duration)
		
	$"../Shop/hole/lid/lid_sfx".play()
	$platform_sfx.play()
	$winch_sfx.play()
	
	await tween.finished
	
	$"../Shop/hole/lid/lid_sfx".stop()
	$platform_sfx.stop()
	$winch_sfx.stop()
	
	$lift_stop_sfx.play()
	lift_arrived.emit(destination)
