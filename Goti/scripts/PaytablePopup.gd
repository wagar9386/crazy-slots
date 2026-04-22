extends Control
class_name PaytablePopup

@onready var background: ColorRect = $Background
@onready var payout_list: GridContainer = $Panel/SymbolGrid
@onready var bet_info_label: Label = $Panel/BetInfo
@onready var bet_buttons_container: HBoxContainer = $Panel/BetSelection/BetButtons
@onready var close_button: Button = $Panel/CloseButton

const SYMBOL_NAMES: Dictionary[int, String] = {
	0: "Cherries",
	1: "Orange",
	2: "Grapes",
	3: "Lemon",
	4: "Diamond",
	5: "Seven",
	6: "Wild"
}
const WILD_SYMBOL_ID: int = 6
const MAX_SYMBOL_ICON_SIZE: int = 18

var symbol_entry_data: Dictionary[int, Dictionary] = {}
var bet_buttons: Dictionary[int, Button] = {}
var active_display_bet: int = 0
var base_bet_value: int = 1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(_on_close_pressed)
	payout_list.columns = 2
	payout_list.set("custom_constants/hseparation", 14)
	payout_list.set("custom_constants/vseparation", 10)
	hide()

func setup(symbol_textures: Dictionary[int, Texture2D], symbol_values: Dictionary[int, int], bet_options: Array[int], current_bet: int, base_bet: int) -> void:
	symbol_entry_data.clear()
	bet_buttons.clear()
	base_bet_value = max(base_bet, 1)

	for child in payout_list.get_children():
		child.queue_free()
	for child in bet_buttons_container.get_children():
		child.queue_free()

	_build_symbol_rows(symbol_textures, symbol_values)
	_build_bet_buttons(bet_options)
	set_display_bet(current_bet)

func _build_symbol_rows(symbol_textures: Dictionary[int, Texture2D], symbol_values: Dictionary[int, int]) -> void:
	var symbol_ids: Array[int] = []
	for key in symbol_textures.keys():
		symbol_ids.append(int(key))
	symbol_ids.sort()

	for symbol_id in symbol_ids:
		var card: PanelContainer = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_FILL
		card.custom_minimum_size = Vector2(0, 80)
		card.set("custom_constants/separation", 6)
		var card_style: StyleBoxFlat = StyleBoxFlat.new()
		card_style.bg_color = Color(0.06, 0.06, 0.12, 0.5)
		card_style.border_color = Color(0.2, 0.3, 0.6, 0.8)
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(10)
		card.add_theme_stylebox_override("panel", card_style)

		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.size_flags_vertical = Control.SIZE_FILL
		row.custom_minimum_size = Vector2(0, 64)
		row.set("custom_constants/separation", 18)

		var icon_wrapper: CenterContainer = CenterContainer.new()
		icon_wrapper.custom_minimum_size = Vector2(48, 48)
		icon_wrapper.size_flags_horizontal = Control.SIZE_FILL
		icon_wrapper.size_flags_vertical = Control.SIZE_FILL

		var texture_rect: TextureRect = TextureRect.new()
		texture_rect.size_flags_horizontal = Control.SIZE_FILL
		texture_rect.size_flags_vertical = Control.SIZE_FILL
		texture_rect.expand = true
		texture_rect.custom_minimum_size = Vector2(32, 32)
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var symbol_texture: Texture2D = symbol_textures.get(symbol_id) as Texture2D
		if symbol_texture:
			var scaled_texture: Texture2D = _get_scaled_symbol_texture(symbol_texture)
			texture_rect.texture = scaled_texture if scaled_texture else symbol_texture
		icon_wrapper.add_child(texture_rect)
		row.add_child(icon_wrapper)

		var text_column: VBoxContainer = VBoxContainer.new()
		text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_column.size_flags_vertical = Control.SIZE_FILL
		text_column.set("custom_constants/separation", 3)

		var name_label: Label = Label.new()
		name_label.text = SYMBOL_NAMES.get(symbol_id, "Symbol %d" % symbol_id)
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
		text_column.add_child(name_label)

		var payout_label: Label = Label.new()
		payout_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		payout_label.add_theme_font_size_override("font_size", 14)
		text_column.add_child(payout_label)

		row.add_child(text_column)
		card.add_child(row)
		payout_list.add_child(card)

		var base_value: int = symbol_values.get(symbol_id, 0) as int
		var multipliers: Array[int] = []
		if symbol_id == WILD_SYMBOL_ID:
			multipliers = [10, 25, 60]
		else:
			multipliers = [2, 5, 12]

		symbol_entry_data[symbol_id] = {
			"payout_label": payout_label,
			"icon": texture_rect,
			"texture": symbol_texture,
			"base_value": base_value,
			"multipliers": multipliers,
			"name": name_label.text
		}

