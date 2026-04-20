class_name SlotGameUI
extends Control

enum Symbol {
	A,
	B,
	C,
	D,
	E,
	G,
	Wild
}

const MIN_BET: int = 4
const MAX_BET: int = 40
const ROW_COUNT: int = 4
const REEL_COUNT: int = 5
const AUTO_SPIN_INTERVAL: float = 0.6

const WEIGHTED_SYMBOLS: Array[Symbol] = [
	Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A,
	Symbol.B, Symbol.B, Symbol.B, Symbol.B,
	Symbol.C, Symbol.C, Symbol.C,
	Symbol.D, Symbol.D, Symbol.D,
	Symbol.E, Symbol.E,
	Symbol.G,
	Symbol.Wild
]

const SYMBOL_NAMES: Dictionary = {
	Symbol.A: "A",
	Symbol.B: "B",
	Symbol.C: "C",
	Symbol.D: "D",
	Symbol.E: "E",
	Symbol.G: "G",
	Symbol.Wild: "W"
}

const SYMBOL_COLORS: Dictionary = {
	Symbol.A: Color8(37, 103, 214),
	Symbol.B: Color8(63, 181, 88),
	Symbol.C: Color8(226, 97, 62),
	Symbol.D: Color8(249, 168, 52),
	Symbol.E: Color8(111, 88, 197),
	Symbol.G: Color8(225, 57, 103),
	Symbol.Wild: Color8(255, 223, 110)
}

@onready var grid_container: GridContainer = $UIFrame/MainColumn/ReelPanel/ReelGrid
@onready var spin_button: Button = $UIFrame/MainColumn/ControlsRow/SpinButton
@onready var max_bet_button: Button = $UIFrame/MainColumn/ControlsRow/MaxBetButton
@onready var auto_button: Button = $UIFrame/MainColumn/ControlsRow/AutoButton
@onready var balance_value: Label = $UIFrame/MainColumn/StatsRow/BalancePanel/BalanceColumn/BalanceValue
@onready var bet_value: Label = $UIFrame/MainColumn/StatsRow/BetPanel/BetColumn/BetValue
@onready var notification_label: Label = $UIFrame/MainColumn/NotificationLabel

var credits: int = 100
var bet: int = MIN_BET
var reel_cells: Array[ColorRect] = []
var cell_labels: Array[Label] = []

var auto_spin_timer: Timer
var auto_spin_active: bool = false

func _ready() -> void:
	randomize()
	bet = max(bet, MIN_BET)
	_build_grid_visuals()
	_setup_auto_timer()
	_connect_controls()
	_update_stats_ui()
	notification_label.text = "Win combinations light up with gold jitters."

func _build_grid_visuals() -> void:
	for child in grid_container.get_children():
		if child is ColorRect:
			var cell: ColorRect = child as ColorRect
			reel_cells.append(cell)

			var label: Label = Label.new()
			label.horizontal_alignment = Label.ALIGN_CENTER
			label.vertical_alignment = Label.VALIGN_CENTER
			label.anchor_left = 0.0
			label.anchor_top = 0.0
			label.anchor_right = 1.0
			label.anchor_bottom = 1.0
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(label)
			cell_labels.append(label)

func _setup_auto_timer() -> void:
	auto_spin_timer = Timer.new()
	auto_spin_timer.wait_time = AUTO_SPIN_INTERVAL
	auto_spin_timer.one_shot = false
	add_child(auto_spin_timer)
	auto_spin_timer.connect("timeout", Callable(self, "_on_auto_spin_timeout"))

func _connect_controls() -> void:
	spin_button.connect("pressed", Callable(self, "_on_spin_button_pressed"))
	max_bet_button.connect("pressed", Callable(self, "_on_max_bet_button_pressed"))
	auto_button.connect("pressed", Callable(self, "_on_auto_button_pressed"))

func _on_spin_button_pressed() -> void:
	_spin()

func _on_max_bet_button_pressed() -> void:
	bet = max(MIN_BET, min(MAX_BET, max(credits, MIN_BET)))
	bet_value.text = "Bet: %d" % bet

func _on_auto_button_pressed() -> void:
	auto_spin_active = not auto_spin_active
	if auto_spin_active:
		auto_spin_timer.start()
	else:
		auto_spin_timer.stop()
	auto_button.text = auto_spin_active ? "Stop Auto" : "Auto"

