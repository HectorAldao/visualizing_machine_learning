extends Node
var dtree: DTreeLogical
var canvas: Control
var next_node_id: int = 0


func initialize(p_tree: DTreeLogical, p_canvas: Control) -> void:
	dtree = p_tree
	canvas = p_canvas
	# Initialize next_node_id based on existing nodes
	for id in dtree.nodes_dict.keys():
		if id >= next_node_id:
			next_node_id = id + 1
	_connect_all_node_signals()
	_update_canvas()


func _connect_all_node_signals() -> void:
	if dtree == null:
		return
	for id in dtree.nodes_dict.keys():
		_connect_signal_for_node(id)


func _connect_signal_for_node(id: int) -> void:
	var dnode = dtree.nodes_dict.get(id)
	if dnode == null:
		return
	
	# Set can_remove flag based on whether this is the root
	dnode.set("can_remove", id != dtree.root_id)
	
	# Connect the signal from the dnode (not Area2D anymore)
	if not dnode.is_connected("change_child_requested", Callable(self, "_on_change_child_requested")):
		dnode.connect("change_child_requested", Callable(self, "_on_change_child_requested").bind(id))


func _on_change_child_requested(type_of_change: String, parent_or_self_id: int) -> void:
	if dtree == null:
		return
	if type_of_change == "add":
		_add_child_node(parent_or_self_id)
	elif type_of_change == "remove":
		_remove_subtree_and_self(parent_or_self_id)

	dtree.relayout_tree()
	_update_canvas()


func _add_child_node(parent_id: int) -> void:
	var parent_dnode = dtree.nodes_dict.get(parent_id)
	var new_id = next_node_id
	next_node_id += 1
	
	var dnode = preload("res://scenes/objects/dtree/dnode/dnode.tscn").instantiate()
	dnode.id = new_id
	dnode.parent_id = parent_id
	dnode.depth = parent_dnode.depth + 1

	dtree.nodes_dict[new_id] = dnode

	parent_dnode.sons_id.append(new_id)

	dtree.nodes_container.add_child(dnode)

	_connect_signal_for_node(new_id)


func _remove_subtree_and_self(node_id: int) -> void:

	if not dtree.nodes_dict.has(node_id):
		return

	var dnode = dtree.nodes_dict[node_id]

	var parent_dnode = dtree.nodes_dict[dnode.parent_id]
	parent_dnode.sons_id.erase(dnode.id)

	# Delete childs recurively
	# Make a copy of sons_id to avoid modifying the array while iterating
	var children_copy = dnode.sons_id.duplicate()
	for child_id in children_copy:
		_remove_subtree_and_self(child_id)

	# Delete from dictionary
	dtree.nodes_dict.erase(node_id)
	
	# Free the physical Godot node
	dnode.queue_free()



func _update_canvas() -> void:
	if canvas and canvas.has_method("update_canvas_size_and_center"):
		canvas.update_canvas_size_and_center()
