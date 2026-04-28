extends Area2D

@export var multiplier: int = 1
@onready var label = $Label


func _ready():
	label.text = "x" + str(multiplier)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not body is RigidBody2D:
		return

	if body.has_meta("scored"):
		return

	body.set_meta("scored", true)

	var win = GameState.bet * multiplier
	GameState.credits += win

	show_win_effect(win)

	call_deferred("_free_ball", body)

func update_label():
	if label:
		label.text = "x" + str(multiplier)

func show_win_effect(win):
	var popup = Label.new()
	popup.text = "+" + str(win)
	add_child(popup)

	popup.position = Vector2(0, -20)
	popup.z_index = 10
	popup.scale = Vector2(1.5, 1.5)

	var tween = create_tween()

	tween.tween_property(popup, "position", popup.position + Vector2(0, -60), 1.0)
	tween.parallel().tween_property(popup, "modulate", Color(1,1,1,0), 1.0)
	tween.tween_callback(popup.queue_free)

func _free_ball(body):
	if is_instance_valid(body):
		body.queue_free()
