extends Node2D

@onready var wheel = $Sprite2D
@onready var label = $CanvasLayer/CreditsLabel
@onready var bet_label = $CanvasLayer/BetLabel
@onready var win_label = $CanvasLayer/WinLabel
@onready var spin_sound = $AudioStreamPlayer2D

var spinning = false

var sections = 8
var multipliers = [5, 10, 100, 50, 20, 10, 5, 2]

var final_result = 0
var rng = RandomNumberGenerator.new()

var angle_offset = 110

var last_section = -1


func _ready():
	rng.randomize()
	win_label.visible = false
	await get_tree().create_timer(0.6).timeout
	spin()


func spin():
	if spinning:
		return
	
	spinning = true
	
	final_result = rng.randi_range(0, sections - 1)
	last_section = -1
	
	var angle_per_section = 360.0 / sections
	
	var final_angle = (final_result * angle_per_section) + angle_per_section / 2.0 + angle_offset
	
	var current_rotation = wheel.rotation_degrees
	
	var target_rotation = current_rotation + 360 * 8
	
	target_rotation = target_rotation - fmod(target_rotation, 360) + final_angle
	
	var tween = create_tween()
	tween.tween_property(wheel, "rotation_degrees", target_rotation, 15.0)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		spinning = false
		apply_result(final_result)
	)


func _process(delta):
	label.text = "Coins: " + str(GameState.credits)
	bet_label.text = "Bet: " + str(GameState.bet)

	if spinning:
		var angle_per_section = 360.0 / sections
		
		var angle = fmod(wheel.rotation_degrees, 360.0)
		
		# 🔥 DESPLAZAMOS MEDIA SECCIÓN PARA QUE SUENE AL INICIO
		angle = fmod(angle + angle_per_section * 0.5, 360.0)
		
		var section = int(angle / angle_per_section)
		
		if section != last_section:
			last_section = section
			
			spin_sound.pitch_scale = randf_range(0.9, 1.1)
			spin_sound.play()


func apply_result(result):
	var multiplier = multipliers[result]
	var win = GameState.bet * multiplier
	
	GameState.credits += win
	
	show_final_animation(win)
	
	await get_tree().create_timer(6).timeout
	get_tree().change_scene_to_file("res://Goti/scenes/SlotMachine.tscn")


func show_final_animation(win: int) -> void:
	GameState.show_bonus_countup_animation(self, win)


func change_font_size(value, lbl):
	if is_instance_valid(lbl):
		lbl.add_theme_font_size_override("font_size", int(value))
