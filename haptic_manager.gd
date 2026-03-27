extends Node

var xr_interface : XRInterface

# haptic vibrations (could be done with data instead using OpenXRHapticVibration)
enum Vibration {
	UI_CLICK,
	QUIVER_HOVER,
	ARROW_GRAB,
	NOCK_SNAP,
	BOW_TENSION,
	BOW_FIRE
}

# [frequency, amplitude, duration]
var type = {
	Vibration.UI_CLICK:     [1.0, 0.3, 0.05],
	Vibration.QUIVER_HOVER: [0.5, 0.1, 0.05],
	Vibration.ARROW_GRAB:   [1.0, 0.8, 0.1],
	Vibration.NOCK_SNAP:    [1.0, 1.0, 0.08],
	Vibration.BOW_TENSION:  [1.0, 0.2, -1.0],
	Vibration.BOW_FIRE:     [0.8, 1.0, 0.15]
}

func _ready():
	xr_interface = XRServer.primary_interface

## play predefined haptic
func play(vibration: Vibration, hand: String = "both", delay: float = 0.0):
	var v_data: Array = type[vibration]
	_vibrate(v_data, hand, delay)

## haptics with custom params
func custom(freq: float, amp: float, dur: float, hand: String = "both", delay: float = 0.0):
	_vibrate([freq,amp,dur],hand,delay)

func _vibrate(v_data: Array, hand: String = "both", delay: float = 0.0):
	if hand != "both" and hand != "right_hand" and hand != "left_hand":
		push_error(hand," is not a valid hand for vibration!")
	if hand == "both":
		_vibrate(v_data, "right_hand", delay)
		_vibrate(v_data, "left_hand", delay)
		return
		
	xr_interface.trigger_haptic_pulse(
		"haptic",
		hand,
		v_data[0],
		v_data[1],
		v_data[2],
		delay)
