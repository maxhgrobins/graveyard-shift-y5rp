extends Node

@export var button_scene : PackedScene
@export var spawn_point_container : Node3D

signal upgrade_selected(type: String)

func generate_shop() -> void:
	# TODO REPLACE WITH ENUM/DATA DRIVEN WAY
	var options = ["damage", "speed", "aoe"]
	options.shuffle()
	
	var _spawn_points = spawn_point_container.get_children()
	
	for i in range(3):
		# TODO Spawn based on data rather than just making a new default button
		var _btn = button_scene.instantiate() as FloatingButton
		_spawn_points[i].add_child(_btn)
		_btn.global_position = _spawn_points[i].global_position
		_btn.button_name = options[i]
		
		_btn.button_pressed.connect(_on_upgrade_selected)
		await get_tree().create_timer(0.5).timeout 
			
func _on_upgrade_selected(type: String):
	upgrade_selected.emit(type)
	
	await get_tree().create_timer(2.0).timeout 
	
	for child in spawn_point_container.get_children():
		if child.get_child_count() > 0:
			var _button = child.get_child(0)
			if _button is FloatingButton:
				_button.shrink_and_clear()
