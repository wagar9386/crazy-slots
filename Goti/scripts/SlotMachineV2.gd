# Slot Machine Main Script
class_name SlotMachineV2
extends Node2D

# Symbol enum
enum Symbol { A, B, C, D, E, G, Wild, Bonus }

# Grid settings
const DEFAULT_GRID_ROWS: int = 4
const DEFAULT_GRID_COLS: int = 5

var grid_rows: int = DEFAULT_GRID_ROWS
var grid_cols: int = DEFAULT_GRID_COLS

# Betting
const MIN_BET: int = 4
const BET_OPTIONS: Array[int] = [4, 8, 16, 32]

# Default cell color
const BASE_CELL_COLOR: Color = Color(0, 0, 0, 0)

# Animator script
const ANIMATOR_SCRIPT: GDScript = preload("res://Goti/scripts/SlotSpinAnimatorV2.gd")

# Weighted symbol pool (controls RNG probability)
const WEIGHTED_SYMBOLS: Array[int] = [
	Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A, Symbol.A,
	Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B, Symbol.B,
	Symbol.C, Symbol.C, Symbol.C, Symbol.C, Symbol.C, Symbol.C, Symbol.C, Symbol.C, Symbol.C, Symbol.C, Symbol.C, Symbol.C,
	Symbol.D, Symbol.D, Symbol.D, Symbol.D, Symbol.D, Symbol.D, Symbol.D, Symbol.D, Symbol.D, Symbol.D,
	Symbol.E, Symbol.E, Symbol.E, Symbol.E, Symbol.E, Symbol.E, Symbol.E, Symbol.E,
	Symbol.G, Symbol.G, Symbol.G, Symbol.G, Symbol.G, Symbol.G,
	Symbol.Wild, Symbol.Wild, Symbol.Wild, Symbol.Wild, Symbol.Wild,
	Symbol.Bonus,
]

# Base symbol values
const SYMBOL_VALUES: Dictionary[int, int] = {
	Symbol.A: 2,
	Symbol.B: 3,
	Symbol.C: 5,
	Symbol.D: 7,
	Symbol.E: 12,
	Symbol.G: 30,
	Symbol.Wild: 33,
	Symbol.Bonus: 333
}

