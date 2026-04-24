extends Node2D

var pin_scene = preload("res://Ian/Bonus/Plinko/pin.tscn")
var ball_scene = preload("res://Ian/Bonus/Plinko/ball.tscn")

func _ready():
	create_pins()

func create_pins():
	var rows = 16
	var spacing_x = 32
	var spacing_y = 32

	for y in range(rows):
		for x in range(3 + y):
			var pin = pin_scene.instantiate()
			add_child(pin)
			
			pin.position = Vector2(
				300 + (x - (3 + y - 1) / 2.0) * spacing_x,
				100 + y * spacing_y
			)


func spawn_ball():
	var ball = ball_scene.instantiate()
	add_child(ball)
	
	ball.position = Vector2(300, 50)

func _input(event):
	if event.is_pressed():
		spawn_ball()
