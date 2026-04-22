class_name SlotSpinAnimatorV2
extends Node

signal spin_completed

const BLUR_SHADER: Shader = preload("res://Goti/scripts/slot_spin_blur.gdshader")

var is_spinning: bool = false
var symbol_nodes: Array = []
var get_random_symbol_func: Callable
var textures: Dictionary = {}
var symbol_materials: Array = []

func setup(nodes: Array, random_func: Callable, tex_dict: Dictionary) -> void:
	symbol_nodes = nodes
	get_random_symbol_func = random_func
	textures = tex_dict
	_build_blur_materials()

func start_spin(final_grid: Array) -> void:
	if is_spinning:
		return
	is_spinning = true

	var rows: int = symbol_nodes.size()
	var cols: int = symbol_nodes[0].size()
	var base_spins: int = 12
	var spin_delay: float = 0.025
	
	# Reset all blur just in case
	_set_all_blur(0.0)

	for column in range(cols):
		# Only blur the current column that is about to spin
		_set_column_blur(column, 4.0)
		
		var column_spins: int = base_spins + (column * 3)
		for i in range(column_spins):
			# If we are in the last few frames, maybe reduce blur for a smoother transition
			if i > column_spins - 3:
				_set_column_blur(column, 1.5)
				
			for row in range(rows):
				var node: TextureRect = symbol_nodes[row][column] as TextureRect
				if node != null:
					var random_symbol: int = get_random_symbol_func.call() as int
					node.texture = textures.get(random_symbol)
					node.self_modulate = Color.WHITE
			await get_tree().create_timer(spin_delay).timeout

		# Snap back to clarity and set final symbols
		_set_column_blur(column, 0.0)
		for row in range(rows):
			var final_symbol: int = final_grid[column][row] as int
			var settle_node: TextureRect = symbol_nodes[row][column] as TextureRect
			if settle_node != null:
				settle_node.texture = textures.get(final_symbol)
				settle_node.self_modulate = Color.WHITE
				# Small pop animation for "stopping" feel
				var pop_tween: Tween = get_tree().create_tween()
				pop_tween.tween_property(settle_node, "scale", Vector2(1.15, 1.15), 0.07)
				pop_tween.tween_property(settle_node, "scale", Vector2.ONE, 0.07)

	is_spinning = false
	spin_completed.emit()

func _build_blur_materials() -> void:
	symbol_materials.clear()
	for row in range(symbol_nodes.size()):
		var row_materials: Array = []
		for column in range(symbol_nodes[row].size()):
			var symbol_node: TextureRect = symbol_nodes[row][column] as TextureRect
			var shader_material: ShaderMaterial = ShaderMaterial.new()
			shader_material.shader = BLUR_SHADER
			shader_material.set_shader_parameter("blur_strength", 0.0)
			if symbol_node != null:
				symbol_node.material = shader_material
			row_materials.append(shader_material)
		symbol_materials.append(row_materials)

func _set_all_blur(amount: float) -> void:
	for row in range(symbol_materials.size()):
		for column in range(symbol_materials[row].size()):
			var material: ShaderMaterial = symbol_materials[row][column] as ShaderMaterial
			if material != null:
				material.set_shader_parameter("blur_strength", amount)

func _set_column_blur(column: int, amount: float) -> void:
	for row in range(symbol_materials.size()):
		var material: ShaderMaterial = symbol_materials[row][column] as ShaderMaterial
		if material != null:
			material.set_shader_parameter("blur_strength", amount)
