class_name SlotMachine
extends Node2D

enum Symbol { A, B, C, D, E, G, Wild }

const GRID_ROWS: int = 4
const GRID_COLS: int = 5
const MIN_BET: int = 4
const BET_OPTIONS: Array[int] = [4, 8, 16, 30]
const BASE_CELL_COLOR: Color = Color(0.07, 0.08, 0.15, 1.0)

const WEIGHTED_SYMBOLS: Array[int] = [
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

var grid: Array = []
var symbol_nodes: Array = []
var cell_nodes: Array = []
var credits: int = 100
@export var bet: int = MIN_BET
var is_spinning: bool = false

var animator: SlotSpinAnimator

@onready var reel_grid: GridContainer = get_node("UILayer/SlotsUI/ReelGrid") as GridContainer
@onready var hud_controls: HBoxContainer = get_node("UILayer/SlotsUI/HUD/HUDControls") as HBoxContainer
@onready var credits_label: Label = hud_controls.get_node("CreditsLabel") as Label
@onready var bet_label: Label = hud_controls.get_node("BetLabel") as Label
@onready var spin_button: Button = hud_controls.get_node("SpinButton") as Button
@onready var bet_4_button: Button = hud_controls.get_node("BetButtons/Bet4Button") as Button
@onready var bet_8_button: Button = hud_controls.get_node("BetButtons/Bet8Button") as Button
@onready var bet_16_button: Button = hud_controls.get_node("BetButtons/Bet16Button") as Button
@onready var bet_30_button: Button = hud_controls.get_node("BetButtons/Bet30Button") as Button

func _ready() -> void:
	randomize()
	if bet < MIN_BET:
		bet = MIN_BET
	if not BET_OPTIONS.has(bet):
		bet = MIN_BET
	gather_grid_nodes()
	set_symbol_pivots()

	animator = SlotSpinAnimator.new()
	add_child(animator)
	animator.setup(symbol_nodes, get_random_symbol, SYMBOL_TEXTURES)
	animator.spin_completed.connect(_on_spin_completed)

	spin_button.pressed.connect(_on_spin_pressed)
	bet_4_button.pressed.connect(_on_bet_button_pressed.bind(4))
	bet_8_button.pressed.connect(_on_bet_button_pressed.bind(8))
	bet_16_button.pressed.connect(_on_bet_button_pressed.bind(16))
	bet_30_button.pressed.connect(_on_bet_button_pressed.bind(30))

	generate_grid()
	update_display_grid()
	clear_cell_highlights()
	update_ui()

func gather_grid_nodes() -> void:
	symbol_nodes.clear()
	cell_nodes.clear()
	var cells: Array[Node] = reel_grid.get_children()
	for row in range(GRID_ROWS):
		var row_symbol_nodes: Array = []
		var row_cell_nodes: Array = []
		for column in range(GRID_COLS):
			var index: int = row * GRID_COLS + column
			var texture_node: TextureRect = null
			var cell_rect: ColorRect = null
			if index < cells.size():
				var cell_node: Node = cells[index]
				cell_rect = cell_node as ColorRect
				if cell_node.get_child_count() > 0:
					var center: Node = cell_node.get_child(0)
					if center.get_child_count() > 0:
						texture_node = center.get_child(0) as TextureRect
			row_symbol_nodes.append(texture_node)
			row_cell_nodes.append(cell_rect)
		symbol_nodes.append(row_symbol_nodes)
		cell_nodes.append(row_cell_nodes)

func set_symbol_pivots() -> void:
	for row in range(GRID_ROWS):
		for column in range(GRID_COLS):
			var node: TextureRect = symbol_nodes[row][column] as TextureRect
			if node != null:
				node.pivot_offset = node.custom_minimum_size * 0.5

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
			var node: TextureRect = symbol_nodes[row][column] as TextureRect
			if node != null:
				node.texture = SYMBOL_TEXTURES.get(symbol)
				node.self_modulate = Color.WHITE

func get_random_symbol() -> int:
	var index: int = randi() % WEIGHTED_SYMBOLS.size()
	return WEIGHTED_SYMBOLS[index]

func spin() -> void:
	if is_spinning:
		return
	is_spinning = true
	spin_button.disabled = true
	set_bet_buttons_disabled(true)
	clear_cell_highlights()
	generate_grid()
	animator.start_spin(grid)

func _on_spin_completed() -> void:
	var win_result: Dictionary = evaluate_wins()
	var base_win: int = win_result.get("total_win", 0) as int
	var scaled_win: int = scale_win_by_bet(base_win)
	var winning_lines: Array = win_result.get("lines", []) as Array

	credits -= bet
	if credits <= 0:
		credits += 10
		print("No cash pity +10")
	else:
		credits += scaled_win

	update_display_grid()
	animate_winning_cells(winning_lines)
	debug_grid()

	if scaled_win >= 100:
		print("MEGA WIN!!! %d" % scaled_win)
	elif scaled_win >= 50:
		print("BIG WIN! %d" % scaled_win)
	elif scaled_win > 0:
		print("Win: %d" % scaled_win)

	update_ui()
	print("Credits: %d" % credits)

	is_spinning = false
	spin_button.disabled = false
	set_bet_buttons_disabled(false)

func evaluate_wins() -> Dictionary:
	var total_win: int = 0
	var line_results: Array = []
	for row in range(GRID_ROWS):
		var row_result: Dictionary = evaluate_row(row)
		var row_win: int = row_result.get("win", 0) as int
		if row_win > 0:
			print("Row %d WIN → %d" % [row, scale_win_by_bet(row_win)])
			total_win += row_win
			line_results.append(row_result)
	return {
		"total_win": total_win,
		"lines": line_results
	}

func evaluate_row(row: int) -> Dictionary:
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
		return {
			"row": row,
			"count": wild_count,
			"win": wild_value * multiplier,
			"symbol": Symbol.Wild
		}

	var base_symbol: int = grid[0][row]
	var count: int = 1
	for column in range(1, GRID_COLS):
		var current: int = grid[column][row]
		if current == Symbol.Wild or current == base_symbol:
			count += 1
		else:
			break

	if count < 3:
		return {
			"row": row,
			"count": 0,
			"win": 0,
			"symbol": base_symbol
		}

	return {
		"row": row,
		"count": count,
		"win": calculate_payout(base_symbol, count),
		"symbol": base_symbol
	}

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
	return SYMBOL_VALUES.get(symbol, 0) as int

func scale_win_by_bet(base_win: int) -> int:
	return int(round(float(base_win) * (float(bet) / float(MIN_BET))))

func animate_winning_cells(line_results: Array) -> void:
	for line in line_results:
		var row: int = line.get("row", 0) as int
		var count: int = line.get("count", 0) as int
		var base_line_win: int = line.get("win", 0) as int
		var scaled_line_win: int = scale_win_by_bet(base_line_win)
		var glow_color: Color = get_highlight_color(scaled_line_win)
		for column in range(count):
			var cell: ColorRect = cell_nodes[row][column] as ColorRect
			if cell != null:
				cell.color = glow_color
				var color_tween: Tween = get_tree().create_tween()
				color_tween.tween_property(cell, "color", BASE_CELL_COLOR, 0.6).set_delay(0.2)

func get_highlight_color(win_amount: int) -> Color:
	if win_amount >= 140:
		return Color(1.0, 0.82, 0.25, 1.0)
	if win_amount >= 70:
		return Color(0.34, 0.9, 1.0, 1.0)
	return Color(0.46, 1.0, 0.56, 1.0)

func clear_cell_highlights() -> void:
	for row in range(GRID_ROWS):
		for column in range(GRID_COLS):
			var cell: ColorRect = cell_nodes[row][column] as ColorRect
			if cell != null:
				cell.color = BASE_CELL_COLOR

func update_ui() -> void:
	credits_label.text = "Credits: %d" % credits
	bet_label.text = "Bet: %d" % bet
	update_bet_button_states()

func update_bet_button_states() -> void:
	bet_4_button.button_pressed = bet == 4
	bet_8_button.button_pressed = bet == 8
	bet_16_button.button_pressed = bet == 16
	bet_30_button.button_pressed = bet == 30

func set_bet_buttons_disabled(disabled: bool) -> void:
	bet_4_button.disabled = disabled
	bet_8_button.disabled = disabled
	bet_16_button.disabled = disabled
	bet_30_button.disabled = disabled

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

func _on_bet_button_pressed(amount: int) -> void:
	if is_spinning:
		return
	if BET_OPTIONS.has(amount):
		bet = amount
		update_ui()
