extends Node3D

@onready var pullpoint : Node3D = self.find_child("pullpoint")
@onready var toptip : Node3D = self.find_child("toptip")
@onready var bottomtip : Node3D = self.find_child("bottomtip")

@export var nock_distance: float = 0.05
@export var nock_range: float = 0.98
@export var nock_lerp_speed: float = 0.15

@export var TEST_HAND : Node3D	#TODO replace with robust ambidextrous solution
 
@export var force_multiplier : float = 10.0

var held_arrow : Node3D = null
var arrow_hand : Node3D = null

enum BowState { IDLE, LERPING, NOCKED }
var current_state = BowState.IDLE

var start_offset: float
var last_pull_dist: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_offset = pullpoint.position.z


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#stick to hand
	global_position = get_parent().global_position
	
	match current_state:
		BowState.IDLE:
			# reset bow
			pullpoint.position.z = start_offset
			last_pull_dist = 0.0
			
			# nocking magnetism
			_nocking()
			
		#BowState.LERPING:
			#if arrow_hand.global_position.distance_to(pullpoint.global_position) > nock_distance * 1.5:
				## ABORT: The player moved their hand too far away
				#held_arrow.reparent(arrow_hand)
				#held_arrow.transform = Transform3D.IDENTITY
				#current_state = BowState.IDLE
				#HapticManager.play(HapticManager.Vibration.UI_CLICK, "right_hand")
				#return
				#
			## Interpolate both Position and Rotation to match the string (pullpoint)
			#held_arrow.global_transform = held_arrow.global_transform.interpolate_with(
				#pullpoint.global_transform, 
				#nock_lerp_speed * delta
			#)
			#
			## If close enough, finish nocking
			#if held_arrow.global_position.distance_to(pullpoint.global_position) < 0.01:
				## Officially child it to the string
				#held_arrow.reparent(pullpoint)
				#held_arrow.transform = Transform3D.IDENTITY
				#current_state = BowState.NOCKED
				#HapticManager.play(HapticManager.Vibration.NOCK_SNAP)
			
		BowState.NOCKED:
			_bend_bow()
			# face back hand
			look_at(TEST_HAND.global_position, get_parent().global_basis.y, true)
			# pull string
			pullpoint.global_position = TEST_HAND.global_position 
			
			var current_pull = pullpoint.position.z
			# if pulled back an extra 2cm, trigger a pulse
			if abs(current_pull - last_pull_dist) > 0.02:
				HapticManager.play(HapticManager.Vibration.BOW_TENSION, "right_hand")
				last_pull_dist = current_pull

func _nocking():
	if held_arrow != null:
		var dist = pullpoint.global_position.distance_to(held_arrow.global_position)
		
		var arrow_forward = -held_arrow.global_basis.z.normalized()
		var pp_forward = -pullpoint.global_basis.z.normalized()

		#print("Result: ", arrow_forward.dot(pp_forward))
		#DebugDraw3D.draw_arrow_ray(held_arrow.global_position, arrow_forward, 0.5, Color.RED, 0.01)
		#DebugDraw3D.draw_arrow_ray(held_arrow.global_position, dir_to_bow, 0.5, Color.BLUE, 0.01)
		#DebugDraw3D.draw_arrow_ray(pullpoint.global_position, pp_forward, 0.5, Color.GREEN, 0.01)
		#DebugDraw3D.draw_box(pullpoint.global_position, pullpoint.global_transform.basis.get_rotation_quaternion(), Vector3.ONE * (nock_distance * 2.0), Color.RED, true)
		
		if dist < nock_distance:

			# Only nock if the arrow is aligned with pullpoint
			if arrow_forward.dot(pp_forward) > nock_range:
				print("nocking")
				## Move arrow to root so it can lerp independently of hand movement
				#held_arrow.reparent(get_tree().root)
				#current_state = BowState.LERPING
				#HapticManager.play(	HapticManager.Vibration.NOCK_SNAP, "right_hand")
			
				# hard snap
				held_arrow.reparent(pullpoint)
				held_arrow.transform = Transform3D.IDENTITY # This clears all rotation/offset
				
				current_state = BowState.NOCKED
				HapticManager.play(HapticManager.Vibration.NOCK_SNAP, "right_hand")
			
										
func _bend_bow():
	# bend the bow
	var pull_delta = pullpoint.position.z - start_offset
	toptip.position.z = start_offset + (pull_delta / 7)
	bottomtip.position.z = start_offset + (pull_delta / 7)
	toptip.position.y = 0.3 - (pull_delta / 20)
	bottomtip.position.y = -0.3 + (pull_delta / 20)


func fire_arrow(arrow: Node3D):
	var force = abs(pullpoint.position.z - start_offset) * force_multiplier
	held_arrow.reparent(get_tree().root, true)
	# TODO implement launch
	print("LAUNCHING ARROW")
	held_arrow.launch(force) 
	
	current_state = BowState.IDLE
	held_arrow = null


func _on_right_hand_controller_button_released(name: String) -> void:
	if held_arrow and current_state == BowState.NOCKED:
		fire_arrow(held_arrow)


func _on_hand_area_arrow_spawned(arrow_node: Node3D, hand_area: Node3D) -> void:
	held_arrow = arrow_node
	arrow_hand = hand_area


func _on_hand_area_arrow_despawned(arrow_node: Node3D, hand_area: Node3D) -> void:
	held_arrow = null
