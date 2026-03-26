extends Area3D

var arrow_held : bool = false
var in_quiver : bool = false

var arrow_node : Node3D = null
@export var arrow_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_quiver_area_area_entered(area):
	print("wgvagbrdehr")
	in_quiver = true
	if not arrow_held:
		$"../../HapticManager".play_global_haptic()

func _on_quiver_area_area_exited(area):
	in_quiver = false
	if not arrow_held:
		$"../../HapticManager".play_global_haptic()
		

func _on_right_hand_controller_button_pressed(name):
	print(name)
	if name == "grip_click":
		if in_quiver and not arrow_held:
			spawn_arrow()
			
func spawn_arrow() -> void:
	arrow_node = arrow_scene.instantiate()
	add_child(arrow_node)
	# Trigger a stronger "click" when the arrow actually appears
	$"../../HapticManager".play_global_haptic()
