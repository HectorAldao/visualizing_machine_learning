extends Node2D

func _draw():
	# Clear all existing connections first
	for child in get_children():
		child.queue_free()
	
	var dtree = get_parent() as DTreeLogical
	for ln in dtree.nodes_dict.values():
		if ln.sons_id != []:
			for child in ln.sons_id:
				_draw_edge(ln.id, child)

func _draw_edge(parent_id: int, child_id: int):
	var tree = get_parent() as DTreeLogical
	var parent_node = tree.nodes_dict[parent_id]
	var child_node = tree.nodes_dict[child_id]
	# draw_line(parent_node.position, child_node.position, Color.BLUE,	 2.0)
	var conection: Conection = preload("res://scenes/objects/dtree/conection/conection.tscn").instantiate() 

	conection.from_node = parent_node
	conection.to_node = child_node

	add_child(conection)
