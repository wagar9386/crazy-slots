extends Node2D

# CONFIGURACIÓ
var rows = 8
var spacing = 50
var start_x = 300
var start_y = 100

var ball_radius = 10

func _ready():
	print("Ready funciona")
	create_walls()
	create_pins()

func _input(event):
	if event.is_pressed():
		spawn_ball()

##################################################
# CREAR BOLA
##################################################
func spawn_ball():
	var ball = RigidBody2D.new()
	add_child(ball)

	ball.position = Vector2(300, 50)
	ball.gravity_scale = 1

	# Col·lisió
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = ball_radius
	shape.shape = circle
	ball.add_child(shape)

	# Física material (rebot)
	var material = PhysicsMaterial.new()
	material.bounce = 0.6
	material.friction = 0.2
	ball.physics_material_override = material

##################################################
# CREAR PINS
##################################################
func create_pins():
	for y in range(rows):
		for x in range(y + 1):
			var pin = StaticBody2D.new()
			add_child(pin)

			pin.position = Vector2(
				start_x + (x - y / 2.0) * spacing,
				start_y + y * spacing
			)

			var shape = CollisionShape2D.new()
			var circle = CircleShape2D.new()
			circle.radius = 5
			shape.shape = circle
			pin.add_child(shape)

##################################################
# CREAR PARETS I COMPARTIMENTS
##################################################
func create_walls():

	# Terra
	var floor = StaticBody2D.new()
	add_child(floor)

	floor.position = Vector2(300, 600)

	var floor_shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(600, 20)
	floor_shape.shape = rect
	floor.add_child(floor_shape)

	# Parets laterals
	create_wall(Vector2(50, 300), Vector2(20, 600))
	create_wall(Vector2(550, 300), Vector2(20, 600))

	# Compartiments finals
	var divisions = 6
	var width = 600 / divisions

	for i in range(divisions + 1):
		create_wall(
			Vector2(i * width, 550),
			Vector2(10, 100)
		)

##################################################
# FUNCIO AUXILIAR PER PARETS
##################################################
func create_wall(pos, size):
	var wall = StaticBody2D.new()
	add_child(wall)

	wall.position = pos

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
