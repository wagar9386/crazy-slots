# Main.gd
extends Node2D

@onready var grid = $Control/GridContainer
@onready var label_multiplier = $Control/Label_Multiplier
@onready var label_status = $Control/Label_Status
@onready var label_credits = $Control/Label_credits
@onready var button_cashout = $Control/Button_Cashout
@onready var button_restart = $Control/Button_Restart

var cell_scene = preload("res://Ian/Bonus/Minas/celda.tscn")

var cells = []

var multiplier = 1.0
var game_over = false

func _ready():
	randomize()

	# PAGAR APUESTA AL ENTRAR
	if GameState.credits >= GameState.bet:
		GameState.credits -= GameState.bet
	else:
		label_status.text = "Sin dinero"
		return

	create_grid()
	generate_mines()
	update_ui()

	button_cashout.pressed.connect(_on_button_cashout_pressed)
	button_restart.pressed.connect(restart)

func create_grid():
	for i in range(25):

		var cell = cell_scene.instantiate()

		grid.add_child(cell)

		cells.append(cell)

		cell.connect("cell_pressed", Callable(self, "on_cell_pressed"))

func generate_mines():

	for cell in cells:

		cell.has_mine = false

		if randf() < 0.2:
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

	label_status.text = "💥 Has perdido"

	update_ui()

func _on_button_cashout_pressed():

	if game_over:
		return

	game_over = true

	var winnings = GameState.bet * multiplier

	GameState.credits += winnings

	label_status.text = "💰 Ganado: $" + str(round(winnings))

	update_ui()

func update_ui():

	label_multiplier.text = "x" + str(round(multiplier * 100) / 100.0)

	label_credits.text = "$" + str(round(GameState.credits))

func restart():

	# LIMPIAR TABLERO
	for cell in cells:
		cell.queue_free()

	cells.clear()

	# RESET VARIABLES
	multiplier = 1.0
	game_over = false

	label_status.text = ""

	# COMPROBAR DINERO
	if GameState.credits >= GameState.bet:
		GameState.credits -= GameState.bet
	else:
		label_status.text = "Sin dinero"
		update_ui()
		return

	create_grid()
	generate_mines()
	update_ui()
