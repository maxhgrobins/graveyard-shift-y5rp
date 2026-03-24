extends Node3D

@onready var pullpoint : Node3D = self.find_child("pullpoint")
@onready var toptip : Node3D = self.find_child("toptip")
@onready var bottomtip : Node3D = self.find_child("bottomtip")

@export var TEST_HAND : Node3D 

var start_offset: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_offset = pullpoint.position.z

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#stick to hand
	global_position = get_parent().global_position
	
	# waggle the bow
	if pullpoint and toptip and bottomtip:
		pullpoint.position.x = 0
		pullpoint.position.y = 0
		
		
		toptip.position.z = start_offset + ((pullpoint.position.z - start_offset) / 7)
		bottomtip.position.z = start_offset + ((pullpoint.position.z - start_offset) / 7)
		toptip.position.y = 0.3 - ((pullpoint.position.z - start_offset) / 20)
		bottomtip.position.y = -0.3 + ((pullpoint.position.z - start_offset) / 20)

	# test rotation
	look_at(TEST_HAND.global_position, get_parent().global_basis.y, true)
	#pullpoint.global_transform = TEST_HAND.global_transform 
