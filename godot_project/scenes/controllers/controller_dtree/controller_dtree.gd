class_name AlgDTree
extends Node


@export_file("*.tscn") var panel_algorithm_dtree_scene: String
@export_file("*.tscn") var dnode_scene: String

var dtree: DTreeLogical
var canvas: Control
var view: Control  # Reference to the main view for UI elements
var next_node_id: int = 0
var mode: String = "manual"

# For automatic mode
var algorithm:              AlgorithmDTree
var panel_algorithmn_dtree: Control
var next_step_button:       Button
var start_training_button:  Button


func initialize(p_tree: DTreeLogical, p_canvas: Control, p_mode: String, p_view: Control = null) -> void:
	dtree = p_tree
	canvas = p_canvas
	view = p_view if p_view != null else p_canvas
	mode = p_mode

	# Initialize next_node_id based on existing nodes
	for id in dtree.nodes_dict.keys():
		if id >= next_node_id:
			next_node_id = id + 1

	if mode == "manual":
		_connect_all_node_signals()
	elif mode == "automatic":
		_setup_automatic_mode()
	
	_update_canvas()


# Manual mode related functions

# Recursive conect signals from root
func _connect_all_node_signals() -> void:
	if dtree == null:
		return
	for id in dtree.nodes_dict.keys():
		_connect_signal_for_node(id)


# Set the can_remove varible to true if not root, and connect the change_child_requested signal
func _connect_signal_for_node(id: int) -> void:
	var dnode = dtree.nodes_dict.get(id)
	if dnode == null:
		return
	
	# Set can_remove flag based on whether this is the root
	dnode.set("can_remove", id != dtree.root_id)
	
	# Connect the signal from the dnode
	if not dnode.change_child_requested.is_connected(_on_change_child_requested):
		dnode.change_child_requested.connect(_on_change_child_requested.bind(id))


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
	
	# The new node is created
	var dnode = preload("res://scenes/objects/dtree/dnode/dnode.tscn").instantiate()
	dnode.id = new_id
	dnode.parent_id = parent_id
	dnode.depth = parent_dnode.depth + 1

	# Is added to the three
	dtree.nodes_dict[new_id] = dnode
	dtree.nodes_container.add_child(dnode)

	# Is added to the list of childs of its parent
	parent_dnode.sons_id.append(new_id)

	# And is connected
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


# Automatic mode related functions

func _setup_automatic_mode() -> void:

	# Add UI for automatic mode
	panel_algorithmn_dtree = load(panel_algorithm_dtree_scene).instantiate()
	view.add_child(panel_algorithmn_dtree)
	panel_algorithmn_dtree.set_anchors_preset(Control.PRESET_TOP_LEFT)

	next_step_button = panel_algorithmn_dtree.get_node("VBoxContainer/NextButton")
	start_training_button = panel_algorithmn_dtree.get_node("VBoxContainer/StartTrainingButton")

	next_step_button.pressed.connect(_on_step_button_pressed)
	start_training_button.pressed.connect(_on_start_training_pressed)

	next_step_button.visible = false
	start_training_button.visible = true

	if algorithm:
		algorithm.add_node_requested.connect(_on_algorithm_add_node_requested)
		algorithm.step_start.connect(_on_algorithm_step)
		algorithm.step_calculating_entropy.connect(_on_algorithm_step_entropy)
		algorithm.step_calculating_gain.connect(_on_algorithm_step_gain)
		algorithm.step_best_attribute_selected.connect(_on_algorithm_step_best_attr)
		algorithm.step_creating_node.connect(_on_algorithm_step_node)
		algorithm.step_creating_branch.connect(_on_algorithm_step_branch)
		algorithm.step_all_same_class.connect(_on_algorithm_step_generic)
		algorithm.step_no_attributes_left.connect(_on_algorithm_step_generic)
		algorithm.algorithm_completed.connect(_on_algorithm_completed)



