extends RigidBody2D

func _ready():
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 10
	linear_velocity = Vector2(randf_range(-15, 15), 0)


func _on_body_entered(body: Node) -> void:
	pass # Replace with function body.
