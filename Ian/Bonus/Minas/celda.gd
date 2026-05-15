extends TextureButton

signal cell_pressed(cell)

var has_mine = false
var revealed = false

@onready var icon = $Sprite2D

@export var click_sound: AudioStream
@export var mine_sound: AudioStream
@export var safe_sound: AudioStream

@onready var mine_texture = preload("res://Ian/Bonus/Minas/assets/bomb.png")
@onready var safe_texture = preload("res://Ian/Bonus/Minas/assets/safe.png")


func _ready():
	icon.texture = null
	icon.scale = Vector2(0.4, 0.4)


func _on_pressed():
	play_click_sound()
	emit_signal("cell_pressed", self)


func reveal_mine():
	icon.texture = mine_texture
	animate_icon()
	play_result_sound(true)


func reveal_safe():
	icon.texture = safe_texture
	animate_icon()
	play_result_sound(false)


# 🎧 sonido click normal
func play_click_sound():
	var player = AudioStreamPlayer2D.new()
	get_tree().current_scene.add_child(player)

	player.global_position = global_position
	player.stream = click_sound
	player.pitch_scale = randf_range(0.95, 1.1)
	player.volume_db = -3

	player.play()
	player.finished.connect(player.queue_free)


# 💣 sonido resultado (bomba o safe)
func play_result_sound(is_mine: bool):
	var player = AudioStreamPlayer2D.new()
	get_tree().current_scene.add_child(player)

	player.global_position = global_position

	if is_mine:
		player.stream = mine_sound
		player.pitch_scale = 0.8  # más grave, más dramático
		player.volume_db = 0
	else:
		player.stream = safe_sound
		player.pitch_scale = 1.2  # más alegre
		player.volume_db = -2

	player.play()
	player.finished.connect(player.queue_free)


func animate_icon():
	icon.scale = Vector2(0, 0)

	var tween = create_tween()
	tween.tween_property(icon, "scale", Vector2(0.4, 0.4), 0.15)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
