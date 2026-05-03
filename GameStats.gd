extends Node

var stats = preload("res://upgrade_data.tres")

#var souls: int = 0

var damage_level: int = 1
var accuracy_level: int = 1
var defence_level: int = 1

func get_damage():
	return stats.damage_levels[damage_level]
	
func get_accuracy():
	return stats.accuracy_levels[accuracy_level]
		
func get_defence():
	return stats.defence_levels[defence_level]
	
