extends Resource
class_name SpawnData

enum PATH_FLAGS {
	North = 1,
	East = 2,
	South = 4,
	South2 = 8,
	West = 16,
	West2 = 32
}

@export_enum("Minion", "Axe", "Wizard") var enemy_type: String = "Minion"
@export var is_armoured : bool = false
@export var amount: int = 1
@export_flags("North", "East", "South", "South2", "West", "West2") var paths = 1
@export var spawn_delay: float = 2.0
