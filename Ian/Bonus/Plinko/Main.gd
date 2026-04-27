extends Node2D

var pin_scene = preload("res://Ian/Bonus/Plinko/pin.tscn")
var ball_scene = preload("res://Ian/Bonus/Plinko/ball.tscn")
var slot_scene = preload("res://Ian/Bonus/Plinko/recipient.tscn")

@onready var label = $CanvasLayer/Label


var rows = 16
var spacing_x = 32
var spacing_y = 32
var start_x = 300
var start_y = 100

var multipliers = [0, 0, 1, 2, 5, 10, 20, 50, 100, 50, 20, 10, 5, 2, 1, 0, 0]

func _ready():
	print(get_node(".").get_children())
	create_pins()
	create_slots()

func create_pins():
	for y in range(rows):
		for x in range(3 + y):
			var pin = pin_scene.instantiate()
			add_child(pin)

			pin.position = Vector2(
				start_x + (x - (3 + y - 1) / 2.0) * spacing_x,
				start_y + y * spacing_y
			)

func create_slots():
	var y_pos = start_y + rows * spacing_y + 40

	for i in range(rows + 1):
		var slot = slot_scene.instantiate()
		add_child(slot)

		slot.position = Vector2(
			start_x + (i - rows / 2.0) * spacing_x,
			y_pos
		)

		slot.multiplier = multipliers[i]

func spawn_ball():
	var ball = ball_scene.instantiate()
	add_child(ball)

	ball.position = Vector2(start_x, 50)

func _input(event):
	if event.is_pressed():
		spawn_ball()

func _process(delta):
	label.text = "Coins: " + str(Script_slot.credits)
