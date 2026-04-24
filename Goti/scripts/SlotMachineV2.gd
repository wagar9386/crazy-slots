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
const BASE_CELL_COLOR: Color = Color(0, 0, 0, 0)

# Animator script
const ANIMATOR_SCRIPT: GDScript = preload("res://Goti/scripts/SlotSpinAnimatorV2.gd")

# Weighted symbol pool (controls RNG probability)
const WEIGHTED_SYMBOLS: Array[int] = [
	Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A,
	Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B,
	Symbol.C, Symbol.C, Symbol.C, Symbol.C, Symbol.C, Symbol.C,
	Symbol.D, Symbol.D, Symbol.D, Symbol.D, Symbol.D, Symbol.D,
	Symbol.E, Symbol.E, Symbol.E, Symbol.E,
	Symbol.G, Symbol.G, Symbol.G,
	Symbol.Wild, Symbol.Wild
]

# Base symbol values
const SYMBOL_VALUES: Dictionary[int, int] = {
	Symbol.A: 3,
	Symbol.B: 6,
	Symbol.C: 9,
	Symbol.D: 9,
	Symbol.E: 12,
	Symbol.G: 30,
	Symbol.Wild: 39
}

# Symbol textures
const SYMBOL_TEXTURES: Dictionary[int, Texture2D] = {
	Symbol.A: preload("res://Goti/symbols/wester_icon_boots_01.png"),
	Symbol.B: preload("res://Goti/symbols/wester_icon_dynamite_01.png"),
	Symbol.C: preload("res://Goti/symbols/wester_icon_revolver_01.png"),
	Symbol.D: preload("res://Goti/symbols/western_icon_hat_01.png"),
	Symbol.E: preload("res://Goti/symbols/western_icon_moneybag_01.png"),
	Symbol.G: preload("res://Goti/symbols/seven.png"),
	Symbol.Wild: preload("res://Goti/symbols/wild.png")
}
const BACKGROUND_TEXTURE: Texture2D = preload("res://Goti/assets/background_2.webp")
const COWBOY_MOVIE_FONT: Font = preload("res://Goti/assets/Cowboy Movie.ttf")
const COWBOY_OUTLAW_FONT: Font = preload("res://Goti/assets/Cowboy Outlaw.otf")
const COWBOY_OUTLAW_TEXTURED_FONT: Font = preload("res://Goti/assets/Cowboy Outlaw Textured.otf")
const GOLDEN_METAL: Color = Color(0.98, 0.75, 0.32, 1)
const RUSTIC_MAHOGANY: Color = Color(0.1, 0.04, 0.02, 1)
const REEL_BACKDROP_COLOR: Color = Color(0.13, 0.05, 0.02, 0.95)
const BOARD_BASE_COLOR: Color = Color(0.06, 0.02, 0.01, 1)
const HUD_PANEL_COLOR: Color = Color(0.1, 0.03, 0.01, 0.95)
const GLOW_HALO_COLOR: Color = Color(0.94, 0.62, 0.2, 0.55)
const STONE_EDGE_COLOR: Color = Color(0.85, 0.55, 0.2, 0.6)
const BURNISHED_BRASS_COLOR: Color = Color(0.93, 0.79, 0.47, 1)
const PAYTABLE_SCENE: PackedScene = preload("res://Goti/scenes/Paytable.tscn")
const GRID_ALIGNMENT: Dictionary[String, float] = {
	"left": 0.095,
	"top": 0.205,
	"right": 0.905,
	"bottom": 0.785
}
const GRID_SEPARATION: int = 2
const GRID_MIN_SIZE: Vector2 = Vector2(960, 520)

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

var paytable_overlay: PaytablePopup

# UI references
@onready var reel_grid: GridContainer = get_node_or_null("UILayer/SlotsUI/ReelGrid") as GridContainer
@onready var hud_controls: HBoxContainer = get_node_or_null("UILayer/SlotsUI/HUD/HUDControls") as HBoxContainer
@onready var credits_label: Label = null
@onready var win_label: Label = null
@onready var spin_button: Button = null
@onready var paytable_button: Button = null
@onready var ui_root: Control = get_node_or_null("UILayer/SlotsUI") as Control
@onready var title_panel: ColorRect = get_node_or_null("UILayer/SlotsUI/TitlePanel") as ColorRect
@onready var marquee_label: Label = get_node_or_null("UILayer/SlotsUI/MarqueeLabel") as Label
@onready var reel_backdrop: ColorRect = get_node_or_null("UILayer/SlotsUI/ReelBackdrop") as ColorRect
@onready var background_pattern: TextureRect = get_node_or_null("UILayer/SlotsUI/BackgroundPattern") as TextureRect

@onready var bet_buttons_container: HBoxContainer = null
@onready var bet_label: Label = null
@onready var bet_4_button: Button = null
@onready var bet_8_button: Button = null
@onready var bet_16_button: Button = null
@onready var bet_30_button: Button = null

