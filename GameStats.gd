extends Node

var stats = preload("res://upgrade_data.tres")

#var souls: int = 0
var crit_mult: float = 2.0

var damage_level: int = 0
var accuracy_level: int = 0
var defence_level: int = 0

var current_night : int = 0
var skeletons_killed : int = 0

func get_damage():
	return stats.damage_levels[damage_level]
	
func get_accuracy():
	return stats.accuracy_levels[accuracy_level]
		
func get_defence():
	return stats.defence_levels[defence_level]

func get_current_night():
	return current_night
	
func get_health_multiplier():
	return stats.enemy_health_mults[current_night] 
	
func get_speed_multiplier():
	return stats.enemy_speed_mults[current_night] 

func reset_stats():
	crit_mult = 2.0

	damage_level = 0
	accuracy_level = 0
	defence_level = 0

	current_night = 0
	skeletons_killed = 0
	
