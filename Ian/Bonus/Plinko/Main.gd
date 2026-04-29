extends Node2D

var pin_scene = preload("res://Ian/Bonus/Plinko/pin.tscn")
var ball_scene = preload("res://Ian/Bonus/Plinko/ball.tscn")
var slot_scene = preload("res://Ian/Bonus/Plinko/recipient.tscn")

@onready var label = $CanvasLayer/Label
@onready var win_label = $CanvasLayer/WinLabel

var rows = 16
var spacing_x = 32
var spacing_y = 32
var start_x = 300
var start_y = 100

var multipliers = [50, 30, 20, 10, 5, 3, 2, 1, 0, 1, 2, 3, 5, 10, 20, 30, 50]

var total_balls = 5
var finished_balls = 0
var total_win = 0


func _ready():
	finished_balls = 0
	total_win = 0

	win_label.visible = false

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
	win_label.visible = true
	win_label.text = "WIN: " + str(total_win)

	win_label.add_theme_font_size_override("font_size", 10)

	win_label.pivot_offset = win_label.size / 2

	var tween = create_tween()

	tween.tween_method(change_font_size.bind(win_label), 10, 110, 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_method(change_font_size.bind(win_label), 110, 90, 0.2)
	tween.tween_method(change_font_size.bind(win_label), 90, 100, 0.2)

	tween.tween_property(win_label, "modulate", Color(1,1,1,0), 1.5)\
		.set_delay(1.0)

	tween.tween_callback(func():
		win_label.visible = false
		win_label.modulate = Color(1,1,1,1)
	)


func change_font_size(value, lbl):
	if is_instance_valid(lbl):
		lbl.add_theme_font_size_override("font_size", int(value))


func _process(delta):
	label.text = "Credits: " + str(GameState.credits)
