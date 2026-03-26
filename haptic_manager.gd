extends Node

# Dictionary to store pre-defined haptic profiles
@export_group("Haptic Profiles")
@export var test : OpenXRHapticVibration

var xr_interface : XRInterface

func _ready():
	xr_interface = XRServer.primary_interface

## Main function to trigger haptics
## profile: The OpenXRHapticVibration resource to play
## hand: "left_hand" or "right_hand"
func play_haptic(profile: OpenXRHapticVibration, hand: String = "right_hand"):
	if not xr_interface or not profile:
		return
		
	# OpenXR trigger_haptic_pulse expects:
	# (action_name, tracker_name, frequency, amplitude, duration_sec, delay_sec)
	xr_interface.trigger_haptic_pulse(
		"haptic", 
		hand, 
		profile.frequency, 
		profile.amplitude, 
		profile.duration / 1000000000.0, # Convert ns to seconds
		0.0
	)

## Helper for "Global" effects (vibrate both hands)
func play_global_haptic():
	play_haptic(test, "left_hand")
	play_haptic(test, "right_hand")
