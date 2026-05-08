extends Node

@onready var camera = $"../XRCamera3D"
@onready var fade_sphere = $"../XRCamera3D/GameOverSphere"
@onready var health_label = $"../right hand controller/RightHand/health_label"

var health : int = 1
var is_alive : bool = true

var last_damage_source : Node3D
var damage_tween: Tween
var label_tween: Tween

func _ready() -> void:
	SignalBus.change_health.connect(change_health)
	SignalBus.game_win.connect(game_over)
	fade_sphere.get_active_material(0).albedo_color.a = 0.0
	update_health_visual()
	

func _die():
	is_alive = false
	print("DEAD")
	SignalBus.game_over.emit()
	game_over()


func _on_head_hitbox_area_entered(area: Area3D) -> void:
	change_health(-1, area.owner)
	if health > 0:
		area.get_parent().queue_free()	#TODO this is a hack
	else:
		area.get_parent().process_mode = Node.PROCESS_MODE_DISABLED
	
	
func change_health(change : int, source : Node3D):
	if change < 0:
		$"../hit_sfx".play()
	health += change
	last_damage_source = source
	if health <= 0:
		health = 0
		_die()
	else:	# if head or axe and didnt kill, destroy
		if source and source.is_in_group("enemy_projectiles"):
			source.queue_free()
	update_health_visual(change)

func update_health_visual(change : int = 0):
	health_label.text = str(health)
	var label_colour = Color(0.051, 0.76, 0.0, 1.0)
	
	if change < 0:
		if is_alive:
			# screen flash
			var mat = fade_sphere.get_active_material(0)

			if damage_tween and damage_tween.is_running():
				damage_tween.kill()
				
			damage_tween = get_tree().create_tween()
			mat.albedo_color = Color(1.0, 0.0, 0.0, 0.0)
			
			damage_tween.tween_property(mat, "albedo_color:a", 0.4, 0.1)
			damage_tween.tween_property(mat, "albedo_color:a", 0.0, 0.4)
			
			damage_tween.tween_callback(func(): mat.albedo_color = Color(0.0, 0.0, 0.0, 0.0))

		label_colour = Color(1.0, 0.0, 0.0, 1.0)
		
	# label flash		
	if label_tween and label_tween.is_running():
		label_tween.kill()
		
	label_tween = get_tree().create_tween()

	health_label.modulate = label_colour

	label_tween.tween_property(health_label, "modulate", Color(1, 1, 1), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	print("health: ",health)

func game_over():
	get_tree().paused = true
	var tween = get_tree().create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	var sphere_mat = fade_sphere.get_active_material(0)
	sphere_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.0)
	if damage_tween and damage_tween.is_running():
		damage_tween.kill()
	tween.tween_property(sphere_mat, "albedo_color:a", 1.0, 3.0)
	
	if health <= 0:
		highlight_killer(last_damage_source)
		spawn_game_over_text(tween, false)
	else:
		spawn_game_over_text(tween, true)


func highlight_killer(enemy: Node3D):	
	var overlay_mat = StandardMaterial3D.new()
	overlay_mat.no_depth_test = true 
	
	overlay_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED 
	overlay_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay_mat.render_priority = 100
	overlay_mat.albedo_color = Color(1.0, 0.0, 0.0, 0.8)
	
	for child in enemy.find_children("*", "MeshInstance3D"):
		child.material_overlay = overlay_mat
		
		
func spawn_game_over_text(tween: Tween, is_win : bool):
	var title = Label3D.new()
	title.text = "GAME OVER"
	title.font_size = 64
	title.modulate = Color(1, 1, 1, 0)
	title.no_depth_test = true
	title.render_priority = 100
	
	var subtitle = Label3D.new()
	subtitle.text = "Nights Survived: " + str(GameStats.get_current_night())
	subtitle.font_size = 32
	subtitle.no_depth_test = true 
	subtitle.render_priority = 100 
	subtitle.modulate = Color(1, 1, 1, 0) 
	
	if is_win:
		title.text = "YOU SURVIVED!"
		subtitle.text = "You defended the graveyard from "+ str(GameStats.skeletons_killed) +" skeletons"
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
