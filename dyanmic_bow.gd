extends Node3D

@onready var pullpoint : Node3D = self.find_child("pullpoint")
@onready var toptip : Node3D = self.find_child("toptip")
@onready var bottomtip : Node3D = self.find_child("bottomtip")

@export var nock_distance: float = 0.05
@export var nock_range: float = 0.98
@export var nock_lerp_speed: float = 0.15

@export var TEST_HAND : Node3D	#TODO replace with robust ambidextrous solution
 
#@export var force_multiplier : float = 25.0
var first_shot_fired : bool = false		# for tutorial

var held_arrow : Node3D = null
var arrow_hand : Node3D = null

enum BowState { IDLE, LERPING, NOCKED }
var current_state = BowState.IDLE

var start_offset: float
var bow_idle_rotation: Vector3
var last_pull_dist: float = 0.0

const BOW_RESET_SPEED = 20.0
var bow_rot_t = 0.0

var _draw_sfx_played : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_offset = pullpoint.position.z
	bow_idle_rotation = rotation


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#stick to hand
	if get_parent() is Node3D:
		global_position = get_parent().global_position
	_bend_bow()
	
	match current_state:
		BowState.IDLE:
			## reset bow
			#var weight = 1 - ease_out_elastic(-BOW_RESET_SPEED * delta)
			#pullpoint.position.z = lerp(pullpoint.position.z, start_offset, weight)
			#
			## lerp rotation
			#weight = 1 - ease_out_expo(-BOW_RESET_SPEED * delta)
			#rotation = rotation.slerp(bow_idle_rotation, weight)
			
			## POSITIONING NOW HANDLED BY TWEENS IN LAUNCH CODE
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
			# face back hand
			look_at(TEST_HAND.global_position, get_parent().global_basis.y, true)
			# pull string
			pullpoint.global_position = TEST_HAND.global_position 
			
			var current_pull = pullpoint.position.z
			# if pulled back an extra 2cm, trigger a pulse
			if abs(current_pull - last_pull_dist) > 0.02:
				HapticManager.play(HapticManager.Vibration.BOW_TENSION, "right_hand")
				last_pull_dist = current_pull
			
			if abs(current_pull - start_offset) > 0.04:
				if not _draw_sfx_played:
					$shaft/draw_sfx.play()
					_draw_sfx_played = true
			else:
				_draw_sfx_played = false
				


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
				$shaft/nock_sfx.play()
			

func _bend_bow():
	# bend the bow
	var pull_delta = pullpoint.position.z - start_offset
	toptip.position.z = start_offset + (pull_delta / 7)
	bottomtip.position.z = start_offset + (pull_delta / 7)
	toptip.position.y = 0.5 - (pull_delta / 10)
	bottomtip.position.y = -0.5 + (pull_delta / 10)

	stretch_bow_arm($top_arm, $shaft/shaft_top.global_position, $toptip.global_position)
	stretch_bow_arm($bottom_arm, $shaft/shaft_bottom.global_position, $bottomtip.global_position)

func fire_arrow(_arrow: Node3D):
	if not first_shot_fired: SignalBus.shot_first_arrow.emit() 	# tutorial
	
	# sfx
	_draw_sfx_played = false
	$shaft/draw_sfx.stop()
	$shaft/release_sfx.play()
	
	var pull_dist = pullpoint.position.z - start_offset
	#var force = (pull_dist) * force_multiplier
	var force = (pull_dist) * GameStats.get_accuracy()
	force = force if force > 0.0 else 0.0
	
	held_arrow.reparent(get_tree().root, true)	
	print("LAUNCHING ARROW")
	
	var v_data = [clampf(pull_dist, 0.0, 1.0),
				clampf(pull_dist, 0.0, 1.0),
				clampf(pull_dist * 0.15, 0.0, 0.15)]
	HapticManager.vibrate(v_data, "left_hand")
	held_arrow.launch(force) 
	
	current_state = BowState.IDLE
	held_arrow = null
	
	var tween = create_tween().set_parallel(true)

	# string bounce
	tween.tween_property(pullpoint, "position:z", start_offset, 0.5)\
	.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# bow rotation
	tween.tween_property(self, "rotation", bow_idle_rotation, 0.3)\
	.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _on_right_hand_controller_button_released(button_name: String) -> void:
	if button_name == "trigger_click":
		if held_arrow and current_state == BowState.NOCKED:
			fire_arrow(held_arrow)


func _on_hand_area_arrow_spawned(arrow_node: Node3D, hand_area: Node3D) -> void:
	held_arrow = arrow_node
	arrow_hand = hand_area


func _on_hand_area_arrow_despawned(_arrow_node: Node3D, _hand_area: Node3D) -> void:
	held_arrow = null


func stretch_bow_arm(pivot: Node3D, start_point: Vector3, end_point: Vector3):
	pivot.global_position = start_point
	var dist = start_point.distance_to(end_point)

	var bow_up = global_transform.basis.y 
	pivot.look_at(end_point, bow_up)
	
	pivot.scale = Vector3(1.0, 1.0, dist)
