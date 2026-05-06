extends Node3D

var skip_tutorial : bool = false
var skip_to_shoot_skull : bool = false
var has_tutorial_started : bool = false

@export var intro : AudioStreamPlayer3D
@export var tutorial : AudioStreamPlayer3D
@export var shoot_skull : AudioStreamPlayer3D
@export var nice_shot : AudioStreamPlayer3D
@export var cutoff : AudioStreamPlayer3D
@export var midnight : AudioStreamPlayer3D
@export var goodluck : AudioStreamPlayer3D
@export var bringing_you_down : AudioStreamPlayer3D
@export var take_one : AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.dummy_killed.connect(_dummy_killed)
	SignalBus.skeleton_killed.connect(_skeleton_killed)
	SignalBus.in_shop.connect(_in_shop)
	SignalBus.in_graveyard.connect(_in_graveyard)
	SignalBus.game_start.connect(_game_start)
	SignalBus.shot_first_arrow.connect(_shot_first_arrow)
	SignalBus.upgrade_selected.connect(_upgrade_selected)
	SignalBus.night_finished.connect(_night_finished)
	
	
func _dummy_killed():
	skip_tutorial = true
	if intro.playing or tutorial.playing:
		intro.stop()
		tutorial.stop()
		cutoff.play()
		
		await cutoff.finished
	else:
		nice_shot.play()
		
		await nice_shot.finished
		
	midnight.play()
	await midnight.finished
	
	SignalBus.tutorial_finished.emit()
	
	goodluck.play()
	
func _skeleton_killed():
	# TODO if heashot sufficiently far away
	pass
	
	
func _in_shop():
	take_one.play()
	
	
func _in_graveyard():
	pass
		
	
func _game_start():
	intro.play()
	await intro.finished
	
	if skip_tutorial: return
	
	await get_tree().create_timer(3.0).timeout
	
	if skip_tutorial: return
	
	if not skip_to_shoot_skull:
		has_tutorial_started = true
		tutorial.play()
		await tutorial.finished
		
	if skip_tutorial: return

	shoot_skull.play()
	
func _shot_first_arrow():
	if not has_tutorial_started:
		skip_to_shoot_skull = true

	
func _upgrade_selected():
	shoot_skull.play()
		
	
func _night_finished():
	bringing_you_down.play()