# Symbol textures
const SYMBOL_TEXTURES: Dictionary[int, Texture2D] = {
	Symbol.A: preload("res://Goti/symbols/wester_icon_boots_01.png"),
	Symbol.B: preload("res://Goti/symbols/wester_icon_dynamite_01.png"),
	Symbol.C: preload("res://Goti/symbols/wester_icon_revolver_01.png"),
	Symbol.D: preload("res://Goti/symbols/western_icon_hat_01.png"),
	Symbol.E: preload("res://Goti/symbols/western_icon_moneybag_01.png"),
	Symbol.G: preload("res://Goti/symbols/seven.png"),
	Symbol.Wild: preload("res://Goti/symbols/wilder.png"),
	Symbol.Bonus: preload("res://Goti/symbols/bonus.png")
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
const FULL_EXPAND_FLAGS: Control.SizeFlags = Control.SIZE_FILL | Control.SIZE_EXPAND
const WIN_TIER_1_COLOR: Color = Color(0.2, 0.8, 1.0, 0.6) # 0 - 100
const WIN_TIER_2_COLOR: Color = Color(1.0, 0.8, 0.2, 0.7) # 100 - 600
const WIN_TIER_3_COLOR: Color = Color(1.0, 0.3, 0.8, 0.8) # 600 - 1000
const WIN_TIER_MEGA_COLOR: Color = Color(1.0, 1.0, 0.3, 1.0) # 1000+
const BONUS_SCENE: PackedScene = preload("res://Ian/Bonus/Plinko/Mapa_Plinko.tscn")


###BONUS SYSTEM 
var spin_pool: Array[int] = []
var bonus_hits_in_spin: int = 0



# Grid data
var grid: Array = []

# Visual nodes
var symbol_nodes: Array = []
var cell_nodes: Array = []

# Player state
var credits: int:
	get: return GameState.credits
	set(value): GameState.credits = value

var bet: int:
	get: return GameState.bet
	set(value): GameState.bet = value
	
var is_spinning: bool = false

#FIX #1: store last win globally so UI can access it
var last_win: int = 0

# Animator
var animator: SlotSpinAnimatorV2

var paytable_overlay: PaytablePopup

# UI references
var reel_grid: GridContainer = null
var hud_controls: HBoxContainer = null
@onready var credits_label: Label = null
@onready var win_label: Label = null
@onready var spin_button: Button = null
@onready var paytable_button: Button = null
@onready var ui_root: Control = get_node_or_null("UILayer/SlotsUI") as Control
@onready var title_panel: ColorRect = get_node_or_null("UILayer/SlotsUI/TitlePanel") as ColorRect
@onready var title_label: Label = get_node_or_null("UILayer/SlotsUI/TitleLabel") as Label
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
	_apply_grid_configuration()

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
	bet_30_button.pressed.connect(_on_bet_button_pressed.bind(32))
	paytable_button.pressed.connect(_on_paytable_pressed)
	paytable_overlay = PAYTABLE_SCENE.instantiate() as PaytablePopup
	ui_root.add_child(paytable_overlay)
	paytable_overlay.call_deferred("setup", SYMBOL_TEXTURES, SYMBOL_VALUES, BET_OPTIONS, bet, MIN_BET)
	
	# Initial state
	_refresh_grid_content()
	
	_update_ui()
	
func _trigger_bonus_game() -> void:
	print("SWITCHING TO BONUS SCENE")

	get_tree().change_scene_to_packed(BONUS_SCENE)

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


#####BONUS SEQUENCE#######################
func _start_bonus_sequence() -> void:
	if not ui_root:
		return

	# Create center text
	var label := Label.new()
	label.text = "BONUS TRIGGERED!"
	label.add_theme_font_override("font", COWBOY_MOVIE_FONT)
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.0))

	label.set_anchors_preset(Control.PRESET_CENTER)
	label.set_offsets_preset(Control.PRESET_CENTER)
	label.pivot_offset = label.size * 0.5
	
	label.scale = Vector2(0.2, 0.2)
	label.modulate = Color(1, 1, 1, 0)

	label.z_index = 999
	ui_root.add_child(label)

	# Pop-in animation
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate", Color(1,1,1,1), 0.2)

	# Hold for dramatic effect (3.3s total delay)
	tween.tween_interval(3.3)

	# Fade out
	tween.tween_property(label, "modulate", Color(1,1,1,0), 0.4)
	tween.tween_callback(label.queue_free)

	# After delay → go bonus
	tween.tween_callback(_trigger_bonus_game)
	
	################




# Called when spin animation finishes
func _on_spin_completed() -> void:
	

	
	var win_result: Dictionary = _evaluate_wins()
	var bonus_result: Dictionary = _evaluate_bonus_trigger()

	var base_win: int = win_result.get("total_win", 0) as int
	var scaled_win: int = _scale_win_by_bet(base_win)

	# FIX (typing): cast to Array to avoid Variant error
	var winning_lines: Array = win_result.get("lines", []) as Array

	# FIX #1: save win globally for UI
	last_win = scaled_win
	_apply_win_visuals(scaled_win, winning_lines)

	# Apply credits
	
	
	
	if bonus_result.count >= 3:
		_start_bonus_sequence()
	
	if credits <= 0:
		credits = 4
		
	if credits < 32:
		bet = 16
	if credits < 16:
		bet = 8
	if credits < 8:
		bet = 4

	_update_display_grid()
	_debug_grid()
	var previous_credits: int = credits
	credits += scaled_win
	_animate_win_countup(previous_credits, credits)
	_dopamine_burst(scaled_win)
	_update_ui()

	is_spinning = false
	spin_button.disabled = false
	_set_bet_buttons_disabled(false)

# Evaluate all rows
func _evaluate_wins() -> Dictionary:
	var total_win: int = 0
	var line_results: Array = []

	for row in range(grid_rows):
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

	for column in range(grid_cols):
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

	for column in range(grid_cols):
		if (grid[column][row] as int) != Symbol.Wild:
			target_symbol = grid[column][row] as int
			break

	var sub_win_amount: int = 0
	var sub_count: int = 0

	if target_symbol != -1:

		# Count consecutive matches (wilds substitute)
		for column in range(grid_cols):
			var current: int = grid[column][row] as int

			if current == target_symbol or current == Symbol.Wild:
				sub_count += 1
			else:
				break

		if sub_count >= 3:
			sub_win_amount = _calculate_payout(target_symbol, sub_count)

	else:
		# All wilds case
		sub_count = grid_cols
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
		4: return base_value * 6
		5: return base_value * 12

	return 0

