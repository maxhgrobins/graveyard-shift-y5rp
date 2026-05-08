extends Area3D

var in_quiver : bool = false

var held_arrow : Node3D = null
@export var arrow_scene : PackedScene

signal arrow_spawned(arrow_node: Node3D, hand_area: Node3D)
signal arrow_despawned(arrow_node: Node3D, hand_area: Node3D)

func _on_quiver_area_area_entered(area):
	print("quiver entered")
	var controller = area.get_parent()
	if controller is XRController3D:
		in_quiver = true
		var hand_side = "left_hand" if "left" in controller.name.to_lower() else "right_hand"
		
		if held_arrow == null:
			HapticManager.play(HapticManager.Vibration.UI_CLICK, hand_side)


func _on_quiver_area_area_exited(area) -> void:
	in_quiver = false
		

func _on_right_hand_controller_button_pressed(button_name: String) -> void:
	if button_name == "trigger_click":
		if in_quiver and held_arrow == null:
			$"../../XRCamera3D/QuiverArea/quiver_sfx".play()
			spawn_arrow()
			#TODO both hands support
			$"../RightHand".visible = false
			

func _on_right_hand_controller_button_released(button_name: String) -> void:
	if button_name == "trigger_click" and held_arrow:
		$"../RightHand".visible = true
		# if nocked, bow script handles firing
		# TODO check if nocked in some smarter way
		if !held_arrow.is_flying:
			print("DROPPING ARROW")
			arrow_despawned.emit(held_arrow, self)
			held_arrow.queue_free()
			held_arrow = null
			## TODO make physics object and drop
		else:
			print("ARROW RELEASED")
			held_arrow = null
		
		
func spawn_arrow() -> void:
	held_arrow = arrow_scene.instantiate()
	add_child(held_arrow)
	# TODO ambidextrous
	HapticManager.play(HapticManager.Vibration.ARROW_GRAB, "right_hand")
	arrow_spawned.emit(held_arrow, self)
