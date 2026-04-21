# Slot Machine Main Script
class_name SlotMachineV2
extends Node2D

# Symbol enum
enum Symbol { A, B, C, D, E, G, Wild }

# Grid settings
const GRID_ROWS: int = 4
const GRID_COLS: int = 5

# Betting
const MIN_BET: int = 4
const BET_OPTIONS: Array[int] = [4, 8, 16, 30]

# Default cell color
const BASE_CELL_COLOR: Color = Color(0.07, 0.08, 0.15, 1.0)

# Animator script
const ANIMATOR_SCRIPT: GDScript = preload("res://scripts/SlotSpinAnimatorV2.gd")

# Weighted symbol pool (controls RNG probability)
const WEIGHTED_SYMBOLS: Array[int] = [
	Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A,
	Symbol.B, Symbol.B, Symbol.B, Symbol.B,
	Symbol.C, Symbol.C, Symbol.C,
	Symbol.D, Symbol.D, Symbol.D,
	Symbol.E, Symbol.E,
	Symbol.G,
	Symbol.Wild
]

# Base symbol values
const SYMBOL_VALUES: Dictionary = {
	Symbol.A: 3,
	Symbol.B: 6,
	Symbol.C: 9,
	Symbol.D: 9,
	Symbol.E: 12,
	Symbol.G: 30,
	Symbol.Wild: 20
}

# Symbol textures
const SYMBOL_TEXTURES: Dictionary = {
	Symbol.A: preload("res://symbols/cherries.png"),
	Symbol.B: preload("res://symbols/diamond.png"),
	Symbol.C: preload("res://symbols/grapes.png"),
	Symbol.D: preload("res://symbols/lemon.png"),
	Symbol.E: preload("res://symbols/orange.png"),
	Symbol.G: preload("res://symbols/seven.png"),
	Symbol.Wild: preload("res://symbols/wild.png")
}

# Grid data
var grid: Array = []

# Visual nodes
var symbol_nodes: Array = []
var cell_nodes: Array = []

# Player state
var credits: int = 100
@export var bet: int = MIN_BET
var is_spinning: bool = false

# ✅ FIX #1: store last win globally so UI can access it
var last_win: int = 0

# Animator
var animator: SlotSpinAnimatorV2

# UI references
@onready var reel_grid: GridContainer = get_node("UILayer/SlotsUI/ReelGrid")
@onready var hud_controls: HBoxContainer = get_node("UILayer/SlotsUI/HUD/HUDControls")
@onready var credits_label: Label = hud_controls.get_node("CreditsLabel")
@onready var bet_label: Label = hud_controls.get_node("BetLabel")
@onready var spin_button: Button = hud_controls.get_node("SpinButton")
@onready var bet_4_button: Button = hud_controls.get_node("BetButtons/Bet4Button")
@onready var bet_8_button: Button = hud_controls.get_node("BetButtons/Bet8Button")
@onready var bet_16_button: Button = hud_controls.get_node("BetButtons/Bet16Button")
@onready var bet_30_button: Button = hud_controls.get_node("BetButtons/Bet30Button")
@onready var Win_label: Label = hud_controls.get_node("WinLabel")

func _ready() -> void:
	randomize()

	# Ensure bet is valid
	if not BET_OPTIONS.has(bet):
		bet = MIN_BET

	# Setup grid visuals
	_gather_grid_nodes()
	_set_symbol_pivots()

	# Setup animator
	animator = ANIMATOR_SCRIPT.new()
	add_child(animator)
	animator.setup(symbol_nodes, get_random_symbol, SYMBOL_TEXTURES)
	animator.spin_completed.connect(_on_spin_completed)

	# Connect UI
	spin_button.pressed.connect(_on_spin_pressed)
	bet_4_button.pressed.connect(_on_bet_button_pressed.bind(4))
	bet_8_button.pressed.connect(_on_bet_button_pressed.bind(8))
	bet_16_button.pressed.connect(_on_bet_button_pressed.bind(16))
	bet_30_button.pressed.connect(_on_bet_button_pressed.bind(30))

	# Initial state
	_generate_grid()
	_update_display_grid()
	_clear_cell_highlights()
	_update_ui()

