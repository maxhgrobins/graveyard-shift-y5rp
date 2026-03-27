extends Node

@onready var spawn = $"../arrow_spawn"
@onready var string_pull_animation = $"../AnimationTree"
@onready var fake_arrow = $"../Arrow"

@onready var is_grabbed := false
@onready var both_hands := false
@onready var hands = []	#TODO replace with prim and sec hand vars
@onready var hand_delta : float = 0

@export var spawned_arrow : PackedScene


func _process(delta: float) -> void:
	both_hands = hands.size() > 1
	
	if is_grabbed && both_hands:
		hand_delta = hands[0].global_position.distance_to(hands[1].global_position)
		
		hand_delta = remap(hand_delta, 0.154, 0.599, 0 ,1)	# magic numbers are start and end distance of hands
		hand_delta = clamp(hand_delta, 0, 1)
		fake_arrow.visible = true
		string_pull_animation["parameters/blend_position"] = hand_delta


func _on_bow_grabbed(pickable, by):
	if not hands.has(by):
		hands.append(by) # add the hand that grabbed to the hands
	is_grabbed = true
		
func _on_bow_released(pickable, by):
	if hands.has(by):
		hands.erase(by) # erase hand that let go from hands
	is_grabbed = true

	if hand_delta >= .2: #TODO replace magic number with fire threshold
		var new_arrow = spawned_arrow.instantiate()
		new_arrow.rotation = spawn.global_rotation
		new_arrow.position = spawn.global_position
		add_child(new_arrow)
		new_arrow.fire(hand_delta)
		hand_delta = 0
	
	string_pull_animation["parameters/blend_position"] = 0
	fake_arrow.visible = false

func _on_bow_dropped(pickable):
	is_grabbed = false
