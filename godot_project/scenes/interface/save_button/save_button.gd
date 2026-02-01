extends Control

func _ready() -> void:
	$Button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	_save_tree($"../ScrollContainer/ArbolCanvas/Arbol", "user://tree.json")


func _save_tree(arbol: Variant, file_path: String = "user://tree.json") -> void:

	var logical_nodes : Dictionary = arbol.nodes_dict

	var dict_of_nodes = _extract_atributes_from_nodes(logical_nodes)

	var json_string = _convert_to_json_string(dict_of_nodes)

	_save_json_to_file(json_string, file_path)

	print("Tree saved")


# func _extract_atributes_from_nodes(dict_of_nodes: Dictionary) -> Array:
func _extract_atributes_from_nodes(dict_of_nodes: Dictionary) -> Dictionary:

	# var list_of_nodes : Array[Dictionary] = []
	var dict_of_nodes_with_atributes : Dictionary = {}

	for node_id in dict_of_nodes:

		var node = dict_of_nodes[node_id]  # DNode
		var node_atributes : Dictionary = {}

		node_atributes["id"] = node.id
		node_atributes["parent_id"] = node.parent_id
		node_atributes["sons_id"] = node.sons_id
		node_atributes["depth"] = node.depth
		node_atributes["inorder_index"] = node.inorder_index

		# list_of_nodes.append(node_atributes)
		dict_of_nodes_with_atributes[node_id] = node_atributes
	
	# return list_of_nodes
	return dict_of_nodes_with_atributes


# func _convert_to_json_string(data: Array) -> String:
func _convert_to_json_string(data: Dictionary) -> String:

	var result = JSON.stringify(JSON.from_native(data))

	if result == "":
		print("Error converting to JSON")
		return ""

	return result


func _save_json_to_file(json_string: String, save_path ) -> void:

	var file := FileAccess.open(save_path, FileAccess.ModeFlags.WRITE)

	if file == null:
		push_error("It wasn't possible to open the file to write: %s" % save_path)
		return

	file.store_string(json_string)

	file.close()
