extends Control
class_name PaytablePopup

@onready var payout_list: GridContainer = $Panel/SymbolGrid
@onready var bet_info_label: Label = $Panel/BetInfo
@onready var bet_buttons_container: HBoxContainer = $Panel/BetSelection/BetButtons
@onready var close_button: Button = $Panel/CloseButton


const SYMBOL_NAMES: Dictionary[int, String] = {
	0: "COWBOY BOOTS",
	1: "DYNAMITE",
	2: "REVOLVER",
	3: "HAT",
	4: "MONEY BAG",
	5: "HORSESHOE",
	6: "WILD",
	7: "BONUS"
}
const WILD_SYMBOL_ID: int = 6
const SYMBOL_COLUMNS: int = 4
const SYMBOL_CARD_MIN_WIDTH: int = 240
const SYMBOL_CARD_MIN_HEIGHT: int = 160
const SYMBOL_CARD_SEPARATION_H: int = 12
const SYMBOL_CARD_SEPARATION_V: int = 10
const SYMBOL_ICON_TARGET_SIZE: Vector2 = Vector2(96, 96)
const MAX_SYMBOL_ICON_SIZE: int = 96
const BACKGROUND_TEXTURE: Texture2D = preload("res://Goti/assets/background_2.webp")
const COWBOY_MOVIE_FONT: Font = preload("res://Goti/assets/Cowboy Movie.ttf")
const COWBOY_OUTLAW_FONT: Font = preload("res://Goti/assets/Cowboy Outlaw.otf")
const COWBOY_OUTLAW_TEXTURED_FONT: Font = preload("res://Goti/assets/Cowboy Outlaw Textured.otf")
const PAYTABLE_PANEL_COLOR: Color = Color(0.07, 0.02, 0.01, 0.75)
const CARD_BG_COLOR: Color = Color(0.1, 0.04, 0.02, 0.82)
const CARD_BORDER_COLOR: Color = Color(0.96, 0.74, 0.28, 0.95)
const BUTTON_BG_COLOR: Color = Color(0.18, 0.07, 0.03, 0.96)
const BUTTON_ACTIVE_COLOR: Color = Color(0.98, 0.72, 0.25, 1)
const TEXT_GOLD_COLOR: Color = Color(0.99, 0.86, 0.52, 1)
const TEXT_LIGHT_COLOR: Color = Color(1, 0.95, 0.85, 1)
const PAYTABLE_BG: Texture2D = preload("res://Goti/assets/paytable-background.png")

var symbol_entry_data: Dictionary[int, Dictionary] = {}
var bet_buttons: Dictionary[int, Button] = {}
var active_display_bet: int = 0
var base_bet_value: int = 1

func _create_vignette_texture() -> ImageTexture:
	var w: int = 128
	var h: int = 80
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var dx: float = (float(x) / float(w)) * 2.0 - 1.0
			var dy: float = (float(y) / float(h)) * 2.0 - 1.0
			var dist: float = sqrt(dx * dx + dy * dy)
			var alpha: float = clamp((dist - 0.4) * 1.12, 0.0, 1.0)
			alpha = alpha * alpha
			img.set_pixel(x, y, Color(0.04, 0.01, 0.0, alpha))
	return ImageTexture.create_from_image(img)


