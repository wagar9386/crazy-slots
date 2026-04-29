extends Node2D

@onready var wheel = $Sprite2D

var spinning = false
var speed = 0.0
var target_rotation = 0.0
var sections = 8
var multipliers = [5, 10, 100, 50, 20, 10, 5, 2]
var final_result = 0
var angle_offset = -110
@onready var label = $CanvasLayer/CreditsLabel
@onready var bet_label = $CanvasLayer/BetLabel


func spin():
	if spinning:
		return
	
	spinning = true
	
	final_result = randi() % sections
	
	var angle_per_section = 360.0 / sections
	
	var current_rotation = fmod(wheel.rotation_degrees, 360.0)
	var final_angle = (final_result * angle_per_section) + angle_per_section / 2.0
	
	var delta = fmod((final_angle - current_rotation + 360.0), 360.0)
	
	target_rotation = wheel.rotation_degrees + delta + (360 * 8)
	
	speed = 30.0


func _process(delta):
	label.text = "Coins: " + str(GameState.credits)
	bet_label.text = "Bet: " + str(GameState.bet)
	if spinning:
		wheel.rotation_degrees += speed
		
		speed = lerp(speed, 0.0, 0.01)
		
		var remaining = target_rotation - wheel.rotation_degrees
		
		if remaining <= 0.5 or speed < 0.01:
			spinning = false
			
			var result = get_result()
			print("Resultat real:", result)
			
			apply_result(result)


func get_result():
	var angle = fmod(wheel.rotation_degrees + angle_offset + 360.0, 360.0)
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

	popup.position = Vector2(300, 200)
	popup.scale = Vector2(1.5, 1.5)
	popup.z_index = 10

	var tween = create_tween()
	tween.tween_property(popup, "position", popup.position + Vector2(0, -80), 1.0)
	tween.parallel().tween_property(popup, "modulate", Color(1,1,1,0), 1.0)
	tween.tween_callback(popup.queue_free)


func _on_button_pressed() -> void:
	spin() 