# Scale win based on bet
func _scale_win_by_bet(base_win: int) -> int:
	return int(round(float(base_win) * (float(bet) / float(MIN_BET))))

# Reset highlights
func _clear_cell_highlights() -> void:
	for row in range(grid_rows):
		for column in range(grid_cols):
			var cell: ColorRect = cell_nodes[row][column]
			if cell:
				cell.color = BASE_CELL_COLOR

func _apply_win_visuals(win_amount: int, winning_lines: Array) -> void:
	if win_amount <= 0:
		return

	var color: Color = WIN_TIER_1_COLOR
	var mega: bool = false

	if win_amount >= 1000:
		color = WIN_TIER_MEGA_COLOR
		mega = true
	elif win_amount >= 600:
		color = WIN_TIER_3_COLOR
	elif win_amount >= 100:
		color = WIN_TIER_2_COLOR

	for line in winning_lines:
		var row: int = line.get("row", 0) as int
		var count: int = line.get("count", 0) as int

		if row < 0 or row >= cell_nodes.size():
			continue

		var row_cells: Array = cell_nodes[row]

		for column in range(count):
			if column < 0 or column >= row_cells.size():
				continue
			var cell: ColorRect = row_cells[column]
			if cell:
				cell.color = color

	if mega:
		_start_flash_effect()

func _start_flash_effect() -> void:
	var tween: Tween = create_tween()
	for _i in range(6):
		tween.tween_callback(_flash_all_cells_on)
		tween.tween_interval(0.12)
		tween.tween_callback(_flash_all_cells_off)
		tween.tween_interval(0.12)

func _flash_all_cells_on() -> void:
	for row_cells in cell_nodes:
		for cell in row_cells:
			if cell:
				cell.modulate = Color(1, 1, 1, 2)

func _flash_all_cells_off() -> void:
	for row_cells in cell_nodes:
		for cell in row_cells:
			if cell:
				cell.modulate = Color(1, 1, 1, 1)

func set_grid_width(new_width: int) -> void:
	if new_width <= 0:
		push_warning("SlotMachineV2: Grid width must be positive.")
		return
	grid_cols = new_width
	_on_grid_dimensions_changed()

func set_grid_height(new_height: int) -> void:
	if new_height <= 0:
		push_warning("SlotMachineV2: Grid height must be positive.")
		return
	grid_rows = new_height
	_on_grid_dimensions_changed()

func set_grid_size(new_rows: int, new_columns: int) -> void:
	if new_rows <= 0 or new_columns <= 0:
		push_warning("SlotMachineV2: Grid size values must be positive.")
		return
	grid_rows = new_rows
	grid_cols = new_columns
	_on_grid_dimensions_changed()

func _on_grid_dimensions_changed() -> void:
	_apply_grid_configuration()
	_refresh_grid_content()

func _apply_grid_configuration() -> void:
	if reel_grid:
		reel_grid.columns = grid_cols
		_apply_cell_visibility()
	_gather_grid_nodes()
	_set_symbol_pivots()
	if animator:
		animator.setup(symbol_nodes, get_random_symbol, SYMBOL_TEXTURES)

func _apply_cell_visibility() -> void:
	if not reel_grid:
		return
	var total_cells: int = reel_grid.get_child_count()
	var visible_count: int = grid_rows * grid_cols
	for index in range(total_cells):
		var cell: CanvasItem = reel_grid.get_child(index) as CanvasItem
		if cell:
			cell.visible = index < visible_count

func _refresh_grid_content() -> void:
	_generate_grid()
	_update_display_grid()
	_clear_cell_highlights()

func set_title_rotation(angle_degrees: float) -> void:
	if not title_label:
		return
	title_label.rotation_degrees = angle_degrees

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
		bet_30_button.button_pressed = bet == 32
	if paytable_overlay:
		paytable_overlay.set_display_bet(bet)