func _on_start_training_pressed() -> void:
	# Example data - you can modify this or add UI to input data
	var data: Array[Dictionary] = [
		{"color": "red", "shape": "round", "size": "big", "class": "apple"},
		{"color": "green", "shape": "round", "size": "big", "class": "apple"},
		{"color": "yellow", "shape": "long", "size": "medium", "class": "banana"},
		{"color": "green", "shape": "long", "size": "medium", "class": "banana"},
		{"color": "orange", "shape": "round", "size": "medium", "class": "orange"},
	]
	var attributes: Array[String] = ["color", "shape", "size"]
	
	if algorithm:
		algorithm.start_training(data, attributes, dtree)

		print("Training started!")

		next_step_button.visible = true
		start_training_button.visible = false


func _create_root_for_algorithm(attribute: String, label: String, is_leaf: bool) -> int:
	var dnode: DNode = load(dnode_scene).instantiate()
	dnode.id = 0
	dnode.depth = 0
	dnode.inorder_index = 0.0
	dnode.attribute = attribute
	dnode.label = label
	dnode.text = label if is_leaf else attribute
	dnode.is_leaf = is_leaf
	
	dtree.nodes_dict[0] = dnode
	dtree.nodes_container.add_child(dnode)
	dtree.root_id = 0
	next_node_id = 1
	
	return 0


func _add_child_node_for_algorithm(parent_id: int, branch_value, attribute: String, label: String, is_leaf: bool) -> int:
	var parent_dnode = dtree.nodes_dict.get(parent_id)
	if parent_dnode == null:
		print("Error: Parent node not found: ", parent_id)
		return -1
	
	var new_id = next_node_id
	next_node_id += 1
	
	# Create new node
	var dnode: DNode = preload("res://scenes/objects/dtree/dnode/dnode.tscn").instantiate()
	dnode.id = new_id
	dnode.parent_id = parent_id
	dnode.depth = parent_dnode.depth + 1
	dnode.attribute = attribute
	dnode.label = label
	dnode.text = label if is_leaf else attribute
	dnode.is_leaf = is_leaf
	dnode.branch_value = branch_value
	
	# Add to tree
	dtree.nodes_dict[new_id] = dnode
	dtree.nodes_container.add_child(dnode)
	parent_dnode.sons_id.append(new_id)
	
	return new_id


func _on_algorithm_add_node_requested(parent_id: int, branch_value, attribute: String, label: String, is_leaf: bool) -> void:
	# This is called by the algorithm to actually create nodes
	var created_node_id: int
	
	if parent_id == -1:
		# Create root
		created_node_id = _create_root_for_algorithm(attribute, label, is_leaf)
	else:
		# Create child
		created_node_id = _add_child_node_for_algorithm(parent_id, branch_value, attribute, label, is_leaf)
	
	# Always update algorithm's call stack with the actual node ID
	# This ensures child contexts waiting in the stack get the correct parent ID
	if algorithm and created_node_id != -1:
		algorithm.update_pending_parent_ids(created_node_id)
	
	dtree.relayout_tree()
	_update_canvas()


func _on_step_button_pressed() -> void:
	if algorithm:
		algorithm.next_step()


# Algorithm signal handlers

func _on_algorithm_step(step_type: String, step_data: Dictionary) -> void:
	print("Step: ", step_type, " - ", step_data)


func _on_algorithm_step_entropy(data_size: int, labels: Array) -> void:
	print("Calculating entropy for ", data_size, " samples with labels: ", labels)


func _on_algorithm_step_gain(attribute: String, gain: float) -> void:
	print("Gain for ", attribute, ": ", gain)


func _on_algorithm_step_best_attr(attribute: String, gain: float) -> void:
	print("Best attribute selected: ", attribute, " with gain: ", gain)


func _on_algorithm_step_node(node_type: String, attribute: String, label: String) -> void:
	print("Creating node - Type: ", node_type, ", Attr: ", attribute, ", Label: ", label)


func _on_algorithm_step_branch(parent_attr: String, branch_value, _is_leaf: bool) -> void:
	print("Creating branch from ", parent_attr, " with value ", branch_value)


func _on_algorithm_step_generic(data) -> void:
	print("Algorithm step: ", data)


func _on_algorithm_completed() -> void:
	print("Algorithm completed!")
	if next_step_button:
		next_step_button.disabled = true




func _update_canvas() -> void:
	if canvas and canvas.has_method("update_canvas_size_and_center"):
		canvas.update_canvas_size_and_center()
