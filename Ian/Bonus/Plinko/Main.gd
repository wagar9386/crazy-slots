extends Node2D

var pin_scene = preload("res://Ian/Bonus/Plinko/pin.tscn")
var ball_scene = preload("res://Ian/Bonus/Plinko/ball.tscn")
var slot_scene = preload("res://Ian/Bonus/Plinko/recipient.tscn")

@onready var label = $CanvasLayer/CreditsLabel
@onready var win_label = $CanvasLayer/WinLabel
@onready var bet_label = $CanvasLayer/BetLabel

const SLOT_FONT: Font = preload("res://Goti/assets/Cowboy Movie.ttf")
const SLOT_OUTLINE_FONT: Font = preload("res://Goti/assets/Cowboy Outlaw.otf")
const SLOT_COLOR: Color = Color(1.0, 0.9, 0.2, 1)

var rows = 16
var spacing_x = 32
var spacing_y = 32
var start_x = 300
var start_y = 100

var multipliers = [50, 30, 20, 10, 5, 2, 1, 0, -5, 0, 1, 2, 5, 10, 20, 30, 50]

var total_balls = 5
var finished_balls = 0
var total_win = 0


func _ready():
	finished_balls = 0
	total_win = 0

	win_label.visible = false
	apply_slotmachine_win_style(win_label)
	create_pins()
	create_slots()
	spawn_balls_sequence()


func create_pins():
	for y in range(rows):
		for x in range(3 + y):
			var pin = pin_scene.instantiate()
			add_child(pin)

			pin.position = Vector2(
				start_x + (x - (3 + y - 1) / 2.0) * spacing_x,
				start_y + y * spacing_y
			)

func play_big_win_countup(label: Label, value: int) -> void:
	label.visible = true
	label.text = "+0"

	# RESET EVERYTHING
	label.rotation = 0
	label.scale = Vector2.ONE
	label.modulate = Color.WHITE

	# HUGE SIZE
	label.custom_minimum_size = Vector2(1400, 400)
	label.size = Vector2(1400, 400)

	# FONT
	label.add_theme_font_override("font", SLOT_FONT)
	label.add_theme_font_size_override("font_size", 180)

	# GOLD COLOR
	label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.92, 0.25, 1)
	)

	# OUTLINE
	label.add_theme_constant_override("outline_size", 18)

	label.add_theme_color_override(
		"font_outline_color",
		Color(0.12, 0.03, 0.0, 1)
	)

	# CENTER ALIGNMENT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# FORCE FULL RECT
	label.set_anchors_preset(Control.PRESET_FULL_RECT)

	# CENTER IN SCREEN
	label.position = Vector2.ZERO
	label.size = get_viewport_rect().size

	# ANIMATION SETUP
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2(0.15, 0.15)
	label.modulate = Color(1, 1, 1, 0)

	var tween := create_tween()

	# BIG POP
	tween.tween_property(
		label,
		"scale",
		Vector2(1.45, 1.45),
		0.28
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(
		label,
		"modulate",
		Color(1,1,1,1),
		0.18
	)

	# SETTLE
	tween.tween_property(
		label,
		"scale",
		Vector2(1.08, 1.08),
		0.12
	).set_ease(Tween.EASE_IN)

	# COUNTUP
	tween.tween_method(
		func(v):
			if is_instance_valid(label):
				label.text = "+%d" % int(v),
		0.0,
		float(value),
		3.0
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# FINAL BOUNCE
	tween.tween_property(
		label,
		"scale",
		Vector2(1.22, 1.22),
		0.15
	).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		label,
		"scale",
		Vector2(1.0, 1.0),
		0.12
	).set_ease(Tween.EASE_IN)

	# GOLD SHIMMER
	var shimmer := create_tween().set_loops()

	shimmer.tween_property(
		label,
		"modulate",
		Color(1.0, 0.88, 0.2, 1),
		0.3
	)

	shimmer.tween_property(
		label,
		"modulate",
		Color(1.0, 0.98, 0.4, 1),
		0.3
	)

func create_slots():
	var y_pos = start_y + rows * spacing_y - 10

	for i in range(rows + 1):
		var slot = slot_scene.instantiate()
		add_child(slot)

		slot.position = Vector2(
			start_x + (i - rows / 2.0) * spacing_x,
			y_pos
		)

		slot.multiplier = multipliers[i]
		slot.update_label()


func spawn_ball():
	var ball = ball_scene.instantiate()
	add_child(ball)

	ball.position = Vector2(start_x, 50)


func spawn_balls_sequence():
	for i in range(total_balls):
		spawn_ball()
		await get_tree().create_timer(0.5).timeout


func register_ball_result(win):
	finished_balls += 1
	total_win += win

	if finished_balls >= total_balls:
		show_final_result()


func show_final_result():
	play_big_win_countup(win_label, total_win)

	var tween := create_tween()

	# small delay before exit
	tween.tween_interval(3.2)

	tween.tween_callback(func():
		win_label.visible = false
		win_label.modulate = Color(1,1,1,1)
		get_tree().change_scene_to_file("res://Goti/scenes/SlotMachine.tscn")
	)

func apply_slotmachine_win_style(label: Label) -> void:
	label.add_theme_font_override("font", SLOT_FONT)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", SLOT_COLOR)
	label.add_theme_constant_override("outline_size", 14)
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.03, 0.0))

func change_font_size(value, lbl):
	if is_instance_valid(lbl):
		lbl.add_theme_font_size_override("font_size", int(value))


func _process(delta):
	label.text = "Credits: " + str(GameState.credits)
	bet_label.text = "Bet: " + str(GameState.bet)