func _on_auto_spin_timeout() -> void:
	if not auto_spin_active:
		return
	if credits < bet:
		auto_spin_active = false
		auto_spin_timer.stop()
		auto_button.text = "Auto"
		notification_label.text = "Not enough credits to continue auto-spin."
		return
	_spin()

func _spin() -> void:
	var result_grid: Array = _generate_slot_result()
	var win: int = _check_win(result_grid)

	credits -= bet

	if credits <= 0:
		credits += 10
		notification_label.text = "No cash pity +10"
	else:
		credits += win
		if win >= 100:
			notification_label.text = "MEGA WIN!!! %d" % win
		elif win >= 50:
			notification_label.text = "BIG WIN! %d" % win
		elif win > 0:
			notification_label.text = "Win: %d" % win
		else:
			notification_label.text = "No win this spin."

	_update_grid_display(result_grid)
	_update_stats_ui()
	_debug_grid(result_grid)
	print("Credits: %d" % credits)

func _generate_slot_result() -> Array:
	var grid: Array = []
	for reel_index in REEL_COUNT:
		var reel: Array = []
		for row_index in ROW_COUNT:
			reel.append(_get_random_symbol())
		grid.append(reel)
	return grid

func _check_win(grid: Array) -> int:
	var total_win: int = 0
	for row_index in ROW_COUNT:
		var row_win: int = _check_row(grid, row_index)
		if row_win > 0:
			print("Row %d WIN → %d" % [row_index, row_win])
		total_win += row_win
	return total_win

func _check_row(grid: Array, row: int) -> int:
	var wild_count: int = _count_wild_cluster(grid, row)
	if wild_count >= 3:
		var wild_value: int = _get_symbol_value(Symbol.Wild)
		var multiplier: int = 0
		match wild_count:
			3:
				multiplier = 3
			4:
				multiplier = 6
			5:
				multiplier = 10
		return wild_value * multiplier

	var base_symbol: Symbol = grid[0][row]
	var count: int = 1
	for reel_index in range(1, REEL_COUNT):
		var current: Symbol = grid[reel_index][row]
		if current == Symbol.Wild or current == base_symbol:
			count += 1
		else:
			break

	if count < 3:
		return 0

	return _calculate_payout(base_symbol, count)

func _count_wild_cluster(grid: Array, row: int) -> int:
	var count: int = 0
	for reel_index in REEL_COUNT:
		if grid[reel_index][row] == Symbol.Wild:
			count += 1
		else:
			break
	return count

func _calculate_payout(symbol: Symbol, count: int) -> int:
	var base_value: int = _get_symbol_value(symbol)
	var multiplier: int = 0
	match count:
		3:
			multiplier = 1
		4:
			multiplier = 3
		5:
			multiplier = 6
	return base_value * multiplier

func _get_symbol_value(symbol: Symbol) -> int:
	match symbol:
		Symbol.A:
			return 3
		Symbol.B:
			return 6
		Symbol.C:
			return 9
		Symbol.D:
			return 9
		Symbol.E:
			return 12
		Symbol.G:
			return 30
		Symbol.Wild:
			return 20
	return 0

func _update_grid_display(grid: Array) -> void:
	var cell_index: int = 0
	for row_index in ROW_COUNT:
		for reel_index in REEL_COUNT:
			var symbol: Symbol = grid[reel_index][row_index]
			var cell: ColorRect = reel_cells[cell_index]
			var label: Label = cell_labels[cell_index]
			cell.color = SYMBOL_COLORS.get(symbol, Color(0.2, 0.2, 0.2))
			label.text = SYMBOL_NAMES.get(symbol, "?")
			cell_index += 1

func _update_stats_ui() -> void:
	balance_value.text = "$%d" % credits
	bet_value.text = "Bet: %d" % bet

func _debug_grid(grid: Array) -> void:
	for row_index in ROW_COUNT:
		var line: String = ""
		for reel_index in REEL_COUNT:
			line += "%s " % SYMBOL_NAMES.get(grid[reel_index][row_index], "?")
		print(line.strip_edges())

func _get_random_symbol() -> Symbol:
	var index: int = int(rand_range(0, WEIGHTED_SYMBOLS.size()))
	return WEIGHTED_SYMBOLS[index]
