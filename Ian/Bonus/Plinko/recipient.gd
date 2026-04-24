extends Area2D

@export var multiplier: int = 1

func _on_body_entered(body):
	if body.name == "Ball":
		Script_slot.apply_win(multiplier)
		body.queue_free()
