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
@onready var dummy_spawner : Marker3D =  $"../Shop/dummyspawner"

var tutorial_complete : bool = false
var night : int = 0
var ready_to_start : bool = true

var _dummy_instance : Node3D

func _ready() -> void:
	GameStats.reset_stats()
	# REPLACE WITH MENU OR WHATEVER. ONLY NEEDS TO KNOW ABOUT MENU BUTTONS, NOT UPGRADES
	for node in $"../Shop".get_children():
		if node is FloatingButton:
			node.button_pressed.connect(_on_button_pressed)
			
	shop_manager.upgrade_selected.connect(_apply_upgrade)
	
	streak_timer.wait_time = streak_cooldown
	streak_timer.timeout.connect(_on_streak_lost)
	
	SignalBus.skeleton_killed.connect(_on_skeleton_killed)
	SignalBus.dummy_killed.connect(_on_dummy_killed)
	SignalBus.night_finished.connect(_on_night_complete)
	SignalBus.start_night.connect(_start_night)
	SignalBus.tutorial_over.connect(func(): ready_to_start = true)	# dont think this is necessary any more as the dummy shouldnt respawn during tutorial anyway
	
	_dummy_instance = $"../Shop/dummyspawner/dummy"

func _process(_delta: float) -> void:
	if night == 5:
		SignalBus.game_win.emit()

func _on_button_pressed(button_name : String) -> void:
	match button_name:
		"start_game":
			_start_game()
			# TODO start tutorial
		#"upgrade":
			#lift.raise_lift()
			#shop_manager.purchase_complete


func _on_dummy_killed():
	# respawn dummy if not ready (hasnt picked up upgrade or is in tutorial)
	if ready_to_start : return	# leave dead dummy
	else:
		await get_tree().create_timer(5.0).timeout 
		if ready_to_start : return	# leave dead dummy
		_dummy_instance.queue_free()
		_dummy_instance = dummy_spawner.spawn_dummy()
		

func _start_night():
	ready_to_start = true
	
	await get_tree().create_timer(2.0).timeout
	# Do some anim/vo here
	
	# maybe call this somewhere else
	lift.raise_lift()
	music.switch_to_clip_by_name("Music")
	ambience.switch_to_clip_by_name("Woods")


func _start_game():
	SignalBus.game_start.emit()
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
			SignalBus.change_health.emit(1, null)
		_:
			push_error("invalid upgrade")
			return
			
	ready_to_start = true
	SignalBus.upgrade_selected.emit()

func _on_platform_lift_arrived(location: String) -> void:
	if location == "graveyard":
		wave_manager.start_night(night)
		SignalBus.in_graveyard.emit()
	else:	# shop
		shop_manager.generate_shop()
		music.switch_to_clip_by_name("Shop")
		$"../Sky"._reset_sky()
		wave_manager.clean_up_spawns()
		SignalBus.in_shop.emit()


func _on_night_complete() -> void:
	if is_instance_valid(_dummy_instance):
		_dummy_instance.queue_free()
	_dummy_instance = dummy_spawner.spawn_dummy()
	ambience.switch_to_clip_by_name("Cave")
	lift.lower_lift()
	night += 1
	GameStats.current_night = night
	
## TODO do streak stuff?
func _on_skeleton_killed():
	#if streak_timer.is_stopped():
		#music.switch_to_clip_by_name("On Fire")
	streak_timer.start()


func _on_streak_lost():
	pass
	#music.switch_to_clip_by_name("Normal")
