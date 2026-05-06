extends Node

@export var lift : AnimatableBody3D
@export var wave_manager : Node
@export var shop_manager : Node

@export var music_player : AudioStreamPlayer
@export var ambience_player : AudioStreamPlayer

@export var streak_cooldown : float = 10.0

@onready var music : AudioStreamPlaybackInteractive = music_player.get_stream_playback()
@onready var ambience : AudioStreamPlaybackInteractive = ambience_player.get_stream_playback()
@onready var streak_timer : Timer = $"../StreakTimer"

var night : int = 0


func _ready() -> void:
	# REPLACE WITH MENU OR WHATEVER. ONLY NEEDS TO KNOW ABOUT MENU BUTTONS, NOT UPGRADES
	for node in $"../Shop".get_children():
		if node is FloatingButton:
			node.button_pressed.connect(_on_button_pressed)
			
	shop_manager.upgrade_selected.connect(_apply_upgrade)
	wave_manager.wave_complete.connect(_on_wave_complete)
	
	streak_timer.wait_time = streak_cooldown
	streak_timer.timeout.connect(_on_streak_lost)
	
	SignalBus.skeleton_killed.connect(_on_skeleton_killed)
	SignalBus.dummy_killed.connect(_on_dummy_killed)


func _process(delta: float) -> void:
	if night == 5:
		get_tree().reload_current_scene()

func _on_button_pressed(button_name : String) -> void:
	match button_name:
		"start_game":
			_start_game()
			# TODO start tutorial
		#"upgrade":
			#lift.raise_lift()
			#shop_manager.purchase_complete


func _on_dummy_killed():
	_start_night()


func _start_night():
	await get_tree().create_timer(2.0).timeout
	# Do some anim/vo here
	
	# maybe call this somewhere else
	lift.raise_lift()
	music.switch_to_clip_by_name("Music")
	ambience.switch_to_clip_by_name("Woods")


func _start_game():
	# TODO Ambidextrous
	$"../Platform/Player/left hand controller/LeftHand".hide()
	$"../Platform/Player/left hand controller/dyanmic_bow".show()
	$"../Platform/Player/left hand controller/LeftHandArea".process_mode = Node.PROCESS_MODE_DISABLED


func _apply_upgrade(type: String):
	# TODO IMPLEMENT STATS/UPGRADES
	match type:
		"damage":
			GameStats.damage_level += 1
		"accuracy":
			GameStats.accuracy_level += 1
		"defence":
			GameStats.defence_level += 1


func _on_platform_lift_arrived(location: String) -> void:
	if location == "graveyard":
		wave_manager.start_night(night)
	else:	# shop
		shop_manager.generate_shop()
		music.switch_to_clip_by_name("Shop")
		$"../Sky"._reset_sky()
		wave_manager.clean_up_spawns()
		SignalBus.emit_signal("in_shop")


func _on_wave_complete() -> void:
	$"../Shop/dummyspawner".spawn_dummy()
	
	ambience.switch_to_clip_by_name("Cave")
	lift.lower_lift()
	night += 1
	
## TODO do streak stuff?
func _on_skeleton_killed():
	#if streak_timer.is_stopped():
		#music.switch_to_clip_by_name("On Fire")
	streak_timer.start()


func _on_streak_lost():
	pass
	#music.switch_to_clip_by_name("Normal")
