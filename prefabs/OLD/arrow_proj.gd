extends Area3D

@export var max_speed: float = 60.0
@export var g: float = 12.0 # Slightly higher for a "snappy" feel

@onready var ray = $RayCast3D

var velocity: Vector3 = Vector3.ZERO
var launched: bool = false

func _ready():
	# Stop processing until fire() is called
	set_process(false)

func fire(strength: float) -> void:
	# Calculate starting velocity based on pull strength (0.0 to 1.0)
	var final_speed = max_speed * strength
	velocity = -transform.basis.z * final_speed
	
	launched = true
	set_process(true)
	# Disconnect from parent (the bow/player) so it moves freely in the world
	set_as_top_level(true) 

func _process(delta: float):
	if not launched: return
	
	# 1. Prediction: How far are we going this frame?
	var displacement = velocity * delta
	
	# 2. Raycast check: Update length to match displacement
	# We use -displacement.length() because the RayCast usually points forward (-Z)
	ray.target_position = Vector3(0, 0, -displacement.length())
	ray.force_raycast_update()
	
	if ray.is_colliding():
		_handle_impact(ray.get_collision_point(), ray.get_collider())
	else:
		# 3. Movement
		global_position += displacement
		
		# 4. Ballistics: Apply gravity to velocity
		velocity.y -= g * delta
		
		# 5. Rotation: Point the mesh toward the new velocity vector
		if velocity.length() > 0.1:
			look_at(global_position + velocity, Vector3.UP)

func _handle_impact(hit_pos: Vector3, body: Node):
	launched = false
	set_process(false) # Stop moving
	
	# Snap to the exact contact point
	global_position = hit_pos
	
	# Logic for sticking to the target
	_stick_to_target(body)

func _stick_to_target(body: Node):
	print("Hit: ", body.name)
	# If it's an enemy, you can call body.take_damage() here
	
	# Reparenting allows the arrow to move with whatever it hit (doors, NPCs, etc.)
	var parent = body
	# Safety check: Don't stick to things without a global transform
	if parent is Node3D:
		get_parent().remove_child(self)
		parent.add_child(self)
		# After reparenting, we reset global_transform to stay at the hit point
		global_position = global_position
