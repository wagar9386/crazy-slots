extends Node2D

@onready var wheel = $Sprite2D
@onready var label = $CanvasLayer/CreditsLabel
@onready var bet_label = $CanvasLayer/BetLabel

var spinning = false

var sections = 8
var multipliers = [5, 10, 100, 50, 20, 10, 5, 2]

var final_result = 0

var rng = RandomNumberGenerator.new()

# 🔧 AJUSTA ESTO SEGÚN TU FLECHA
var angle_offset = 110


func _ready():
	rng.randomize()


func spin():
	if spinning:
		return
	
	spinning = true
	
	final_result = rng.randi_range(0, sections - 1)
	
	var angle_per_section = 360.0 / sections
	
	# 🎯 Ángulo final EXACTO
	var final_angle = (final_result * angle_per_section) + angle_per_section / 2.0 + angle_offset
	
	# Rotación actual
	var current_rotation = wheel.rotation_degrees
	
	# Queremos girar varias vueltas + llegar al resultado
	var target_rotation = current_rotation + 360 * 8
	
	# Ajustamos para que termine EXACTO en final_angle
	target_rotation = target_rotation - fmod(target_rotation, 360) + final_angle
	
	# 🎬 ANIMACIÓN REAL (SIN ERRORES)
	var tween = create_tween()
	tween.tween_property(wheel, "rotation_degrees", target_rotation, 15.0)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		spinning = false
		print("Resultado:", final_result)
		apply_result(final_result)
	)


func _process(delta):
	label.text = "Coins: " + str(GameState.credits)
	bet_label.text = "Bet: " + str(GameState.bet)


func apply_result(result):
	var multiplier = multipliers[result]
	var win = GameState.bet * multiplier
	
	GameState.credits += win
	
	print("Multiplicador:", multiplier)
	print("Ganancia:", win)
	
	show_win_effect(win)


func show_win_effect(win):
	var popup = Label.new()
	popup.text = "+" + str(win)
	add_child(popup)

	popup.position = Vector2(300, 200)
	popup.z_index = 10

	var tween = create_tween()
	tween.tween_property(popup, "position", popup.position + Vector2(0, -80), 1.0)
	tween.parallel().tween_property(popup, "modulate", Color(1,1,1,0), 1.0)
	tween.tween_callback(popup.queue_free)


func _on_button_pressed() -> void:
	spin()
