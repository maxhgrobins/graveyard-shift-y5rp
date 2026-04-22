extends Node

@export var lift : AnimatableBody3D
@export var wave_manager : Node
@export var shop_manager : Node

var night : int = 0


func _ready() -> void:
	# REPLACE WITH MENU OR WHATEVER. ONLY NEEDS TO KNOW ABOUT MENU BUTTONS, NOT UPGRADES
	for node in $"../Shop".get_children():
		if node is FloatingButton:
			node.button_pressed.connect(_on_button_pressed)
			
	shop_manager.upgrade_selected.connect(_apply_upgrade)
	wave_manager.wave_complete.connect(_on_wave_complete)


func _process(delta: float) -> void:
	if night == 5:
		get_tree().reload_current_scene()


func _on_button_pressed(button_name : String) -> void:
	match button_name:
		"start_game":
			lift.raise_lift()
			# TODO Ambidextrous
			$"../Platform/Player/left hand controller/LeftHand".hide()
			$"../Platform/Player/left hand controller/dyanmic_bow".show()
			$"../Platform/Player/left hand controller/LeftHandArea".monitoring = false
		#"upgrade":
			#lift.raise_lift()
			#shop_manager.purchase_complete


func _apply_upgrade(type: String):
	# TODO IMPLEMENT STATS/UPGRADES
	#match type:
		#"damage":
			#player.arrow_damage += 5
		#"speed":
			#player.arrow_speed += 10
		#"health":
			#player.health += 20
	
	await get_tree().create_timer(2.0).timeout
	lift.raise_lift()


func _on_platform_lift_arrived(location: String) -> void:
	if location == "graveyard":
		wave_manager.start_night(night)
	else:
		shop_manager.generate_shop()


func _on_wave_complete() -> void:
	lift.lower_lift()
	night += 1
