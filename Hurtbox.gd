class_name Hurtbox extends Area3D

# TODO do we still need actor?
var actor: Node3D
var health_component: HealthComponent

@export var zone: HitData.Zone

func _ready():
	actor = get_owner() 
	if actor:
		health_component = actor.get_node_or_null("HealthComponent")
	else:
		push_warning("Hurtbox at %s is missing an Actor!" % get_path())
	
	if not health_component:
		push_warning("Hurtbox at %s is missing a HealthComponent!" % get_path())
