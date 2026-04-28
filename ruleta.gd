extends Node2D

@onready var wheel = $Sprite2D

var spinning = false
var speed = 0.0
var target_rotation = 0.0

var sections = 8 # número de parts de la ruleta

func spin():
	print("SPIN CRIDAT")
	if spinning:
		return
	
	spinning = true
	
	# escollim un resultat random
	var result = randi() % sections
	
	# calculem angle final
	var angle_per_section = 360.0 / sections
	target_rotation = 360 * 5 + (result * angle_per_section)
	
	speed = 20.0

func _process(delta):
	if spinning:
		wheel.rotation_degrees += speed
		
		# frenar poc a poc
		speed = lerp(speed, 0.0, 0.01)
		
		if wheel.rotation_degrees >= target_rotation:
			spinning = false
			wheel.rotation_degrees = target_rotation
			print("Resultat:", get_result())

func get_result():
	var angle = int(wheel.rotation_degrees) % 360
	var angle_per_section = 360.0 / sections
	
	return int(angle / angle_per_section)


func _on_button_pressed() -> void:
	spin() # Replace with function body.