# Start spin
func spin() -> void:
	if is_spinning:
		return

	is_spinning = true
	spin_button.disabled = true
	_set_bet_buttons_disabled(true)

	_clear_cell_highlights()
	_generate_grid()

	animator.start_spin(grid)

# RNG symbol picker
func get_random_symbol() -> int:
	return WEIGHTED_SYMBOLS[randi() % WEIGHTED_SYMBOLS.size()]

func _on_spin_pressed() -> void:
	spin()

# Change bet
func _on_bet_button_pressed(amount: int) -> void:
	if is_spinning:
		return

	if BET_OPTIONS.has(amount):
		bet = amount
		_update_ui()

# Called when spin animation finishes
func _on_spin_completed() -> void:
	var win_result: Dictionary = _evaluate_wins()

	var base_win: int = win_result.get("total_win", 0) as int
	var scaled_win: int = _scale_win_by_bet(base_win)

	# ✅ FIX (typing): cast to Array to avoid Variant error
	var winning_lines: Array = win_result.get("lines", []) as Array

	# ✅ FIX #1: save win globally for UI
	last_win = scaled_win

	# Apply credits
	credits -= bet
	if credits <= 0:
		credits += 10
	else:
		credits += scaled_win

	_update_display_grid()
	_animate_winning_cells(winning_lines)
	_debug_grid()

	_update_ui()

	is_spinning = false
	spin_button.disabled = false
	_set_bet_buttons_disabled(false)

# Evaluate all rows
func _evaluate_wins() -> Dictionary:
	var total_win: int = 0
	var line_results: Array = []

	for row in range(GRID_ROWS):
		var row_result: Dictionary = _evaluate_row(row)

		var row_win: int = row_result.get("win", 0) as int

		if row_win > 0:
			total_win += row_win
			line_results.append(row_result)

	return {"total_win": total_win, "lines": line_results}

# Evaluate a single row
func _evaluate_row(row: int) -> Dictionary:

	# --- WILD CLUSTER (only from left side) ---
	var wild_cluster_count: int = 0

	for column in range(GRID_COLS):
		if (grid[column][row] as int) == Symbol.Wild:
			wild_cluster_count += 1
		else:
			break

	var wild_win_amount: int = 0

	if wild_cluster_count >= 3:
		var base_val: int = SYMBOL_VALUES[Symbol.Wild]

		match wild_cluster_count:
			3: wild_win_amount = base_val * 10
			4: wild_win_amount = base_val * 25
			5: wild_win_amount = base_val * 60

	# --- SUBSTITUTION LOGIC ---
	# ✅ FIX #3 (COMMENT ONLY): 
	# This finds the FIRST non-wild symbol from the LEFT.
	# All wilds before it will act as that symbol.
	# Only LEFT-TO-RIGHT matches count (classic slots behavior).

	var target_symbol: int = -1

	for column in range(GRID_COLS):
		if (grid[column][row] as int) != Symbol.Wild:
			target_symbol = grid[column][row] as int
			break

	var sub_win_amount: int = 0
	var sub_count: int = 0

	if target_symbol != -1:

		# Count consecutive matches (wilds substitute)
		for column in range(GRID_COLS):
			var current: int = grid[column][row] as int

			if current == target_symbol or current == Symbol.Wild:
				sub_count += 1
			else:
				break

		if sub_count >= 3:
			sub_win_amount = _calculate_payout(target_symbol, sub_count)

	else:
		# All wilds case
		sub_count = GRID_COLS
		sub_win_amount = _calculate_payout(Symbol.Wild, sub_count)
		target_symbol = Symbol.Wild

	# Choose best result
	if wild_win_amount >= sub_win_amount and wild_win_amount > 0:
		return {"row": row, "count": wild_cluster_count, "win": wild_win_amount, "symbol": Symbol.Wild}
	elif sub_win_amount > 0:
		return {"row": row, "count": sub_count, "win": sub_win_amount, "symbol": target_symbol}

	return {"row": row, "count": 0, "win": 0, "symbol": -1}

