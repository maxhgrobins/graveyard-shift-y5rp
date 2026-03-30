extends Area3D

var in_quiver : bool = false

var held_arrow : Node3D = null
@export var arrow_scene : PackedScene

signal arrow_spawned(arrow_node: Node3D, hand_area: Node3D)
signal arrow_despawned(arrow_node: Node3D, hand_area: Node3D)

func _on_quiver_area_area_entered(area):
	print("quiver entered")
	in_quiver = true
	if held_arrow == null:
		# TODO ambidextrous
		HapticManager.play(HapticManager.Vibration.QUIVER_HOVER, "right_hand")


func _on_quiver_area_area_exited(area):
	in_quiver = false
		

func _on_right_hand_controller_button_pressed(name):
	if name == "grip_click":
		if in_quiver and held_arrow == null:
			spawn_arrow()
			

func _on_right_hand_controller_button_released(name: String) -> void:
	if name == "grip_click" and held_arrow:
		# if nocked, bow script handles firing
		# TODO check if nocked in some smarter way
		if !held_arrow.is_flying:
			print("DROPPING ARROW")
			arrow_despawned.emit(held_arrow, self)
			held_arrow.queue_free()
			held_arrow = null
			## TODO make physics object and drop
			
		
		
func spawn_arrow() -> void:
	held_arrow = arrow_scene.instantiate()
	add_child(held_arrow)
	# TODO ambidextrous
	HapticManager.play(HapticManager.Vibration.ARROW_GRAB, "right_hand")
	arrow_spawned.emit(held_arrow, self)
