extends AnimatableBody3D

@export var move_duration : float = 2.0
@export var shop_height : float = -5.6
@export var graveyard_height : float = 0.0

signal lift_arrived(location: String)

func lower_lift():
	_move_lift(shop_height, "shop")


func raise_lift():
	_move_lift(graveyard_height, "graveyard")


func _move_lift(target: float, destination: String):
	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(self, "global_position:y", target, move_duration)
	
	await tween.finished
	
	lift_arrived.emit(destination)
