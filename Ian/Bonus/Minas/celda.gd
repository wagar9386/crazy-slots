extends TextureButton

var has_mine = false
var revealed = false

signal cell_pressed(cell)

@onready var mine_texture = preload("res://Ian/Bonus/Minas/assets/bomb.png")
@onready var safe_texture = preload("res://Ian/Bonus/Minas/assets/safe.png")

func _ready():
	self.texture_normal = null  # o textura base de la casilla

func _on_pressed():
	if revealed:
		return

	revealed = true
	emit_signal("cell_pressed", self)

func reveal_mine():
	texture_normal = mine_texture

func reveal_safe():
	texture_normal = safe_texture
