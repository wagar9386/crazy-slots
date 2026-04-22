extends Node2D

@export var nivell: Array[PackedScene]

var nivell_actual: int = 1
var _nivell_instanciat: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_crear_nivell(nivell_actual)
	


func _crear_nivell(numero_nivell: int):
	_nivell_instanciat = nivell[numero_nivell - 1].instantiate()
	add_child(_nivell_instanciat)
	
	var fills := _nivell_instanciat.get_children()
	for i in fills.size():
		if fills[i].is_in_group("personatges"):
			fills[i].personatge_mort.connect(_reiniciar_nivell)
			break


func _eliminar_nivell():
	_nivell_instanciat.queue_free()

func _reiniciar_nivell():
	_eliminar_nivell()
	_crear_nivell(nivell_actual)