# Payout calculation
func _calculate_payout(symbol: int, count: int) -> int:
	var base_value: int = SYMBOL_VALUES.get(symbol, 0) as int

	match count:
		3: return base_value * 2
		4: return base_value * 5
		5: return base_value * 12

	return 0

# Scale win based on bet
func _scale_win_by_bet(base_win: int) -> int:
	return int(round(float(base_win) * (float(bet) / float(MIN_BET))))

# Animate winning cells
func _animate_winning_cells(line_results: Array) -> void:
	for line in line_results:
		var row: int = line.get("row", 0) as int
		var count: int = line.get("count", 0) as int

		for column in range(count):
			var cell: ColorRect = cell_nodes[row][column]
			if cell:
				cell.color = Color(0.4, 1.0, 0.5)

# Reset highlights
func _clear_cell_highlights() -> void:
	for row in range(GRID_ROWS):
		for column in range(GRID_COLS):
			var cell: ColorRect = cell_nodes[row][column]
			if cell:
				cell.color = BASE_CELL_COLOR

# Update UI
func _update_ui() -> void:
	credits_label.text = "Credits: %d" % credits
	bet_label.text = "Bet: %d" % bet
	Win_label.text = "Win: %d" % last_win

	bet_4_button.button_pressed = bet == 4
	bet_8_button.button_pressed = bet == 8
	bet_16_button.button_pressed = bet == 16
	bet_30_button.button_pressed = bet == 30

# Enable/disable bet buttons
func _set_bet_buttons_disabled(disabled: bool) -> void:
	bet_4_button.disabled = disabled
	bet_8_button.disabled = disabled
	bet_16_button.disabled = disabled
	bet_30_button.disabled = disabled

# Debug print grid
func _debug_grid() -> void:
	for row in range(GRID_ROWS):
		var line := ""
		for column in range(GRID_COLS):
			line += "%s " % _symbol_to_label(grid[column][row])
		print(line)

# Convert symbol to text
func _symbol_to_label(symbol: int) -> String:
	match symbol:
		Symbol.A: return "A"
		Symbol.B: return "B"
		Symbol.C: return "C"
		Symbol.D: return "D"
		Symbol.E: return "E"
		Symbol.G: return "G"
		Symbol.Wild: return "W"
	return "?"

# Gather grid nodes from scene
func _gather_grid_nodes() -> void:
	symbol_nodes.clear()
	cell_nodes.clear()

	var cells: Array = reel_grid.get_children()

	for row in range(GRID_ROWS):
		var row_symbols := []
		var row_cells := []

		for column in range(GRID_COLS):
			var index: int = (row * GRID_COLS) + column
			var symbol_node: TextureRect = null
			var cell: ColorRect = null

			if index < cells.size():
				var cell_node: Node = cells[index]
				cell = cell_node

				if cell_node.get_child_count() > 0:
					var center = cell_node.get_child(0)
					if center.get_child_count() > 0:
						symbol_node = center.get_child(0)

			row_symbols.append(symbol_node)
			row_cells.append(cell)

		symbol_nodes.append(row_symbols)
		cell_nodes.append(row_cells)

# Center pivot for scaling animations
func _set_symbol_pivots() -> void:
	for row in range(GRID_ROWS):
		for column in range(GRID_COLS):
			var symbol: TextureRect = symbol_nodes[row][column]
			if symbol:
				symbol.pivot_offset = symbol.custom_minimum_size * 0.5

# Generate random grid
func _generate_grid() -> void:
	grid.resize(GRID_COLS)

	for column in range(GRID_COLS):
		grid[column] = []

		for row in range(GRID_ROWS):
			grid[column].append(get_random_symbol())

# Update visuals
func _update_display_grid() -> void:
	for row in range(GRID_ROWS):
		for column in range(GRID_COLS):
			var symbol: int = grid[column][row]
			var node: TextureRect = symbol_nodes[row][column]

			if node:
				node.texture = SYMBOL_TEXTURES.get(symbol)
				node.self_modulate = Color.WHITE
