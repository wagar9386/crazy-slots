extends RigidBody2D

func _ready():
	linear_velocity.x = randf_range(-1, 1)
