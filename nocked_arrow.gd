extends Node3D

var is_flying: bool = false
var velocity: Vector3 = Vector3.ZERO

const RAY_LENGTH = 0.5

@onready var stick_point: Marker3D = $StickPoint

func _physics_process(delta: float) -> void:
	if is_flying:
		var next_position = stick_point.global_position + (velocity * delta)
		
		# create ray
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(stick_point.global_position, next_position)
		var result = space_state.intersect_ray(query)

		if result :
			is_flying = false
			set_process(false) # stop moving
			
			# snap to contact point
			global_position = global_position + (result.position - stick_point.global_position)
			
			_stick_to_target(result.collider)
		else:
			# gravity
			velocity.y -= 9.8 * delta
			
			global_position += velocity * delta
			
			# arrow arc
			if velocity.length() > 0.1:
				look_at(global_position + velocity, Vector3.UP)
				

func launch(force: float):
	is_flying = true
	velocity = -global_transform.basis.z * force


func _stick_to_target(body: Object):
	print("Hit: ", body.name)
	# call body.take_damage() here
	
	# reparenting to move with whatever it hit
	reparent(body, true)