func _build_bet_buttons(bet_options: Array[int]) -> void:
	var sorted_options: Array[int] = bet_options.duplicate()
	sorted_options.sort()

	for amount in sorted_options:
		if amount <= 0:
			continue
		var btn: Button = Button.new()
		btn.text = "Bet %d" % amount
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(64, 36)
		btn.pressed.connect(_on_display_bet_pressed.bind(amount))
		bet_buttons[amount] = btn
		bet_buttons_container.add_child(btn)

func set_display_bet(amount: int) -> void:
	if amount <= 0:
		return
	active_display_bet = amount
	for option in bet_buttons.keys():
		var btn: Button = bet_buttons[option]
		btn.set_pressed(option == amount)
	var ratio: float = float(amount) / float(base_bet_value)
	bet_info_label.text = "Previewing payouts for Bet %d (%.1fx Base bet %d). Higher bets increase payouts." % [amount, ratio, base_bet_value]
	_refresh_payouts()

func _refresh_payouts() -> void:
	for entry in symbol_entry_data.values():
		var payout_label: Label = entry.get("payout_label") as Label
		var icon_rect: TextureRect = entry.get("icon") as TextureRect
		var base_value: int = entry.get("base_value", 0) as int
		var multipliers: Array[int] = entry.get("multipliers", []) as Array[int]
		var stored_texture: Texture2D = entry.get("texture") as Texture2D

		if icon_rect and stored_texture:
			var scaled_icon: Texture2D = _get_scaled_symbol_texture(stored_texture)
			icon_rect.texture = scaled_icon if scaled_icon else stored_texture

		if payout_label and multipliers.size() >= 3:
			var payouts: Array[int] = []
			for multiplier in multipliers:
				payouts.append(_scaled_payout(base_value, multiplier))
			payout_label.text = "3x: %d\n4x: %d\n5x: %d" % [payouts[0], payouts[1], payouts[2]]

func _scaled_payout(base_value: int, multiplier: int) -> int:
	var raw_value: int = base_value * multiplier
	if base_bet_value <= 0 or active_display_bet <= 0:
		return raw_value
	var ratio: float = float(active_display_bet) / float(base_bet_value)
	return int(round(float(raw_value) * ratio))

func _get_scaled_symbol_texture(texture: Texture2D) -> Texture2D:
	if not texture:
		return texture
	var source_image: Image = texture.get_image()
	if source_image.get_width() == 0 or source_image.get_height() == 0:
		return texture
	var max_dimension: int = max(source_image.get_width(), source_image.get_height())
	if max_dimension <= MAX_SYMBOL_ICON_SIZE:
		return texture
	var scale_ratio: float = float(MAX_SYMBOL_ICON_SIZE) / float(max_dimension)
	var target_width: int = max(1, int(round(source_image.get_width() * scale_ratio)))
	var target_height: int = max(1, int(round(source_image.get_height() * scale_ratio)))
	var resized_image: Image = source_image.duplicate()
	resized_image.resize(target_width, target_height, Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(resized_image)

func _on_display_bet_pressed(amount: int) -> void:
	set_display_bet(amount)

func _on_close_pressed() -> void:
	hide()
