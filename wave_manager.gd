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
@export var projectile_markers : Array[Marker3D]
@export var night_duration : float = 180.0
@export var minion_scene : PackedScene
@export var axe_skele_scene : PackedScene
@export var wizard_scene : PackedScene

@onready var player : Node3D = $"../Platform/Player/XRCamera3D"

var night_timer: Timer
var current_night_index: int = 0

signal wave_complete()

func _ready():
	night_timer = $"../NightTimer"
	night_timer.wait_time = night_duration
	night_timer.timeout.connect(_on_night_end)


func _on_night_end():
	print("end of night")
	wave_complete.emit()
	
	# kill remaining enemies as the lift goes down
	clean_up_spawns(true)


func start_night(index: int):
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


func clean_up_spawns(knockdown: bool = false):
	var _enemies = []
	# projectile enemies
	for _marker : Marker3D in projectile_markers:
		if _marker != null and _marker.get_child_count() > 0:
			var _enemy : Node3D = _marker.get_child(0)
			if _enemy != null:
				_enemies.append(_enemy)

	# path enemies
	for node_path: NodePath in path_map.values():
		for follower : PathFollow3D in get_node(node_path).get_children():
			if follower != null and follower.get_child_count() > 0:
				var _enemy : Node3D = follower.get_child(0)
				if _enemy != null:
					_enemies.append(_enemy)
	
	# clear 'em
	_enemies.shuffle()
	for _enemy : Node3D in _enemies:
		if _enemy != null:
			if _enemy is BaseSkeleton and knockdown:
				## TODO: if doesnt get knockdown, default to die?
				## 0 is dont get up
				_enemy._knockdown(0)
			else:
				_enemy.queue_free()
			await get_tree().create_timer(0.3).timeout


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
			if night_timer.is_stopped(): break
			# check each path
			
			if _spawn_data.enemy_type == "Axe":
				var _marker = get_free_marker()
				if _marker:
					create_projectile_enemy(_marker, _enemy_scene)
				else:
					print("No free markers for enemy, skipping spawn.")
			else:
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


func get_free_marker() -> Marker3D:
	var _available = []
	for _marker in projectile_markers:
		var _occupied = false
		if _marker.get_child_count() > 0:
				_occupied = true
		else:
			_available.append(_marker)
	
	return _available.pick_random() if _available.size() > 0 else null
	
	
func create_projectile_enemy(marker: Marker3D, enemy_type: PackedScene) -> void:
	var _enemy = enemy_type.instantiate()
	_enemy.target_player = player

	marker.add_child(_enemy) 
	_enemy.global_position = marker.global_position	
