extends Node

var current_day: int = 1
var current_wave: int = 1

@export var skeleton_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

	
func start_wave():
	# Formula: Base count + (Day * Multiplier) + (Wave * Multiplier)
	var enemy_count = 5 + (current_day * 3) + (current_wave * 2)
	for i in enemy_count:
		spawn_enemy_from_random_grave()
		await get_tree().create_timer(randf_range(0.5, 2.0)).timeout
		
# maybe pass in details about enemy type?
func spawn_enemy_from_random_grave():
	var spawned_enemy = skeleton_scene.instantiate()
	
