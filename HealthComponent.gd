class_name HealthComponent extends Node

@export var max_health: int = 1
@onready var current_health: int = max_health

signal damaged(amount: int, hit_zone: HitData.Zone, impact: Vector3)
signal health_depleted(amount: int, hit_zone: HitData.Zone, impact: Vector3)

func take_damage(amount: int, zone: HitData.Zone, impact: Vector3):
	current_health -= amount
	if current_health <= 0:
		health_depleted.emit(amount, zone, impact)
	else:
		damaged.emit(amount, zone, impact) 
		
		
#func _die():
	#get_parent().queue_free()
