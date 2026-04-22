extends CharacterBody2D

signal personatge_mort

@export var animacio: Node
@export var area_2d: Area2D

var _velocidad: float = 100.0
var _velocitat_salt: float = -300.0
var _mort: bool


func _ready() -> void:
	add_to_group("personatges")
	area_2d.body_entered.connect(_on_area_2d_body_entered)

func _physics_process(delta):
	#mort
	if _mort:
		return

	#gravetat
	velocity += get_gravity() * delta
	
	#salt
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = _velocitat_salt
		
	#moviment lateral
	if Input.is_action_pressed("dreta"):
		velocity.x = _velocidad
		animacio.flip_h = true
	elif Input.is_action_pressed("esquerra"):
		velocity.x = -_velocidad
		animacio.flip_h = false
	else:
		velocity.x = 0
	move_and_slide()
	
	#animacio
	if !is_on_floor():
		animacio.play("saltar")
	elif velocity.x != 0:
		animacio.play("caminar")
	else:
		animacio.play("idle")


func _on_area_2d_body_entered(body: Node2D) -> void:
	animacio.modulate = Color(11.241, 0.001, 0.001, 1.0)
	_mort = true
	animacio.stop()
	
	await get_tree().create_timer(0.5).timeout
	personatge_mort.emit()
	
	
	
	
	
