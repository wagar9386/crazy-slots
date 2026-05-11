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
	await get_tree().create_timer(4.0).timeout
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


func show_final_animation(win):

	win_label.visible = true
	win_label.text = "+0"

	# SAME SLOT MACHINE STYLE
	win_label.add_theme_font_override("font", preload("res://Goti/assets/Cowboy Movie.ttf"))
	win_label.add_theme_font_size_override("font_size", 120)
	win_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1))
	win_label.add_theme_constant_override("outline_size", 14)
	win_label.add_theme_color_override("font_outline_color", Color(0.12, 0.03, 0.0))

	win_label.pivot_offset = win_label.size * 0.5
	win_label.scale = Vector2(0.2, 0.2)
	win_label.modulate = Color(1,1,1,0)

	var tween := create_tween()

	# POP
	tween.tween_property(
		win_label,
		"scale",
		Vector2(1.35, 1.35),
		0.24
	).set_ease(Tween.EASE_OUT)\
	 .set_trans(Tween.TRANS_BACK)

	tween.parallel().tween_property(
		win_label,
		"modulate",
		Color(1,1,1,1),
		0.18
	)

	tween.tween_property(
		win_label,
		"scale",
		Vector2(1.05, 1.05),
		0.10
	)

	# COUNTUP
	tween.tween_method(
		func(v):
			if is_instance_valid(win_label):
				win_label.text = "+%d" % int(v),
		0.0,
		float(win),
		3.0
	).set_trans(Tween.TRANS_QUAD)\
	 .set_ease(Tween.EASE_OUT)

	# BOUNCE
	tween.tween_property(
		win_label,
		"scale",
		Vector2(1.25, 1.25),
		0.14
	)

	tween.tween_property(
		win_label,
		"scale",
		Vector2(1.05, 1.05),
		0.10
	)

	# SHIMMER LOOP
	var shimmer := create_tween().set_loops()

	shimmer.tween_property(
		win_label,
		"modulate",
		Color(1.0, 0.85, 0.2, 1),
		0.3
	)

	shimmer.tween_property(
		win_label,
		"modulate",
		Color(0.987, 0.828, 0.0, 1.0),
		0.3
	)

func change_font_size(value, lbl):
	if is_instance_valid(lbl):
		lbl.add_theme_font_size_override("font_size", int(value))
