extends Control


func _ready() -> void:
	# When the NodoControl is created (the one that contains the node button) it connects to the signal "pressed" of its child Button to the funcion "_on_button_pressed".
	$Button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:

	var arbol_canvas = $"../ScrollContainer/ArbolCanvas" 

	# Cargar el contenido del json
	var json_content : String = _load_json_content("user://tree.json")

	_delete_prev_tree(arbol_canvas)

	_load_tree(arbol_canvas, json_content)

	print("Tree loaded")


func _load_json_content(path: String) -> String:

	# The json is read
	var file : FileAccess = FileAccess.open(path, FileAccess.ModeFlags.READ)

	# If the file does not exist
	if file == null:
		push_error("It wasn't possible to open the file to write: %s" % path)
		return ""

	# And the class file (FileAccess) has a method to return the content as a string
	return file.get_as_text()


func _load_tree(dtree_path: CanvasItem, json_content_raw: String) -> void:
	
	# Change from string string, a json, y de ese json podemos cargar el diccio
	var json_content: Dictionary = JSON.to_native(JSON.parse_string(json_content_raw))

	# Create the tree
	var dtree: DTreeLogical = preload("res://scenes/objects/dtree/dtree/dtree.tscn").instantiate()

	# print(json_content[0])

	# For each key of the json
	for node_id in json_content:

		# Get que diccionary of atributes of the node 
		var node_atributes: Dictionary = json_content[node_id]

		# Create a DNode scene instance for that id, and add it to the tree
		var dnode = preload("res://scenes/objects/dtree/dnode/dnode.tscn").instantiate()
		
		dnode.id = node_atributes["id"]
		dnode.parent_id = node_atributes["parent_id"]
		dnode.sons_id = node_atributes["sons_id"]
		dnode.depth = node_atributes["depth"]
		dnode.inorder_index = node_atributes["inorder_index"]

		dtree.nodes_dict[node_id] = dnode
	
	# Add the tree to the canvas first
	dtree_path.add_child(dtree)
	
	# Then add all DNode instances to the nodes_container
	for node_id in dtree.nodes_dict.keys():
		var dnode = dtree.nodes_dict[node_id]
		dtree.nodes_container.add_child(dnode)


func _delete_prev_tree(dtree_path: CanvasItem) -> void:
	
	var dtree = dtree_path.get_node_or_null("Arbol")

	if dtree:
		dtree.queue_free()
		print("There was a tree, so it was deleted")
