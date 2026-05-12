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

var mine_chance = 0.15


func _ready():

	randomize()

	win_label.visible = false

	# PAGAR APUESTA
	if GameState.credits >= GameState.bet:
		GameState.credits -= GameState.bet
	else:
		label_status.text = "Sin dinero"
		push_warning("Minas: Insufficient credits. Credits: %d, Bet: %d" % [GameState.credits, GameState.bet])
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

	multiplier *= 3.3

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
		push_warning("Minas restart: Insufficient credits. Credits: %d, Bet: %d" % [GameState.credits, GameState.bet])
		update_ui()
		return

	create_grid()
	generate_mines()
	update_ui()


func show_final_animation(win: int) -> void:
	GameState.show_bonus_countup_animation(self, win)
