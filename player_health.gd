extends Node

@onready var camera = $"../XRCamera3D"
@onready var fade_sphere = $"../XRCamera3D/GameOverSphere"

var health : int = 1
var is_alive : bool = true

var last_damage_source : Node3D

func _ready() -> void:
	GameStats.increase_health.connect(_increase_health)
	fade_sphere.get_active_material(0).albedo_color.a = 0.0
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if health <= 0 and is_alive:
		_die()


func _die():
	is_alive = false
	print("DEAD")
	SignalBus.game_over.emit()
	game_over()


func _on_head_hitbox_area_entered(area: Area3D) -> void:
	last_damage_source = area.get_parent()
	
	if health > 0:
		area.get_parent().queue_free()	#TODO this is a hack
	else:
		area.get_parent().process_mode = Node.PROCESS_MODE_DISABLED
	
# TODO FINISH THIS
func _increase_health():
	health += 1
	update_health_visual()

# UNFINISHED
func take_damage(amount : int):
	health -= 1
	update_health_visual()

func update_health_visual():
	print("health: ",health)
	pass

func game_over():
	get_tree().paused = true
	var tween = get_tree().create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	var sphere_mat = fade_sphere.get_active_material(0)
	tween.tween_property(sphere_mat, "albedo_color:a", 1.0, 3.0)
	
	highlight_killer(last_damage_source)
	
	spawn_game_over_text(tween)


func highlight_killer(enemy: Node3D):	
	var overlay_mat = StandardMaterial3D.new()
	overlay_mat.no_depth_test = true 
	
	overlay_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED 
	overlay_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay_mat.render_priority = 100
	
	for child in enemy.find_children("*", "MeshInstance3D"):
		child.material_overlay = overlay_mat
		
		
func spawn_game_over_text(tween: Tween):
	var title = Label3D.new()
	title.text = "GAME OVER"
	title.font_size = 64
	title.modulate = Color(1, 1, 1, 0)
	title.no_depth_test = true
	title.render_priority = 100
	
	var subtitle = Label3D.new()
	subtitle.text = "Nights Survived: " + str(GameStats.get_current_night())
	subtitle.font_size = 32 # Smaller font for a cleaner look
	subtitle.no_depth_test = true 
	subtitle.render_priority = 100 
	subtitle.modulate = Color(1, 1, 1, 0) 
	
	add_child(subtitle)
	add_child(title)
	
	var center_point = camera.global_position + (-camera.global_transform.basis.z * 2.0)
	
	title.global_transform.basis = camera.global_transform.basis
	subtitle.global_transform.basis = camera.global_transform.basis
	
	title.global_position = center_point + (camera.global_transform.basis.y * 0.2)
	subtitle.global_position = center_point - (camera.global_transform.basis.y * 0.2)
	
	tween.tween_property(title, "modulate:a", 1.0, 3.0)
	tween.tween_property(subtitle, "modulate:a", 1.0, 3.0)
	
	tween.tween_callback(restart_level).set_delay(5.0)
	

func restart_level():
	get_tree().paused = false 
	if is_instance_valid(last_damage_source):
		last_damage_source.queue_free()
	get_tree().reload_current_scene()
