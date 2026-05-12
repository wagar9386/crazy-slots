extends TextureButton

signal cell_pressed(cell)

var has_mine = false
var revealed = false

@onready var icon = $Sprite2D

@onready var mine_texture = preload("res://Ian/Bonus/Minas/assets/bomb.png")
@onready var safe_texture = preload("res://Ian/Bonus/Minas/assets/safe.png")

func _ready():

	icon.texture = null

	icon.scale = Vector2(0.4, 0.4)


func _on_pressed():

	emit_signal("cell_pressed", self)


func reveal_mine():

	icon.texture = mine_texture

	animate_icon()


func reveal_safe():

	icon.texture = safe_texture

	animate_icon()


func animate_icon():

	icon.scale = Vector2(0,0)

	var tween = create_tween()

	tween.tween_property(
		icon,
		"scale",
		Vector2(0.4,0.4),
		0.15
	).set_trans(Tween.TRANS_BACK)\
	 .set_ease(Tween.EASE_OUT)
