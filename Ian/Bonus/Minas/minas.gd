extends Node2D

@onready var grid = $Control/GridContainer
@onready var label_multiplier = $Control/Label_Multiplier
@onready var label_status = $Control/Label_Status
@onready var credits_label = $Control/CreditsLabel

@onready var button = $Control/Button
@onready var win_label = $Control/WinLabel


var cell_scene = preload("res://Ian/Bonus/Minas/celda.tscn")

var cells = []

var multiplier = 1.0
var game_over = false

var mine_chance = 0.20


func _ready():

	randomize()

	win_label.visible = false

	# PAGAR APUESTA
	if GameState.credits >= GameState.bet:
		GameState.credits -= GameState.bet
	else:
		label_status.text = "Sin dinero"
		return

	create_grid()
	generate_mines()
	update_ui()

	button.pressed.connect(_on_button_pressed)

func create_grid():

	for i in range(25):

		var cell = cell_scene.instantiate()

		grid.add_child(cell)

		cells.append(cell)

		cell.connect("cell_pressed", Callable(self, "on_cell_pressed"))


func generate_mines():

	for cell in cells:

		cell.has_mine = false

		if randf() < mine_chance:
			cell.has_mine = true


func on_cell_pressed(cell):

	if game_over:
		return

	if cell.revealed:
		return

	cell.revealed = true

	if cell.has_mine:

		cell.reveal_mine()

		lose()

	else:

		cell.reveal_safe()

		increase_multiplier()


func increase_multiplier():

	multiplier *= 1.2

	update_ui()


func lose():

	game_over = true

	multiplier = 0

	label_status.text = "Has perdido"

	update_ui()

	await get_tree().create_timer(2.0).timeout

	get_tree().change_scene_to_file("res://Goti/scenes/SlotMachine.tscn")


func _on_button_pressed():

	if game_over:
		return

	game_over = true

	var winnings = GameState.bet * multiplier

	GameState.credits += winnings

	update_ui()

	show_final_animation(winnings)

	await get_tree().create_timer(3.0).timeout

	get_tree().change_scene_to_file("res://Goti/scenes/SlotMachine.tscn")


func update_ui():

	label_multiplier.text = "x" + str(round(multiplier * 100) / 100.0)

	credits_label.text = "Credits: " + str(round(GameState.credits))


func restart():

	# BORRAR CELDAS
	for cell in cells:
		cell.queue_free()

	cells.clear()

	# RESET VARIABLES
	multiplier = 1.0
	game_over = false

	label_status.text = ""

	# PAGAR NUEVA APUESTA
	if GameState.credits >= GameState.bet:
		GameState.credits -= GameState.bet
	else:
		label_status.text = "Sin dinero"
		update_ui()
		return

	create_grid()
	generate_mines()
	update_ui()


func show_final_animation(win):

	win_label.visible = true

	win_label.text = "+0"

	win_label.add_theme_font_override(
		"font",
		preload("res://Goti/assets/Cowboy Movie.ttf")
	)

	win_label.add_theme_font_size_override("font_size", 120)

	win_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.9, 0.2, 1)
	)

	win_label.add_theme_constant_override(
		"outline_size",
		14
	)

	win_label.add_theme_color_override(
		"font_outline_color",
		Color(0.12, 0.03, 0.0)
	)

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
		2.0
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
