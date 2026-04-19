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
		query.collide_with_areas = true
		
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
				# prevent colinearity warning from clogging debugger
				if not velocity.normalized().is_equal_approx(Vector3.UP) and not velocity.normalized().is_equal_approx(Vector3.DOWN):
					look_at(global_position + velocity, Vector3.UP)
				

func launch(force: float):
	is_flying = true
	velocity = -global_transform.basis.z * force


func _stick_to_target(hit_collider: Object):
	print("Hit: ", hit_collider.name)
	
	# reparenting to move with whatever it hit
	reparent(hit_collider, true)
	set_physics_process(false)
	
	if hit_collider is Hurtbox:
		var health = hit_collider.health_component
		
		# defaults
		var damage = 1
		var zone = hit_collider.zone
			
		# TODO this might still be hella jank. maybe just send damage to the
		# 	hurtbox and let it decide? ack
		match hit_collider.zone:
			HitData.Zone.BODY:
				damage = 0
				#zone = "weakPoint"
			#elif hit_collider.is_in_group("Hurtbox_Armour"):
				#damage = 1
				#zone = "armour"
			#elif hit_collider.is_in_group("Hurtbox_Knockdown"):
				#damage = 0
				#zone = "body"
		## TODO REVISIT IF YOU NEED TO CHANGE DAMAGE/ZONE FROM ARROW ^^
		
			
		health.take_damage(damage, zone, velocity)