func _ready() -> void:
	randomize()
	_cache_ui_nodes()

	if not _validate_ui_nodes():
		push_warning("SlotMachineV2: Missing UI nodes, slot setup aborted.")
		return

	# --- UI POLISH ---
	_apply_visual_polish()

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
	paytable_button.pressed.connect(_on_paytable_pressed)
	paytable_overlay = PAYTABLE_SCENE.instantiate() as PaytablePopup
	ui_root.add_child(paytable_overlay)
	paytable_overlay.call_deferred("setup", SYMBOL_TEXTURES, SYMBOL_VALUES, BET_OPTIONS, bet, MIN_BET)

	# Initial state
	_generate_grid()
	_update_display_grid()
	_clear_cell_highlights()
	_update_ui()

# Start spin
func spin() -> void:
	if is_spinning:
		return
	
#Restar credits just despres de clicar spin
	credits -= bet
	_update_display_grid()
	_update_ui()
	
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

func _on_paytable_pressed() -> void:
	if not paytable_overlay:
		return
	paytable_overlay.set_display_bet(bet)
	paytable_overlay.move_to_front()
	paytable_overlay.show()

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
	
	credits += scaled_win
	
	if credits <= 0:
		credits = 4
		
	if credits < 30:
		bet = 16
	if credits < 16:
		bet = 8
	if credits < 8:
		bet = 4

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
				cell.color = Color(0.4, 1.0, 0.5, 0.65)

# Reset highlights
func _clear_cell_highlights() -> void:
	for row in range(GRID_ROWS):
		for column in range(GRID_COLS):
			var cell: ColorRect = cell_nodes[row][column]
			if cell:
				cell.color = BASE_CELL_COLOR

# Update UI
func _update_ui() -> void:
	if credits_label:
		credits_label.text = "CREDITS: %d" % credits
	if bet_label:
		bet_label.text = "BET: %d" % bet
	if win_label:
		win_label.text = "WIN: %d" % last_win

	if bet_4_button:
		bet_4_button.button_pressed = bet == 4
	if bet_8_button:
		bet_8_button.button_pressed = bet == 8
	if bet_16_button:
		bet_16_button.button_pressed = bet == 16
	if bet_30_button:
		bet_30_button.button_pressed = bet == 30
	if paytable_overlay:
		paytable_overlay.set_display_bet(bet)


	if bet_4_button:
		bet_4_button.button_pressed = bet == 4
	if bet_8_button:
		bet_8_button.button_pressed = bet == 8
	if bet_16_button:
		bet_16_button.button_pressed = bet == 16
	if bet_30_button:
		bet_30_button.button_pressed = bet == 30

	if paytable_overlay:
		paytable_overlay.set_display_bet(bet)

func _cache_ui_nodes() -> void:
	if hud_controls:
		credits_label = hud_controls.get_node_or_null("CreditsLabel") as Label
		win_label = hud_controls.get_node_or_null("WinLabel") as Label
		spin_button = hud_controls.get_node_or_null("SpinButton") as Button
		paytable_button = hud_controls.get_node_or_null("PaytableButton") as Button
		bet_buttons_container = hud_controls.get_node_or_null("BetButtons") as HBoxContainer
	else:
		bet_buttons_container = null
	
	if bet_buttons_container:
		bet_label = bet_buttons_container.get_node_or_null("BetLabel") as Label
		bet_4_button = bet_buttons_container.get_node_or_null("Bet4Button") as Button
		bet_8_button = bet_buttons_container.get_node_or_null("Bet8Button") as Button
		bet_16_button = bet_buttons_container.get_node_or_null("Bet16Button") as Button
		bet_30_button = bet_buttons_container.get_node_or_null("Bet30Button") as Button
	else:
		bet_label = null
		bet_4_button = null
		bet_8_button = null
		bet_16_button = null
		bet_30_button = null

func _validate_ui_nodes() -> bool:
	var mapping: Dictionary[String, Node] = {
		"ReelGrid": reel_grid,
		"HUDControls": hud_controls,
		"CreditsLabel": credits_label,
		"WinLabel": win_label,
		"SpinButton": spin_button,
		"PaytableButton": paytable_button,
		"BetButtons": bet_buttons_container,
		"BetLabel": bet_label,
		"Bet4Button": bet_4_button,
		"Bet8Button": bet_8_button,
		"Bet16Button": bet_16_button,
		"Bet30Button": bet_30_button
	}
	var missing: Array[String] = []
	for name in mapping.keys():
		if not mapping[name]:
			missing.append(name)
	if missing.size() > 0:
		push_warning("SlotMachineV2: Missing UI nodes (%s)." % String(", ").join(missing))
		return false
	return true

