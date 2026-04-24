extends Node3D

@export var nights : Array[NightData]
@export var path_map : Dictionary[String, NodePath] = {
	"North": "",
	"East": "",
	"South": "",
	"South2": "",
	"West": "",
	"West2": ""
}

@export var night_duration = 180
@export var minion_scene : PackedScene
@export var axe_skele_scene : PackedScene
@export var wizard_scene : PackedScene

@onready var player : Node3D = $"../Platform/Player/XRCamera3D"

var night_timer: Timer
var current_night_index: int = 0

signal wave_complete()

func _ready():
	night_timer = $"../NightTimer"

func start_night(index: int):
	_clean_up_paths()
	if index >= nights.size():
		push_warning("Night out of range! Trying to run night ",index," but it is not assigned in the inspector.")
		return
	var night = nights[index]
	
	night_timer.wait_time = night_duration
	night_timer.one_shot = true
	night_timer.start()
	print("Starting Night ", index + 1)
	
	var _length = night.wave_pool.size()
	var _shuffled_waves = night.wave_pool.duplicate()
	
	if index == 0:
		print("playing n1 start wave")
		await spawn_wave(night.wave_pool[0])
		_shuffled_waves = night.wave_pool.slice(1, _length)
		_shuffled_waves.shuffle()
		_length -= 1
	else:
		_shuffled_waves.shuffle()
	
	var _wave_idx: int = 0
	while not night_timer.is_stopped():
		var next_wave = _shuffled_waves[_wave_idx % _length]
		await spawn_wave(next_wave)
		if night_timer.is_stopped(): break
		await get_tree().create_timer(night.secs_between_waves).timeout
		if night_timer.is_stopped(): break
		_wave_idx += 1
	
	print("end of night")
	wave_complete.emit()
	_clean_up_paths(true)


func _clean_up_paths(knockdown: bool = false):
	for node_path: NodePath in path_map.values():
		for follower in get_node(node_path).get_children():
			if follower is PathFollow3D:
				var _enemy = follower.get_child(0)
				
				if _enemy:
					if knockdown:
						## TODO: if doesnt have a knockdown, default to die?
						## CHANGED TO DIE SO I DONT HAVE TO WORRY ABOUT THEM GETTING BACK UP
						_enemy._die(0, 0, Vector3.ZERO)		# this is 100% borked. please fix when it isnt 3am
						await get_tree().create_timer(0.1).timeout
					else:
						_enemy.queue_free()


func spawn_wave(wave: WaveData):
	for _spawn_data in wave.spawn_list:
		if night_timer.is_stopped(): break
		
		## TODO : what if a long ahh timer is chosen as wave 1. is there just awkward silence.
		await get_tree().create_timer(_spawn_data.spawn_delay).timeout
		
		var _enemy_scene :PackedScene
		match _spawn_data.enemy_type:
			"Minion": _enemy_scene = minion_scene
			"Axe": _enemy_scene = axe_skele_scene
			"Wizard": _enemy_scene = wizard_scene

		for i in range(_spawn_data.amount):
			# check each path
			for _path_name in _spawn_data.PATH_FLAGS.keys():
				# get the flag number
				var _flag_value = SpawnData.PATH_FLAGS[_path_name]
				# if the path is selected
				if _spawn_data.paths & _flag_value:
					var _path_node_path = path_map.get(_path_name)
					if _path_node_path:
						var _path : Path3D = get_node(_path_node_path)
						if _path:
								create_enemy_on_path(_path, _enemy_scene)
			await get_tree().create_timer(_spawn_data.spawn_delay).timeout


func create_enemy_on_path(path: Path3D, enemy_type: PackedScene):
	var follower = PathFollow3D.new()
	follower.loop = false
	follower.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	
	path.add_child(follower)
	
	var enemy = enemy_type.instantiate()
	enemy.target_player = player
	follower.add_child(enemy)
