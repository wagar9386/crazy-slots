extends Node2D

@onready var grid = $Control/GridContainer
@onready var label_multiplier = $Control/Label_Multiplier
@onready var label_status = $Control/Label_Status
@onready var button_cashout = $Control/Button

var cell_scene = preload("res://Ian/Bonus/Minas/celda.tscn")

var cells = []

var multiplier = 1.0
var game_over = false

func _ready():
	create_grid()
	generate_mines()
	update_ui()
	button_cashout.pressed.connect(_on_button_cashout_pressed)

func create_grid():
	for i in range(25):  # 5x5
		var cell = cell_scene.instantiate()
		grid.add_child(cell)
		
		cells.append(cell)
		
		cell.connect("cell_pressed", Callable(self, "on_cell_pressed"))

func generate_mines():
	for cell in cells:
		cell.has_mine = randf() < 0.2

func on_cell_pressed(cell):
	if game_over:
		return

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

func _on_button_cashout_pressed():
	if game_over:
		return
	
	game_over = true
	label_status.text = "Ganado: x" + str(round(multiplier * 100) / 100.0)

func update_ui():
	label_multiplier.text = "x" + str(round(multiplier * 100) / 100.0)

func restart():
	multiplier = 1.0
	game_over = false
	label_status.text = ""

	for cell in cells:
		cell.reset()

	generate_mines()
	update_ui()