func _align_reel_grid() -> void:
	if not reel_grid:
		return
	reel_grid.anchor_left = GRID_ALIGNMENT["left"]
	reel_grid.anchor_top = GRID_ALIGNMENT["top"]
	reel_grid.anchor_right = GRID_ALIGNMENT["right"]
	reel_grid.anchor_bottom = GRID_ALIGNMENT["bottom"]
	reel_grid.offset_left = 0
	reel_grid.offset_top = 0
	reel_grid.offset_right = 0
	reel_grid.offset_bottom = 0
	reel_grid.custom_minimum_size = GRID_MIN_SIZE
	reel_grid.set("custom_constants/hseparation", GRID_SEPARATION)
	reel_grid.set("custom_constants/vseparation", GRID_SEPARATION)
	_clear_symbol_backgrounds()

func _clear_symbol_backgrounds() -> void:
	if not reel_grid:
		return
	for child in reel_grid.get_children():
		var cell: ColorRect = child as ColorRect
		if cell:
			cell.color = BASE_CELL_COLOR
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _apply_visual_polish() -> void:
	if background_pattern:
		background_pattern.texture = BACKGROUND_TEXTURE
		background_pattern.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background_pattern.modulate = Color(1, 1, 1, 1)
		background_pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if title_panel:
		title_panel.visible = false
		title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if reel_backdrop:
		reel_backdrop.visible = false

	var machine_board: ColorRect = get_node_or_null("UILayer/SlotsUI/MachineBoard") as ColorRect
	if machine_board:
		machine_board.visible = false

	var glow: ColorRect = get_node_or_null("UILayer/SlotsUI/BoardGlow") as ColorRect
	if glow:
		glow.visible = false

	var hud_bg: ColorRect = get_node_or_null("UILayer/SlotsUI/HUD/HUDBackground") as ColorRect
	if hud_bg:
		hud_bg.color = Color(0, 0, 0, 0)
		hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if reel_grid:
		_align_reel_grid()

	var title: Label = get_node_or_null("UILayer/SlotsUI/TitleLabel") as Label
	if title:
		title.text = "COWBOY & COWGIRL REELS"
		title.add_theme_font_override("font", COWBOY_MOVIE_FONT)
		title.add_theme_font_size_override("font_size", 48)
		title.add_theme_color_override("font_color", GOLDEN_METAL)
		title.add_theme_constant_override("outline_size", 12)
		title.add_theme_color_override("font_outline_color", Color(0.18, 0.05, 0))
		title.horizontal_alignment = 1

	if marquee_label:
		marquee_label.text = "HIGH NOON JACKPOT REELS"
		marquee_label.add_theme_font_override("font", COWBOY_OUTLAW_TEXTURED_FONT)
		marquee_label.add_theme_font_size_override("font_size", 22)
		marquee_label.add_theme_constant_override("outline_size", 4)
		marquee_label.add_theme_color_override("font_color", Color(0.98, 0.78, 0.25, 1))
		marquee_label.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0))
		marquee_label.horizontal_alignment = 1
		marquee_label.vertical_alignment = 1

	var subtitle: Label = get_node_or_null("UILayer/SlotsUI/SubtitleLabel") as Label
	if subtitle:
		subtitle.text = "WESTERN HIGH ROLLER 4X5 REELS"
		subtitle.add_theme_font_override("font", COWBOY_OUTLAW_TEXTURED_FONT)
		subtitle.add_theme_font_size_override("font_size", 18)
		subtitle.add_theme_color_override("font_color", Color(0.95, 0.74, 0.3, 1))
		subtitle.horizontal_alignment = 1

	var spin_normal: StyleBoxFlat = StyleBoxFlat.new()
	spin_normal.bg_color = Color(0.95, 0.62, 0.08)
	spin_normal.border_color = Color(1.0, 0.9, 0.43)
	spin_normal.set_border_width_all(3)
	spin_normal.set_corner_radius_all(18)
	spin_normal.shadow_size = 14
	spin_normal.shadow_color = Color(0.8, 0.4, 0.08, 0.65)

	var spin_hover: StyleBoxFlat = StyleBoxFlat.new()
	spin_hover.bg_color = Color(1, 0.7, 0.1)
	spin_hover.border_color = Color(1.0, 0.92, 0.5)
	spin_hover.set_border_width_all(3)
	spin_hover.set_corner_radius_all(18)

	var spin_pressed: StyleBoxFlat = StyleBoxFlat.new()
	spin_pressed.bg_color = Color(0.72, 0.32, 0.08)
	spin_pressed.border_color = Color(0.96, 0.56, 0.2)
	spin_pressed.set_border_width_all(3)
	spin_pressed.set_corner_radius_all(18)

	spin_button.add_theme_stylebox_override("normal", spin_normal)
	spin_button.add_theme_stylebox_override("hover", spin_hover)
	spin_button.add_theme_stylebox_override("pressed", spin_pressed)
	spin_button.add_theme_font_override("font", COWBOY_OUTLAW_FONT)
	spin_button.add_theme_font_size_override("font_size", 26)
	spin_button.add_theme_color_override("font_color", Color(0.06, 0.02, 0))
	spin_button.text = spin_button.text.to_upper()

	if credits_label:
		credits_label.add_theme_font_override("font", COWBOY_OUTLAW_FONT)
		credits_label.add_theme_font_size_override("font_size", 24)
		credits_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.7))
	if win_label:
		win_label.add_theme_font_override("font", COWBOY_OUTLAW_FONT)
		win_label.add_theme_font_size_override("font_size", 22)
		win_label.add_theme_color_override("font_color", Color(0.98, 0.84, 0.46))
	if bet_label:
		bet_label.add_theme_font_override("font", COWBOY_OUTLAW_FONT)
		bet_label.add_theme_font_size_override("font_size", 22)
		bet_label.add_theme_color_override("font_color", Color(0.97, 0.85, 0.35))

	for btn in [bet_4_button, bet_8_button, bet_16_button, bet_30_button]:
		if not btn:
			continue
		var bstyle: StyleBoxFlat = StyleBoxFlat.new()
		bstyle.bg_color = Color(0.16, 0.06, 0.02)
		bstyle.border_color = Color(0.95, 0.78, 0.3)
		bstyle.set_border_width_all(2)
		bstyle.set_corner_radius_all(8)
		bstyle.shadow_size = 4
		bstyle.shadow_color = Color(0.7, 0.38, 0.13, 0.7)
		btn.add_theme_stylebox_override("normal", bstyle)

		var bstyle_sel: StyleBoxFlat = StyleBoxFlat.new()
		bstyle_sel.bg_color = Color(0.98, 0.68, 0.24)
		bstyle_sel.border_color = Color(0.92, 0.45, 0.12)
		bstyle_sel.set_border_width_all(2)
		bstyle_sel.set_corner_radius_all(8)
		bstyle_sel.shadow_size = 4
		bstyle_sel.shadow_color = Color(0.85, 0.5, 0.15, 0.8)
		btn.add_theme_stylebox_override("pressed", bstyle_sel)
		btn.add_theme_font_override("font", COWBOY_OUTLAW_FONT)
		btn.add_theme_color_override("font_color", Color(0.98, 0.9, 0.65))
		btn.add_theme_font_size_override("font_size", 18)
		btn.toggle_mode = true

	if paytable_button:
		paytable_button.add_theme_font_override("font", COWBOY_OUTLAW_FONT)
		paytable_button.add_theme_font_size_override("font_size", 22)
		paytable_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		paytable_button.text = paytable_button.text.to_upper()
		var paytable_style: StyleBoxFlat = StyleBoxFlat.new()
		paytable_style.bg_color = Color(0.12, 0.05, 0.02)
		paytable_style.border_color = Color(0.99, 0.78, 0.3)
		paytable_style.set_border_width_all(2)
		paytable_style.set_corner_radius_all(10)
		paytable_style.shadow_size = 6
		paytable_style.shadow_color = Color(0.85, 0.45, 0.12, 0.6)
		paytable_button.add_theme_stylebox_override("normal", paytable_style)
		paytable_button.add_theme_stylebox_override("hover", paytable_style)

		var paytable_pressed: StyleBoxFlat = StyleBoxFlat.new()
		paytable_pressed.bg_color = Color(0.95, 0.62, 0.24)
		paytable_pressed.border_color = Color(0.92, 0.48, 0.15)
		paytable_pressed.set_border_width_all(2)
		paytable_pressed.set_corner_radius_all(10)
		paytable_pressed.shadow_size = 6
		paytable_pressed.shadow_color = Color(0.85, 0.45, 0.12, 0.5)
		paytable_button.add_theme_stylebox_override("pressed", paytable_pressed)
# Enable/disable bet buttons
func _set_bet_buttons_disabled(disabled: bool) -> void:
	for button in [bet_4_button, bet_8_button, bet_16_button, bet_30_button]:
		if button:
			button.disabled = disabled

func broke_mf(disabled: bool) -> void:
	for button in [bet_8_button, bet_16_button, bet_30_button]:
		if button:
			button.disabled = disabled

func _process(_delta: float) -> void:
	if is_spinning:
		return  # don’t run logic while spinning

	# runs every frame when NOT spinning
	if bet_8_button:
		bet_8_button.disabled = credits < 8
	if bet_16_button:
		bet_16_button.disabled = credits < 16
	if bet_30_button:
		bet_30_button.disabled = credits < 30

	

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

func apply_win(multiplier):
	var win = bet * multiplier
	credits += win
	print("Has guanyat:", win)
	print("Saldo:", credits)
