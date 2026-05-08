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


func _ready():
	night_timer = $"../NightTimer"
	night_timer.wait_time = night_duration
	night_timer.timeout.connect(_on_night_end)
	
	# clear anything left from restart
	clear_all_projectiles()		
	clean_up_spawns()

func _on_night_end():
	print("end of night")
	SignalBus.night_finished.emit()
	# kill remaining enemies as the lift goes down
	clean_up_spawns(true)

func _process(delta: float) -> void:
	if night_timer.time_left <= 5.0 and night_timer.time_left > 1.0:	# dont call on 0
		$"../Cockerel".play()

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
		if _marker.get_child_count() > 0:
			var _enemy = _marker.get_child(0)
			if is_instance_valid(_enemy):
				_enemies.append(_enemy)

	# path enemies
	for node_path: NodePath in path_map.values():
		var path_node = get_node_or_null(node_path)
		if path_node:
			for follower : PathFollow3D in path_node.get_children():
				if is_instance_valid(follower) and follower.get_child_count() > 0:
					var _enemy = follower.get_child(0)
					if is_instance_valid(_enemy):
						_enemies.append(_enemy)
	
	# clear 'em
	_enemies.shuffle()
	for _enemy : Node3D in _enemies:
		if not is_instance_valid(_enemy):
			continue
			
		if _enemy is BaseSkeleton and knockdown:
			## TODO: if doesnt get knockdown, default to die?
			## 0 is dont get up
			_enemy._die(100, HitData.Zone.BODY, Vector3.ZERO)
		else:
			if is_instance_valid(_enemy): _enemy.queue_free()
			
		await get_tree().create_timer(0.3).timeout


func clear_all_projectiles():
	var all_projectiles = get_tree().get_nodes_in_group("projectiles")
	
	for projectile in all_projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()


func spawn_wave(wave: WaveData):
	for _spawn_data in wave.spawn_list:
		if night_timer.is_stopped(): break
		
		## TODO : what if a long ahh timer is chosen as wave 1. is there just awkward silence.
		await get_tree().create_timer(_spawn_data.spawn_delay).timeout
		
		if night_timer.is_stopped(): break
		
		var _enemy_scene : PackedScene
		match _spawn_data.enemy_type:
			"Minion": _enemy_scene = minion_scene
			"Axe": _enemy_scene = axe_skele_scene
			"Wizard": _enemy_scene = wizard_scene
		
		for i in range(_spawn_data.amount):
			# check each path
			var _spawned
			
			if _spawn_data.enemy_type == "Axe":
				var _marker = get_free_marker()
				if _marker:
					if night_timer.is_stopped(): break
					_spawned = create_projectile_enemy(_marker, _enemy_scene)
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
								if night_timer.is_stopped(): break
								_spawned = create_enemy_on_path(_path, _enemy_scene)
			if is_instance_valid(_spawned) and _spawned is BaseSkeleton:
				_spawned.is_armoured = _spawn_data.is_armoured
				
			await get_tree().create_timer(_spawn_data.spawn_delay).timeout


func create_enemy_on_path(path: Path3D, enemy_type: PackedScene) -> Node3D:
	var _follower = PathFollow3D.new()
	_follower.loop = false
	_follower.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	
	path.add_child(_follower)
	
	var _enemy = enemy_type.instantiate()
	_enemy.target_player = player
	_follower.add_child(_enemy)
	return _enemy


func get_free_marker() -> Marker3D:
	var _available = []
	for _marker in projectile_markers:
		var _occupied = false
		if _marker.get_child_count() > 0:
				_occupied = true
		else:
			_available.append(_marker)
	
	return _available.pick_random() if _available.size() > 0 else null
	
	
func create_projectile_enemy(marker: Marker3D, enemy_type: PackedScene) -> Node3D:
	var _enemy = enemy_type.instantiate()
	_enemy.target_player = player

	marker.add_child(_enemy) 
	_enemy.global_position = marker.global_position	
	return _enemy