func _cache_ui_nodes() -> void:
	reel_grid = get_node_or_null("UILayer/SlotsUI/ReelGrid") as GridContainer
	hud_controls = get_node_or_null("UILayer/SlotsUI/HUD/HUDControls") as HBoxContainer

	if hud_controls:
		credits_label = hud_controls.get_node_or_null("CreditsLabel") as Label
		win_label = hud_controls.get_node_or_null("WinLabel") as Label
		spin_button = hud_controls.get_node_or_null("SpinButton") as Button
		paytable_button = hud_controls.get_node_or_null("PaytableButton") as Button
		bet_buttons_container = hud_controls.get_node_or_null("BetButtons") as HBoxContainer
	else:
		credits_label = null
		win_label = null
		spin_button = null
		paytable_button = null
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

##BONUS LOGIC
func _evaluate_bonus_trigger() -> Dictionary:
	var count := 0
	var positions: Array = []

	for column in range(grid_cols):
		for row in range(grid_rows):
			if grid[column][row] == Symbol.Bonus:
				count += 1
				positions.append({"row": row, "col": column})

	return {
		"count": count,
		"positions": positions
	}


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
	for node_name in mapping.keys():
		if not mapping[node_name]:
			missing.append(node_name)
	if missing.size() > 0:
		push_warning("SlotMachineV2: Missing UI nodes (%s)." % String(", ").join(missing))
		return false
	return true

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
		background_pattern.modulate = Color(1, 1, 1, 1)
		background_pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stretch_background_to_fullscreen()

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
		_clear_symbol_backgrounds()

	if title_label:
		title_label.text = "COWGIRL SLOTS"
		title_label.add_theme_font_override("font", COWBOY_MOVIE_FONT)
		title_label.add_theme_font_size_override("font_size", 69)
		title_label.add_theme_color_override("font_color", GOLDEN_METAL)
		title_label.add_theme_constant_override("outline_size", 12)
		title_label.add_theme_color_override("font_outline_color", Color(0.18, 0.05, 0))
		title_label.horizontal_alignment = 1

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

func _stretch_background_to_fullscreen() -> void:
	if not background_pattern:
		return
	background_pattern.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	background_pattern.offset_left = 0
	background_pattern.offset_top = 0
	background_pattern.offset_right = 0
	background_pattern.offset_bottom = 0
	background_pattern.size_flags_horizontal = FULL_EXPAND_FLAGS
	background_pattern.size_flags_vertical = FULL_EXPAND_FLAGS
	background_pattern.stretch_mode = TextureRect.STRETCH_SCALE
	background_pattern.custom_minimum_size = Vector2.ZERO
	background_pattern.position = Vector2.ZERO

# Enable/disable bet buttons
func _set_bet_buttons_disabled(disabled: bool) -> void:
	for button in [bet_4_button, bet_8_button, bet_16_button, bet_30_button]:
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
		bet_30_button.disabled = credits < 32


####DOPAMINE###################
func _animate_win_countup(from: int, to: int) -> void:
	if to <= 0:
		return
	var duration: float = clamp(float(to - from) * 0.012, 2.0, 6.0)
	var tween: Tween = create_tween()
	tween.tween_method(_set_credits_display, float(from), float(to), duration).set_ease(Tween.EASE_OUT)

func _set_credits_display(value: float) -> void:
	if credits_label:
		credits_label.text = "CREDITS: %d" % int(value)
		
func _dopamine_burst(win_amount: int) -> void:
	if win_amount <= 0 or not win_label:
		return

	win_label.text = "WIN: %d" % win_amount
	win_label.pivot_offset = win_label.size * 0.5
	var pop: Tween = create_tween()
	pop.tween_property(win_label, "scale", Vector2(1.55, 1.55), 0.1).set_ease(Tween.EASE_OUT)
	pop.tween_property(win_label, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_IN)

	var color_tween: Tween = create_tween().set_loops(4)
	color_tween.tween_property(win_label, "modulate", Color(1.0, 0.9, 0.2, 1), 0.15)
	color_tween.tween_property(win_label, "modulate", Color(1.0, 0.4, 0.1, 1), 0.15)
	color_tween.tween_property(win_label, "modulate", Color(1.0, 1.0, 1.0, 1), 0.15)

	if win_amount >= 100 and reel_grid:
		var origin: Vector2 = reel_grid.position
		var shake: Tween = create_tween()
		for _i in range(8):
			shake.tween_property(reel_grid, "position", origin + Vector2(randf_range(-6, 6), randf_range(-5, 5)), 0.05)
		shake.tween_property(reel_grid, "position", origin, 0.05)

	_show_win_celebration(win_amount)

