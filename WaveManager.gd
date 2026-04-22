extends Node3D

@export var nights: Array[NightData]
@export var path_map: Dictionary[String, NodePath] = {
	"N": "",
	"E": "",
	"S": "",
	"S2": "",
	"W": "",
	"W2": ""
}

@export var night_duration = 300
@onready var player : Node3D = $"../Platform/Player/XRCamera3D"

var night_timer: Timer
var current_night_index: int = 0
var is_night_active: bool = false

signal wave_complete()

func _ready():
	night_timer = $"../NightTimer"

func start_night(index: int):
	if index >= nights.size():
		push_warning("Night out of range! Trying to run night ",index," but it is not assigned in the inspector.")
		return
	var night = nights[index]
	
	night_timer.wait_time = night_duration
	night_timer.one_shot = true
	night_timer.start()
	
	is_night_active = true
	print("Starting Night ", index + 1)
	
	while not night_timer.is_stopped():
		var random_wave = night.wave_pool.pick_random()
		await spawn_wave(random_wave)
		if night_timer.is_stopped(): break
		await get_tree().create_timer(night.secs_between_waves).timeout
		if night_timer.is_stopped(): break
	
	print("end of night")
	wave_complete.emit()

func spawn_wave(wave: WaveData):
	for enemy in wave.spawn_list:
		if night_timer.is_stopped(): break
		
		if not is_night_active: break
		
		await get_tree().create_timer(enemy.sapwn_delay).timeout
		
		if path_map.has(enemy.path_name):
			var path_node_path = path_map[enemy.path_name]
			var path_node = get_node(path_node_path) as Path3D
			
			if path_node:
				create_enemy_on_path(path_node, enemy.enemy_type)
		else:
			print("Error: Path name '", enemy.path_name, "' not found!")

func create_enemy_on_path(path: Path3D, enemy_type: PackedScene):
	var follower = PathFollow3D.new()
	follower.loop = false
	follower.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	
	path.add_child(follower)
	
	var enemy = enemy_type.instantiate()
	enemy.target_player = player
	follower.add_child(enemy)
