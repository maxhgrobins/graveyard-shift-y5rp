extends Node

signal increase_health

var stats = preload("res://upgrade_data.tres")

#var souls: int = 0
var crit_mult: float = 2.0

var damage_level: int = 0
var accuracy_level: int = 0
var defence_level: int = 0

var current_night : int = 0

func get_damage():
	return stats.damage_levels[damage_level]
	
func get_accuracy():
	return stats.accuracy_levels[accuracy_level]
		
func get_defence():
	return stats.defence_levels[defence_level]
	increase_health.emit()
	
func get_current_night():
	return current_night