func _show_win_celebration(win_amount: int) -> void:
	if not ui_root or not reel_grid:
		return
	if win_amount < 100:
		return

	var tier_text: String = ""
	var tier_color: Color = Color.WHITE
	var do_flash: bool = false
	var do_fireworks: bool = false

	if win_amount >= 5000:
		tier_text = "ULTRA MEGA HUGE WIN"
		tier_color = Color(0.9, 0.2, 1.0, 1)
		do_flash = true
		do_fireworks = true
	elif win_amount >= 3000:
		tier_text = "MEGA HUGE WIN"
		tier_color = Color(1.0, 0.35, 0.08, 1)
		do_flash = true
		do_fireworks = true
	elif win_amount >= 2000:
		tier_text = "MEGA WIN"
		tier_color = Color(1.0, 1.0, 0.1, 1)
		do_flash = true
		do_fireworks = true
	elif win_amount >= 1000:
		tier_text = "HUGE WIN"
		tier_color = Color(1.0, 0.55, 0.1, 1)
		do_flash = true
	elif win_amount >= 500:
		tier_text = "BIG WIN"
		tier_color = Color(0.35, 1.0, 0.45, 1)

	_show_big_credits_overlay(win_amount)

	if tier_text != "":
		_show_tier_label(tier_text, tier_color)

	if do_flash:
		_start_flash_effect()

	if do_fireworks:
		_launch_fireworks()

func _show_big_credits_overlay(win_amount: int) -> void:
	if not reel_grid or not ui_root:
		return

	var big_label: Label = Label.new()
	big_label.text = "+%d" % win_amount
	big_label.add_theme_font_override("font", COWBOY_MOVIE_FONT)
	big_label.add_theme_font_size_override("font_size", 104)
	big_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1))
	big_label.add_theme_constant_override("outline_size", 12)
	big_label.add_theme_color_override("font_outline_color", Color(0.12, 0.03, 0.0))
	big_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	big_label.size = Vector2(700, 220)
	big_label.z_index = 100
	big_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var reel_center: Vector2 = reel_grid.global_position + reel_grid.size * 0.5
	var local_pos: Vector2 = ui_root.get_global_transform().affine_inverse() * reel_center
	big_label.position = local_pos - big_label.size * 0.5
	big_label.pivot_offset = big_label.size * 0.5
	big_label.scale = Vector2(0.2, 0.2)
	big_label.modulate = Color(1, 1, 1, 0)
	ui_root.add_child(big_label)

	var tween: Tween = create_tween()
	tween.tween_property(big_label, "scale", Vector2(1.25, 1.25), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(big_label, "modulate", Color(1, 1, 1, 1), 0.18)
	tween.tween_property(big_label, "scale", Vector2(1.0, 1.0), 0.12).set_ease(Tween.EASE_IN)
	tween.tween_interval(1.6)
	tween.tween_property(big_label, "modulate", Color(1, 1, 1, 0), 0.55)
	tween.tween_callback(big_label.queue_free)

func _show_tier_label(tier_text: String, tier_color: Color) -> void:
	if not ui_root:
		return

	var label: Label = Label.new()
	label.text = tier_text
	label.add_theme_font_override("font", COWBOY_MOVIE_FONT)
	label.add_theme_font_size_override("font_size", 88)
	label.add_theme_color_override("font_color", tier_color)
	label.add_theme_constant_override("outline_size", 14)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.01, 0.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(ui_root.size.x, 160)
	label.position = Vector2(0, 40)
	label.pivot_offset = Vector2(ui_root.size.x * 0.5, 80)
	label.scale = Vector2(0.1, 0.1)
	label.modulate = Color(1, 1, 1, 0)
	label.z_index = 101
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(label)

	# Slam in, pulse, then fade
	var tween: Tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.14).set_ease(Tween.EASE_IN)

	# Pulse glow loop
	var pulse: Tween = create_tween().set_loops(5)
	pulse.tween_property(label, "modulate", Color(tier_color.r, tier_color.g, tier_color.b, 0.7), 0.25)
	pulse.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.25)

	# Fade out after delay
	var fade: Tween = create_tween()
	fade.tween_interval(3.0)
	fade.tween_property(label, "modulate", Color(1, 1, 1, 0), 0.6)
	fade.tween_callback(label.queue_free)

