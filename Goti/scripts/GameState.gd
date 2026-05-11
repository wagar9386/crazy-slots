extends Node

var credits: int = 100
var bet: int = 4

# Slot machine fonts and colors
const COWBOY_MOVIE_FONT: Font = preload("res://Goti/assets/Cowboy Movie.ttf")
const WIN_ANIMATION_COLOR: Color = Color(1.0, 0.9, 0.2, 1)
const WIN_ANIMATION_OUTLINE: Color = Color(0.12, 0.03, 0.0)

func show_bonus_countup_animation(parent_node: Node, win_amount: int) -> void:
	if not parent_node:
		return
	
	var big_label: Label = Label.new()
	big_label.add_theme_font_override("font", COWBOY_MOVIE_FONT)
	big_label.add_theme_font_size_override("font_size", 160)
	big_label.add_theme_color_override("font_color", WIN_ANIMATION_COLOR)
	big_label.add_theme_constant_override("outline_size", 14)
	big_label.add_theme_color_override("font_outline_color", WIN_ANIMATION_OUTLINE)
	big_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	big_label.text = "+0"
	
	# Find or create CanvasLayer for UI overlay
	var canvas_layer: CanvasLayer = null
	for child: Node in parent_node.get_children():
		if child is CanvasLayer:
			canvas_layer = child
			break
	
	if canvas_layer == null:
		canvas_layer = CanvasLayer.new()
		parent_node.add_child(canvas_layer)
	
	# Create a Control container to properly center the label on screen
	var control_container: Control = Control.new()
	control_container.anchor_left = 0.0
	control_container.anchor_top = 0.0
	control_container.anchor_right = 1.0
	control_container.anchor_bottom = 1.0
	control_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(control_container)
	
	# Add label to the container and center it using anchors
	big_label.anchor_left = 0.5
	big_label.anchor_top = 0.5
	big_label.anchor_right = 0.5
	big_label.anchor_bottom = 0.5
	big_label.offset_left = -220
	big_label.offset_top = -200
	big_label.offset_right = 180
	big_label.offset_bottom = 200
	control_container.add_child(big_label)
	
	var tween := parent_node.create_tween()
	
	# Pop in
	tween.tween_property(big_label, "scale", Vector2(1.35, 1.35), 0.24)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(big_label, "modulate", Color(1, 1, 1, 1), 0.18)
	tween.tween_property(big_label, "scale", Vector2(1.05, 1.05), 0.10).set_ease(Tween.EASE_IN)
	
	# Count up
	tween.tween_method(func(v):
		if big_label:
			big_label.text = "+%d" % int(v)
	, 0.0, float(win_amount), 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Bounce
	tween.tween_property(big_label, "scale", Vector2(1.25, 1.25), 0.14).set_ease(Tween.EASE_OUT)
	tween.tween_property(big_label, "scale", Vector2(1.05, 1.05), 0.10).set_ease(Tween.EASE_IN)
	
	# Shimmer loop
	var shimmer: Tween = parent_node.create_tween().set_loops()
	shimmer.tween_property(big_label, "modulate", Color(1.0, 0.85, 0.2, 1), 0.3)
	shimmer.tween_property(big_label, "modulate", Color(0.987, 0.828, 0.0, 1.0), 0.3)
