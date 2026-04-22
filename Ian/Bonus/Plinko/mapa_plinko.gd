extends Node2D

	
var pin_scene = preload("res://Ian/Bonus/Plinko/pin.tscn")

func _ready():
	create_pins()

func create_pins():
	var rows = 8
	var spacing = 50

	for y in range(rows):
		for x in range(y + 1):
			var pin = pin_scene.instantiate()
			add_child(pin)
			
			pin.position = Vector2(
				300 + (x - y/2.0) * spacing,
				100 + y * spacing
			)
