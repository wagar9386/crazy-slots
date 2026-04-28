extends Node2D

@onready var wheel = $Sprite2D

var spinning = false
var speed = 0.0
var target_rotation = 0.0

var sections = 8

# Multiplicadors (mateix nombre que sections)
var multipliers = [0, 1, 2, 5, 10, 5, 2, 1]

func spin():
	print("SPIN CRIDAT")
	
	if spinning:
		return
	
	spinning = true
	
	# resultat random
	var result = randi() % sections
	
	# angle per secció
	var angle_per_section = 360.0 / sections
	
	# fem que giri varies voltes + resultat final
	target_rotation = wheel.rotation_degrees + (360 * 5) + (result * angle_per_section)
	
	speed = 20.0


func _process(delta):
	if spinning:
		wheel.rotation_degrees += speed
		
		# frenar poc a poc
		speed = lerp(speed, 0.0, 0.01)
		
		if wheel.rotation_degrees >= target_rotation:
			spinning = false
			wheel.rotation_degrees = target_rotation
			
			var result = get_result()
			print("Resultat:", result)
			
			apply_result(result)


func get_result():
	var angle = fmod(wheel.rotation_degrees, 360.0)
	var angle_per_section = 360.0 / sections
	
	return int(angle / angle_per_section)


func apply_result(result):
	var multiplier = multipliers[result]
	var win = GameState.bet * multiplier
	
	GameState.credits += win
	
	print("Multiplicador:", multiplier)
	print("Guany:", win)
	
	show_win_effect(win)


func show_win_effect(win):
	var popup = Label.new()
	popup.text = "+" + str(win)
	add_child(popup)

	# POSICIÓ (ajusta si vols)
	popup.position = Vector2(300, 200)
	popup.scale = Vector2(1.5, 1.5)
	popup.z_index = 10

	var tween = create_tween()
	tween.tween_property(popup, "position", popup.position + Vector2(0, -80), 1.0)
	tween.parallel().tween_property(popup, "modulate", Color(1,1,1,0), 1.0)
	tween.tween_callback(popup.queue_free)


func _on_button_pressed() -> void:
	spin()