func _ready() -> void:
	var panel: ColorRect = get_node("Panel") as ColorRect
	panel.custom_minimum_size = Vector2(1100, 613)
	if panel:
		panel.color = Color(0, 0, 0, 0)  # Make Panel fully transparent

		var bg_rect: TextureRect = TextureRect.new()
		bg_rect.name = "BackgroundImage"
		bg_rect.texture = PAYTABLE_BG
		bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
		bg_rect.size_flags_horizontal = Control.SIZE_FILL
		bg_rect.size_flags_vertical = Control.SIZE_FILL
		bg_rect.anchor_left = 0
		bg_rect.anchor_top = 0
		bg_rect.anchor_right = 1
		bg_rect.anchor_bottom = 1
		bg_rect.offset_left = 0
		bg_rect.offset_top = 0
		bg_rect.offset_right = 0
		bg_rect.offset_bottom = 0
		bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(bg_rect)
		panel.move_child(bg_rect, 0)
	# Brown tint overlay
		var tint: ColorRect = ColorRect.new()
		tint.color = Color(0.12, 0.05, 0.01, 0.52)
		tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tint.anchor_left = 0
		tint.anchor_top = 0
		tint.anchor_right = 1
		tint.anchor_bottom = 1
		tint.offset_left = 0
		tint.offset_top = 0
		tint.offset_right = 0
		tint.offset_bottom = 0
		panel.add_child(tint)
		panel.move_child(tint, 1)

		# Vignette
		var vignette: TextureRect = TextureRect.new()
		vignette.texture = _create_vignette_texture()
		vignette.stretch_mode = TextureRect.STRETCH_SCALE
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vignette.anchor_left = 0
		vignette.anchor_top = 0
		vignette.anchor_right = 1
		vignette.anchor_bottom = 1
		vignette.offset_left = 0
		vignette.offset_top = 0
		vignette.offset_right = 0
		vignette.offset_bottom = 0
		panel.add_child(vignette)
		panel.move_child(vignette, 2)
	mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = Vector2(1100, 613)
	if panel:
		panel.color = PAYTABLE_PANEL_COLOR
		var glint: TextureRect = panel.get_node("PanelGlint") as TextureRect
		if glint:
			glint.modulate = Color(1, 0.92, 0.75, 0.12)
	var title_label: Label = get_node("Panel/Title") as Label
	
	if title_label:
		title_label.add_theme_constant_override("margin_top", 10)
		title_label.add_theme_constant_override("margin_bottom", 25)
		title_label.text = "PAYTABLE"
		title_label.add_theme_font_override("font", COWBOY_MOVIE_FONT)
		title_label.add_theme_font_size_override("font_size", 78)
		title_label.add_theme_color_override("font_color", TEXT_GOLD_COLOR)
		title_label.add_theme_constant_override("outline_size", 9)
		title_label.add_theme_color_override("font_outline_color", Color(0.16, 0.04, 0.01))
	bet_info_label.add_theme_font_override("font", COWBOY_OUTLAW_FONT)
	bet_info_label.add_theme_font_size_override("font_size", 23)
	bet_info_label.add_theme_color_override("font_color", TEXT_LIGHT_COLOR)
	var selection_label: Label = get_node("Panel/BetSelection/Label") as Label
	if selection_label:
		selection_label.add_theme_font_override("font", COWBOY_OUTLAW_TEXTURED_FONT)
		selection_label.add_theme_font_size_override("font_size", 33)
		selection_label.add_theme_color_override("font_color", TEXT_GOLD_COLOR)
	close_button.add_theme_font_override("font", COWBOY_OUTLAW_FONT)
	close_button.add_theme_font_size_override("font_size", 33)
	close_button.add_theme_color_override("font_color", TEXT_GOLD_COLOR)
	close_button.text = close_button.text.to_upper()
	close_button.pressed.connect(_on_close_pressed)
	payout_list.columns = SYMBOL_COLUMNS
	payout_list.add_theme_constant_override("h_separation", 24)
	payout_list.add_theme_constant_override("v_separation", 20)
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
		card.custom_minimum_size = Vector2(SYMBOL_CARD_MIN_WIDTH, SYMBOL_CARD_MIN_HEIGHT)
		card.set("custom_constants/separation", 10)
		var card_style: StyleBoxFlat = StyleBoxFlat.new()
		card_style.bg_color = CARD_BG_COLOR
		card_style.border_color = CARD_BORDER_COLOR
		card_style.set_border_width_all(2)
		card_style.set_corner_radius_all(16)
		card_style.shadow_size = 8
		card_style.shadow_color = Color(0.92, 0.5, 0.12, 0.7)
		card.add_theme_stylebox_override("panel", card_style)

		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.size_flags_vertical = Control.SIZE_FILL
		row.custom_minimum_size = Vector2(0, SYMBOL_CARD_MIN_HEIGHT)
		row.set("custom_constants/separation", 14)

		var icon_wrapper: CenterContainer = CenterContainer.new()
		icon_wrapper.custom_minimum_size = SYMBOL_ICON_TARGET_SIZE
		icon_wrapper.size_flags_horizontal = Control.SIZE_FILL
		icon_wrapper.size_flags_vertical = Control.SIZE_FILL

		var texture_rect: TextureRect = TextureRect.new()
		texture_rect.size_flags_horizontal = Control.SIZE_FILL
		texture_rect.size_flags_vertical = Control.SIZE_FILL
		texture_rect.expand = true
		texture_rect.custom_minimum_size = SYMBOL_ICON_TARGET_SIZE
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
		var symbol_name: String = SYMBOL_NAMES.get(symbol_id, "Symbol %d" % symbol_id).to_upper()
		name_label.text = symbol_name
		name_label.add_theme_font_override("font", COWBOY_OUTLAW_FONT)
		name_label.add_theme_font_size_override("font_size", 29)
		name_label.add_theme_color_override("font_color", TEXT_GOLD_COLOR)
		text_column.add_child(name_label)

		var payout_label: Label = Label.new()
		payout_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		payout_label.add_theme_font_override("font", COWBOY_OUTLAW_FONT)
		payout_label.add_theme_font_size_override("font_size", 20)
		payout_label.add_theme_color_override("font_color", TEXT_LIGHT_COLOR)

		var special_label: Label = Label.new()
		special_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		special_label.add_theme_font_override("font", COWBOY_OUTLAW_FONT)
		special_label.add_theme_font_size_override("font_size", 23)
		special_label.add_theme_color_override("font_color", TEXT_GOLD_COLOR)
		special_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		text_column.add_child(payout_label)
		text_column.add_child(special_label)
		
		row.add_child(text_column)
		card.add_child(row)
		payout_list.add_child(card)

		var base_value: int = symbol_values.get(symbol_id, 0) as int
		var multipliers: Array[int] = []
		if symbol_id == WILD_SYMBOL_ID:
			multipliers = [10, 25, 60]
		else:
			multipliers = [2, 6, 12]

		symbol_entry_data[symbol_id] = {
			"payout_label": payout_label,
			"special_label": special_label,
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
		btn.text = "BET %d" % amount
		btn.text = btn.text.to_upper()
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(64, 36)
		var bet_style: StyleBoxFlat = StyleBoxFlat.new()
		bet_style.bg_color = BUTTON_BG_COLOR
		bet_style.border_color = Color(0.95, 0.72, 0.3)
		bet_style.set_border_width_all(2)
		bet_style.set_corner_radius_all(10)
		bet_style.shadow_size = 5
		bet_style.shadow_color = Color(0.3, 0.1, 0.03, 0.75)
		btn.add_theme_stylebox_override("normal", bet_style)
		var bet_pressed_style: StyleBoxFlat = StyleBoxFlat.new()
		bet_pressed_style.bg_color = BUTTON_ACTIVE_COLOR
		bet_pressed_style.border_color = Color(0.9, 0.45, 0.16)
		bet_pressed_style.set_border_width_all(2)
		bet_pressed_style.set_corner_radius_all(10)
		bet_pressed_style.shadow_size = 5
		bet_pressed_style.shadow_color = Color(0.85, 0.5, 0.18, 0.8)
		btn.add_theme_stylebox_override("pressed", bet_pressed_style)
		btn.add_theme_font_override("font", COWBOY_OUTLAW_FONT)
		btn.add_theme_color_override("font_color", Color(0.08, 0.02, 0))
		btn.add_theme_font_size_override("font_size", 18)
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
	if bet_info_label:
		var ratio_text: String = "%0.1f" % ratio
		bet_info_label.text = "CURRENT BET: %d (%sX BASE)" % [amount, ratio_text]
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
			payout_label.text = "3X: %d\n4X: %d\n5X: %d" % [payouts[0], payouts[1], payouts[2]]
			
		var special_label: Label = entry.get("special_label") as Label
		var symbol_name: String = entry.get("name", "")
		special_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))

		if special_label:
			if symbol_name.find("WILD") != -1:
				special_label.text = "REPLACES ANY SYMBOL"
			elif symbol_name.find("BONUS") != -1:
				special_label.text = "TRIGGERS BONUS SCENE"
			else:
				special_label.text = ""

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
