extends Node2D

enum Symbol { A, B, C, D, E, G, Wild }

const GRID_ROWS: int = 4
const GRID_COLS: int = 5

const WEIGHTED_SYMBOLS: Array = [
	Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A,
	Symbol.B, Symbol.B, Symbol.B, Symbol.B,
	Symbol.C, Symbol.C, Symbol.C,
	Symbol.D, Symbol.D, Symbol.D,
	Symbol.E, Symbol.E,
	Symbol.G,
	Symbol.Wild
]

const SYMBOL_VALUES: Dictionary = {
	Symbol.A: 3,
	Symbol.B: 6,
	Symbol.C: 9,
	Symbol.D: 9,
	Symbol.E: 12,
	Symbol.G: 30,
	Symbol.Wild: 20
}

const SYMBOL_TEXTURES: Dictionary = {
	Symbol.A: preload("res://symbols/cherries.png"),
	Symbol.B: preload("res://symbols/diamond.png"),
	Symbol.C: preload("res://symbols/grapes.png"),
	Symbol.D: preload("res://symbols/lemon.png"),
	Symbol.E: preload("res://symbols/orange.png"),
	Symbol.G: preload("res://symbols/seven.png"),
	Symbol.Wild: preload("res://symbols/wild.png")
}

const SYMBOL_MODULATION: Dictionary = {
	Symbol.G: Color(1, 0.85, 0.4),
	Symbol.Wild: Color(1, 1, 1)
}

var grid: Array = []
var symbol_nodes: Array = []
var credits: int = 100
@export var bet: int = 4
var is_spinning: bool = false

@onready var reel_grid: GridContainer = get_node("SlotMachine#UILayer/UILayer#SlotsUI/SlotsUI#ReelGrid") as GridContainer
@onready var hud_controls: HBoxContainer = get_node("SlotMachine#UILayer/UILayer#SlotsUI/HUD/HUDControls") as HBoxContainer
@onready var credits_label: Label = hud_controls.get_node("CreditsLabel") as Label
@onready var spin_button: Button = hud_controls.get_node("SpinButton") as Button

func _ready() -> void:
	randomize()
	if bet < 4:
		bet = 4
	gather_symbol_nodes()
	spin_button.pressed.connect(_on_spin_pressed)
	generate_grid()
	update_display_grid()
	update_ui()

func gather_symbol_nodes() -> void:
	symbol_nodes.clear()
	var cells: Array = reel_grid.get_children()
	for row in range(GRID_ROWS):
		var row_nodes: Array = []
		for column in range(GRID_COLS):
			var index: int = row * GRID_COLS + column
			var texture_node: TextureRect = null
			if index < cells.size():
				var cell: Node = cells[index]
				if cell.get_child_count() > 0:
					var center = cell.get_child(0)
					if center and center.get_child_count() > 0:
						texture_node = center.get_child(0) as TextureRect
			row_nodes.append(texture_node)
		symbol_nodes.append(row_nodes)

func generate_grid() -> void:
	grid.resize(GRID_COLS)
	for column in range(GRID_COLS):
		grid[column] = []
		for row in range(GRID_ROWS):
			grid[column].append(get_random_symbol())

func update_display_grid() -> void:
	for row in range(GRID_ROWS):
		for column in range(GRID_COLS):
			var symbol: int = grid[column][row]
			var node: TextureRect = symbol_nodes[row][column]
			if node:
				node.texture = SYMBOL_TEXTURES.get(symbol)
				node.self_modulate = SYMBOL_MODULATION.get(symbol, Color(1, 1, 1))

func get_random_symbol() -> int:
	var index: int = randi() % WEIGHTED_SYMBOLS.size()
	return WEIGHTED_SYMBOLS[index]

func spin() -> void:
	if is_spinning:
		return
	is_spinning = true
	spin_button.disabled = true
	
	for i in range(15):
		for row in range(GRID_ROWS):
			for column in range(GRID_COLS):
				var random_sym: int = get_random_symbol()
				var node: TextureRect = symbol_nodes[row][column]
				if node:
					node.texture = SYMBOL_TEXTURES.get(random_sym)
					node.self_modulate = SYMBOL_MODULATION.get(random_sym, Color(1, 1, 1))
		await get_tree().create_timer(0.05).timeout

	generate_grid()
	var win: int = check_win()
	credits -= bet
	if credits <= 0:
		credits += 10
		print("No cash pity +10")
	else:
		credits += win
	update_display_grid()
	debug_grid()
	if win >= 100:
		print("MEGA WIN!!! %d" % win)
	elif win >= 50:
		print("BIG WIN! %d" % win)
	elif win > 0:
		print("Win: %d" % win)
	update_ui()
	print("Credits: %d" % credits)
	
	is_spinning = false
	spin_button.disabled = false

func check_win() -> int:
	var total_win: int = 0
	for row in range(GRID_ROWS):
		var row_win: int = check_row(row)
		if row_win > 0:
			print("Row %d WIN → %d" % [row, row_win])
		total_win += row_win
	return total_win

func check_row(row: int) -> int:
	var wild_count: int = count_wild_cluster(row)
	if wild_count >= 3:
		var wild_value: int = get_symbol_value(Symbol.Wild)
		var multiplier: int = 0
		match wild_count:
			3:
				multiplier = 3
			4:
				multiplier = 6
			5:
				multiplier = 10
		return wild_value * multiplier
	var base_symbol: int = grid[0][row]
	var count: int = 1
	for column in range(1, GRID_COLS):
		var current: int = grid[column][row]
		if current == Symbol.Wild or current == base_symbol:
			count += 1
		else:
			break
	if count < 3:
		return 0
	return calculate_payout(base_symbol, count)

func count_wild_cluster(row: int) -> int:
	var total: int = 0
	for column in range(GRID_COLS):
		if grid[column][row] == Symbol.Wild:
			total += 1
		else:
			break
	return total

func calculate_payout(symbol: int, count: int) -> int:
	var base_value: int = get_symbol_value(symbol)
	var multiplier: int = 0
	match count:
		3:
			multiplier = 1
		4:
			multiplier = 3
		5:
			multiplier = 6
	return base_value * multiplier

func get_symbol_value(symbol: int) -> int:
	return SYMBOL_VALUES.get(symbol, 0)

func update_ui() -> void:
	credits_label.text = "Credits: %d" % credits

func debug_grid() -> void:
	for row in range(GRID_ROWS):
		var line: String = ""
		for column in range(GRID_COLS):
			line += "%s " % symbol_to_label(grid[column][row])
		print(line)

func symbol_to_label(symbol: int) -> String:
	match symbol:
		Symbol.A:
			return "A"
		Symbol.B:
			return "B"
		Symbol.C:
			return "C"
		Symbol.D:
			return "D"
		Symbol.E:
			return "E"
		Symbol.G:
			return "G"
		Symbol.Wild:
			return "W"
	return "?"

func _on_spin_pressed() -> void:
	spin()
