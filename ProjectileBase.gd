extends Node3D
class_name ProjectileBase

var is_flying: bool = false
var velocity: Vector3 = Vector3.ZERO
var shooter_collider

@onready var stick_point: Marker3D = $StickPoint


func launch(force: float):
	is_flying = true
	velocity = -global_transform.basis.z * force


func _physics_process(delta: float) -> void:
	if not is_flying: return
	
	_process_visuals(delta)
	
	var _next_position = stick_point.global_position + (velocity * delta)
	
	# create ray
	var _space_state = get_world_3d().direct_space_state
	var _query = PhysicsRayQueryParameters3D.create(stick_point.global_position, _next_position)
	if shooter_collider:
		_query.exclude = [shooter_collider]
	_query.collide_with_areas = true
	
	var _result = _space_state.intersect_ray(_query)

	if _result :
		_on_impact(_result)
	else:
		_process_movement(delta)


## Projectile movement - Default straight line
func _process_movement(delta):
	global_position += velocity * delta
	
## When hitting a collider - Default apply damage
func _on_impact(result):
	is_flying = false
	set_process(false) # stop moving

	# snap to contact point
	global_position = global_position + (result.position - stick_point.global_position)
	
	# TODO spawn particles
	
	if result.collider is Hurtbox:
		_apply_damage(result.collider)
	
	_after_impact(result.collider)


func _process_visuals(delta):
	pass


## After hit _collider - Default delete self
func _after_impact(_collider: Object):
	queue_free() 


func _apply_damage(hurtbox):
	## TODO Decide on damage logic
	var _final_damage = 0
	if hurtbox.zone == HitData.Zone.HEAD:
		_final_damage = 1
	
	hurtbox.health_component.take_damage(_final_damage, hurtbox.zone, velocity)
