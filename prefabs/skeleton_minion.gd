extends Node3D

@onready var anim : AnimationPlayer = $AnimationPlayer
var spawned : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("Rig_Medium_Special/Skeletons_Spawn_Ground")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	spawned = true
