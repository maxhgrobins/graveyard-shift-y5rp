extends Sprite3D

@export var max_health: int = 50
@onready var current_health: int = max_health
@onready var health_bar = $SubViewport/Panel/ProgressBar
@onready var ghost_bar = $SubViewport/Panel/ghost

signal damaged(amount: int, hit_zone: HitData.Zone, impact: Vector3)
signal health_depleted(amount: int, hit_zone: HitData.Zone, impact: Vector3)

func _ready() -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	ghost_bar.max_value = max_health
	ghost_bar.value = current_health


func take_damage(amount: int, zone: HitData.Zone, impact: Vector3):
	if zone == HitData.Zone.ARMOR:
		damaged.emit(0, zone, impact)
		return

	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	
	health_bar.value = current_health
	
	var tween = get_tree().create_tween()
	tween.tween_interval(0.4)
	
	tween.tween_property(ghost_bar, "value", current_health, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if current_health <= 0:
		health_depleted.emit(amount, zone, impact)
	else:
		damaged.emit(amount, zone, impact) 
		