func _launch_fireworks() -> void:
	if ui_root.get_child_count() > 200:
		return
	if not ui_root:
		return

	var screen_size: Vector2 = ui_root.size
	var colors: Array[Color] = [
		Color(1.0, 0.2, 0.2),
		Color(1.0, 0.85, 0.1),
		Color(0.2, 0.8, 1.0),
		Color(0.9, 0.2, 1.0),
		Color(0.2, 1.0, 0.4),
		Color(1.0, 0.5, 0.1),
	]

	# Fire several bursts with slight delays
	for burst in range(7):
		var delay: float = burst * 0.32
		var burst_pos: Vector2 = Vector2(
			randf_range(screen_size.x * 0.15, screen_size.x * 0.85),
			randf_range(screen_size.y * 0.05, screen_size.y * 0.55)
		)
		var burst_color: Color = colors[randi() % colors.size()]

		var timer: SceneTreeTimer = get_tree().create_timer(delay)
		timer.timeout.connect(_spawn_burst.bind(burst_pos, burst_color))

func _spawn_burst(origin: Vector2, burst_color: Color) -> void:
	if not ui_root:
		return

	var particle_count: int = 18

	for i in range(particle_count):
		var angle: float = (TAU / particle_count) * i + randf_range(-0.15, 0.15)
		var speed: float = randf_range(110.0, 260.0)
		var velocity: Vector2 = Vector2(cos(angle), sin(angle)) * speed

		var dot: ColorRect = ColorRect.new()
		var size_val: float = randf_range(5, 11)
		dot.size = Vector2(size_val, size_val)
		dot.color = burst_color.lightened(randf_range(0.0, 0.3))
		dot.position = origin
		dot.z_index = 200
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_root.add_child(dot)

		var duration: float = randf_range(0.55, 1.1)
		var end_pos: Vector2 = origin + velocity * duration + Vector2(0, 140.0 * duration * duration)

		var tween: Tween = create_tween()
		tween.tween_property(dot, "position", end_pos, duration).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(dot, "color", Color(dot.color.r, dot.color.g, dot.color.b, 0.0), duration).set_ease(Tween.EASE_IN)
		tween.tween_callback(dot.queue_free)
######################################################################

# Debug print grid
func _debug_grid() -> void:
	for row in range(grid_rows):
		var line := ""
		for column in range(grid_cols):
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

	for row in range(grid_rows):
		var row_symbols := []
		var row_cells := []

		for column in range(grid_cols):
			var index: int = (row * grid_cols) + column
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
	for row in range(grid_rows):
		for column in range(grid_cols):
			var symbol: TextureRect = symbol_nodes[row][column]
			if symbol:
				symbol.pivot_offset = symbol.custom_minimum_size * 0.5

# Generate random grid
func _generate_grid() -> void:
	grid.clear()
	grid.resize(grid_cols)

	# reset per spin
	bonus_hits_in_spin = 0
	
	# copy your ORIGINAL weighted pool (unchanged)
	spin_pool = WEIGHTED_SYMBOLS.duplicate()

	for column in range(grid_cols):
		grid[column] = []

		for row in range(grid_rows):
			var symbol: int = spin_pool[randi() % spin_pool.size()]
			grid[column].append(symbol)

			# if bonus appears → boost chances for remaining cells
			if symbol == Symbol.Bonus:
				_on_bonus_hit()
				
func _on_bonus_hit() -> void:
	bonus_hits_in_spin += 1


	var extra := 2 + bonus_hits_in_spin

	for i in range(extra):
		spin_pool.append(Symbol.Bonus)


# Update visuals
func _update_display_grid() -> void:
	for row in range(grid_rows):
		for column in range(grid_cols):
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
