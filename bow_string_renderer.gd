extends Node

@onready var _top_line_helper : Node3D = $"../toptip/TopLineHelper"
@onready var _top_line : CSGCylinder3D = $"../toptip/TopLineHelper/TopLine"

@onready var _bottom_line_helper : Node3D = $"../bottomtip/BottomLineHelper"
@onready var _bottom_line : CSGCylinder3D = $"../bottomtip/BottomLineHelper/BottomLine"

@onready var _tt : Node3D = $"../toptip"
@onready var _bt : Node3D = $"../bottomtip"
@onready var _pp : Node3D = $"../pullpoint"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var _tt_pos := _tt.global_position
	var _bt_pos := _bt.global_position
	var _pp_pos := _pp.global_position
	
	var top_line_length := (_tt_pos - _pp_pos).length()
	var bottom_line_length := (_bt_pos - _pp_pos).length()
	
	_top_line_helper.look_at(_pp_pos, Vector3.UP)
	_top_line.height = top_line_length
	_top_line.position.z = top_line_length / -2
	
	_bottom_line_helper.look_at(_pp_pos, Vector3.UP)
	_bottom_line.height = bottom_line_length
	_bottom_line.position.z = bottom_line_length / -2
