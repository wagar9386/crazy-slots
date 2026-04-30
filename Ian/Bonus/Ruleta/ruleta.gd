extends Node2D

@onready var wheel = $Sprite2D
@onready var label = $CanvasLayer/CreditsLabel
@onready var bet_label = $CanvasLayer/BetLabel
@onready var win_label = $CanvasLayer/WinLabel

var spinning = false

var sections = 8
var multipliers = [5, 10, 100, 50, 20, 10, 5, 2]

var final_result = 0
var rng = RandomNumberGenerator.new()

var angle_offset = 110


func _ready():
	rng.randomize()
	win_label.visible = false
	await get_tree().create_timer(1.0).timeout
	spin()


func spin():
	if spinning:
		return
	
	spinning = true
	
	final_result = rng.randi_range(0, sections - 1)
	
	var angle_per_section = 360.0 / sections
	
	var final_angle = (final_result * angle_per_section) + angle_per_section / 2.0 + angle_offset
	
	var current_rotation = wheel.rotation_degrees
	
	var target_rotation = current_rotation + 360 * 8
	
	target_rotation = target_rotation - fmod(target_rotation, 360) + final_angle
	
	var tween = create_tween()
	tween.tween_property(wheel, "rotation_degrees", target_rotation, 15.0)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		spinning = false
		apply_result(final_result)
	)


func _process(delta):
	label.text = "Coins: " + str(GameState.credits)
	bet_label.text = "Bet: " + str(GameState.bet)


func apply_result(result):
	var multiplier = multipliers[result]
	var win = GameState.bet * multiplier
	
	GameState.credits += win
	
	show_final_animation(win)
	
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://Goti/scenes/SlotMachine.tscn")


# 🎯 MISMA ANIMACIÓN QUE PLINKO PERO EN LABEL
func show_final_animation(win):
	win_label.visible = true
	win_label.text = "WIN: " + str(win)

	win_label.add_theme_font_size_override("font_size", 10)
	win_label.pivot_offset = win_label.size / 2

	var tween = create_tween()

	# 💥 aparece grande desde pequeño
	tween.tween_method(change_font_size.bind(win_label), 10, 110, 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	# 🔥 rebote
	tween.tween_method(change_font_size.bind(win_label), 110, 90, 0.2)
	tween.tween_method(change_font_size.bind(win_label), 90, 100, 0.2)

	# 💨 fade out
	tween.tween_property(win_label, "modulate", Color(1,1,1,0), 1.5)\
		.set_delay(1.0)

	tween.tween_callback(func():
		win_label.visible = false
		win_label.modulate = Color(1,1,1,1)
	)


func change_font_size(value, lbl):
	if is_instance_valid(lbl):
		lbl.add_theme_font_size_override("font_size", int(value))
