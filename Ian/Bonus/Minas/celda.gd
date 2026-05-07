extends TextureButton

signal cell_pressed(cell)

var has_mine = false
var revealed = false

@onready var icon = $Sprite2D

@onready var mine_texture = preload("res://Ian/Bonus/Minas/assets/bomb.png")
@onready var safe_texture = preload("res://Ian/Bonus/Minas/assets/safe.png")
@onready var default_texture = preload("res://Ian/Bonus/Minas/assets/Gemini_Generated_Image_439u9p439u9p439u (1).png")

func _ready():
	pressed.connect(_on_pressed)
	texture_normal = default_texture
	
	icon.texture = null
	icon.scale = Vector2(1, 1)

func _on_pressed():
	if revealed:
		return
	
	revealed = true
	emit_signal("cell_pressed", self)

func reveal_mine():
	icon.texture = mine_texture
	animate_icon()

func reveal_safe():
	icon.texture = safe_texture
	animate_icon()

func animate_icon():
	icon.scale = Vector2(0, 0)
	var tween = create_tween()
	tween.tween_property(icon, "scale", Vector2(0.4, 0.4), 0.2)

func reset():
	revealed = false
	has_mine = false
	icon.texture = null
	texture_normal = default_texture
