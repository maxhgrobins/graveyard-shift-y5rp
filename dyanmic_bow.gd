extends Node3D

@onready var pullpoint : Node3D = self.find_child("pullpoint")
@onready var toptip : Node3D = self.find_child("toptip")
@onready var bottomtip : Node3D = self.find_child("bottomtip")

@export var TEST_HAND : Node3D 

var held_arrow : Node3D = null

enum BowState { IDLE, NOCKED }
var current_state = BowState.IDLE

var start_offset: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_offset = pullpoint.position.z

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#stick to hand
	global_position = get_parent().global_position
	
	match current_state:
		BowState.IDLE:
			pass
			
		BowState.NOCKED:
			bend_bow()
			
			# face back hand
			look_at(TEST_HAND.global_position, get_parent().global_basis.y, true)
			# pull string
			pullpoint.global_transform = TEST_HAND.global_transform 
			
func bend_bow():
	# bend the bow
	#pullpoint.position.x = 0
	#pullpoint.position.y = 0
	toptip.position.z = start_offset + ((pullpoint.position.z - start_offset) / 7)
	bottomtip.position.z = start_offset + ((pullpoint.position.z - start_offset) / 7)
	toptip.position.y = 0.3 - ((pullpoint.position.z - start_offset) / 20)
	bottomtip.position.y = -0.3 + ((pullpoint.position.z - start_offset) / 20)

func nock_arrow(arrow_node):
	held_arrow = arrow_node
	current_state = BowState.NOCKED
	# Re-parent arrow to the bow's "String" node so it moves with the pull
	held_arrow.reparent(pullpoint) 
	held_arrow.position = Vector3.ZERO
	held_arrow.rotation = Vector3.ZERO

func fire_arrow():
	if current_state == BowState.NOCKED:
		# 1. Calculate force based on pull distance
		var force = global_position.distance_to(pullpoint.global_position) * 50

		# 2. Release arrow into the world
		held_arrow.reparent(get_tree().root)
		held_arrow.launch(force) # Call a function on the arrow to start physics

		# 3. Reset bow
		current_state = BowState.IDLE
		held_arrow = null
