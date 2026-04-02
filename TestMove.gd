extends CSGBox3D

@export var reverse : bool = false
@export var speed : float = 1.0
@export var start : Marker3D
@export var end : Marker3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var target = end if not reverse else start
	
	global_position += global_position.direction_to(target.global_position) * speed * delta	
	
	if global_position.distance_to(target.global_position) < 0.2:
		reverse = not reverse
	
