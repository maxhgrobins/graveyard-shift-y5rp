extends Node3D

@export var enemy_scene : PackedScene
@export var spawn_radius_min : float = 15.0
@export var spawn_radius_max : float = 25.0
@export var min_wait_time : float = 1.0
@export var max_wait_time : float = 5.0

@onready var player : Node3D = $"../Player/XRCamera3D"

func _ready() -> void:
	spawn_loop()

func spawn_loop() -> void:
	while true:
		var wait_time = randf_range(min_wait_time, max_wait_time)
		await get_tree().create_timer(wait_time).timeout

		spawn_enemy()
		
		# speed up
		min_wait_time = max(0.5, min_wait_time * 0.99)
		max_wait_time = max(1.0, max_wait_time * 0.99)

func spawn_enemy() -> void:
	if not enemy_scene:
		print("No enemy scene assigned to spawner!")
		return
		
	var angle = randf() * TAU
	var distance = randf_range(spawn_radius_min, spawn_radius_max)
	
	var spawn_pos = Vector3(cos(angle) * distance, 0, sin(angle) * distance)

	spawn_pos += global_position 

	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_pos
	enemy.target_player = player
