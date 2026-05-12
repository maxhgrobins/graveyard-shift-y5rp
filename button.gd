extends Area3D
class_name FloatingButton

signal button_pressed(button_name: String)

@export var button_name : String = "upgrade"
@export_group("Settings")
@export var interact_button : String = "grip_click"
@export_group("Visuals")
@export var float_amplitude : float = 0.02
@export var float_speed : float = 1.0
@export var spin_speed : float = 0.2
@export var shrink_and_grow : bool = true

@onready var start_y : float = position.y

@export var pickup_sound : AudioStreamPlayer3D

var time : float = 0.0
var hovering_hand: Node3D = null


func _ready() -> void:
	area_entered.connect(_on_button_area_entered)
	area_exited.connect(_on_button_area_exited)
	
	if shrink_and_grow:
		grow()


func grow() -> void:
	var _original_spin_speed : float = spin_speed
	spin_speed = spin_speed * 10.0
	scale = Vector3(0.001, 0.001, 0.001)
	var _tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "spin_speed", _original_spin_speed, 0.2)

func shrink_and_clear(delay : float = 0.0) -> void:
	set_deferred("monitoring", false)
	$CollisionShape3D.disabled = true
	
	await get_tree().create_timer(delay).timeout 
	
	var _tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector3(0.001, 0.001, 0.001), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "spin_speed", spin_speed * 10.0, 0.2)
	_tween.finished.connect(queue_free)


func _process(delta: float) -> void:
	if hovering_hand:
		_check_for_input()
	
	## Visuals
	
	if float_speed > 0:
		time += delta
		position.y = start_y + sin(time * float_speed) * float_amplitude
	if spin_speed > 0:
		rotate_y(spin_speed * delta)


func _on_button_area_entered(area):
	print("start entered")
	var _controller = area.get_parent()
	if _controller is XRController3D:
		var _hand_side = "left_hand" if "left" in _controller.name.to_lower() else "right_hand"
		HapticManager.play(HapticManager.Vibration.QUIVER_HOVER, _hand_side)
		hovering_hand = _controller


func _on_button_area_exited(_area) -> void:
	hovering_hand = null


func _check_for_input() -> void:
	if hovering_hand is XRController3D:
		if hovering_hand.is_button_pressed(interact_button): 
				_trigger_action()


func _trigger_action() -> void:
	button_pressed.emit(button_name)
	set_deferred("monitoring", false)
	$CollisionShape3D.disabled = true
	
	if hovering_hand is XRController3D:
		var _hand_side = "left_hand" if "left" in hovering_hand.name.to_lower() else "right_hand"
		HapticManager.play(HapticManager.Vibration.UI_CLICK, _hand_side)

	hovering_hand = null
	
	if pickup_sound:
		pickup_sound.play()	#TODO wont work with queue free
	
	if shrink_and_grow:
		shrink_and_clear()
	else:
		queue_free()
