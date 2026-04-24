extends Area2D

@export var multiplier: int = 1

func _on_body_entered(body):
	if body.name == "Ball":
		var win = Script_slot.bet * multiplier
		Script_slot.credits += win
		body.queue_free()
