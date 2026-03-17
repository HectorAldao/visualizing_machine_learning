class_name ControllerDTree
extends Node

signal next_step
signal detail

const panel_algorithm_dtree_scene: String = Constants.SCENES.panel_algorithm_dtree
const dnode_scene: String = Constants.SCENES.dnode

var dtree: DTreeLogical
var window: Window
var view: Control  # Reference to the main view for UI elements
var next_node_id: int = 0
var mode: String = "manual"

# For automatic mode
var algorithm:              AlgorithmDTree
var panel_algorithm_dtree:  Control
var next_step_button:       Button
var start_training_button:  Button
var detail_button:          Button


func initialize(p_tree: DTreeLogical, p_window: Window, p_mode: String, p_view: Control = null) -> void:
	dtree = p_tree
	window = p_window
	view = p_view if p_view != null else p_tree
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
	var dnode: DNode = dtree.nodes_dict.get(id)
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
	var parent_dnode: DNode = dtree.nodes_dict.get(parent_id)
	var new_id: int = next_node_id
	next_node_id += 1
	
	# The new node is created
	var dnode: DNode = preload(dnode_scene).instantiate()
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

	var dnode: DNode = dtree.nodes_dict[node_id]

	var parent_dnode: DNode = dtree.nodes_dict[dnode.parent_id]
	parent_dnode.sons_id.erase(dnode.id)

	# Delete childs recurively
	# Make a copy of sons_id to avoid modifying the array while iterating
	var children_copy: Array[int] = dnode.sons_id.duplicate()
	for child_id in children_copy:
		_remove_subtree_and_self(child_id)

	# Delete from dictionary
	dtree.nodes_dict.erase(node_id)
	
	# Free the physical Godot node
	dnode.queue_free()


# Automatic mode related functions #

func _setup_automatic_mode() -> void:

	# Add UI for automatic mode
	panel_algorithm_dtree = preload(panel_algorithm_dtree_scene).instantiate()
	view.add_child(panel_algorithm_dtree)
	panel_algorithm_dtree.set_anchors_preset(Control.PRESET_TOP_LEFT)

	next_step_button = panel_algorithm_dtree.get_node("VBoxContainer/NextButton")
	start_training_button = panel_algorithm_dtree.get_node("VBoxContainer/StartTrainingButton")
	detail_button = panel_algorithm_dtree.get_node("VBoxContainer/DetailButton")

	next_step_button.pressed.connect(_on_step_button_pressed)
	start_training_button.pressed.connect(_on_start_training_pressed)
	detail_button.pressed.connect(_on_detail_button_pressed)

	next_step_button.      visible = false
	start_training_button. visible = true
	detail_button.         visible = false

	if algorithm:

		algorithm. add_node_requested           .connect(_on_algorithm_add_node_requested)

		#algorithm. step_start                   .connect(_on_algorithm_step)
		#algorithm. step_calculating_info_gain   .connect(_on_algorithm_step_entropy)
		#algorithm. step_calculating_gain        .connect(_on_algorithm_step_gain)
		#algorithm. step_best_attribute_selected .connect(_on_algorithm_step_best_attr)
		#algorithm. step_creating_node           .connect(_on_algorithm_step_node)
		#algorithm. step_creating_branch         .connect(_on_algorithm_step_branch)
		#algorithm. step_all_same_class          .connect(_on_algorithm_all_same_class)
		#algorithm. step_no_attributes_left      .connect(_on_algorithm_no_atributes_left)
		algorithm. algorithm_completed          .connect(_on_algorithm_completed)

		next_step.connect(algorithm.next_step)



func _on_start_training_pressed() -> void:
	
	var data: Array[Dictionary]
	var attributes: Array[String]
	
	data = [
		{"color": "red", "shape": "round", "size": "big", "class": "apple"},
		{"color": "green", "shape": "round", "size": "big", "class": "apple"},
		{"color": "yellow", "shape": "long", "size": "medium", "class": "banana"},
		{"color": "green", "shape": "long", "size": "medium", "class": "banana"},
		{"color": "orange", "shape": "round", "size": "medium", "class": "orange"},
	]
	attributes = ["color", "shape", "size"]
	
	data = [
	# --- Situación Extrema 1: Rama Pura Perfecta (Tipo=Roca + Estado=Seco -> Siempre Inerte) ---
	{"tipo": "roca", "estado": "seco", "tamaño": "pequeño", "clase": "inerte"},
	{"tipo": "roca", "estado": "seco", "tamaño": "grande", "clase": "inerte"},
	{"tipo": "roca", "estado": "seco", "tamaño": "gigante", "clase": "inerte"},
	
	# --- Situación Extrema 2: Rama Mixta 50/50 (Tipo=Animal + Estado=Activo -> Depredador o Presa) ---
	{"tipo": "animal", "estado": "activo", "tamaño": "pequeño", "clase": "depredador"}, # Pequeño y activo = depredador (ej. halcón)
	{"tipo": "animal", "estado": "activo", "tamaño": "pequeño", "clase": "presa"},     # Pequeño y activo = presa (ej. conejo)
	{"tipo": "animal", "estado": "activo", "tamaño": "grande", "clase": "depredador"}, # Grande y activo = depredador (ej. león)
	{"tipo": "animal", "estado": "activo", "tamaño": "grande", "clase": "presa"},      # Grande y activo = presa (ej. elefante)
	
	# --- Situación Extrema 3: Definición con pocos atributos (Tipo=Planta -> Siempre Vegetal) ---
	{"tipo": "planta", "estado": "viva", "tamaño": "pequeño", "clase": "vegetal"},
	{"tipo": "planta", "estado": "muerta", "tamaño": "grande", "clase": "vegetal"},
	{"tipo": "planta", "estado": "viva", "tamaño": "gigante", "clase": "vegetal"},
	{"tipo": "planta", "estado": "secada", "tamaño": "pequeño", "clase": "vegetal"},
	
	# --- Casos de Ruido y Contradicción para probar la profundidad ---
	{"tipo": "animal", "estado": "inactivo", "tamaño": "pequeño", "clase": "presa"},
	{"tipo": "animal", "estado": "inactivo", "tamaño": "grande", "clase": "depredador"}, # Dormido pero grande sigue siendo depredador
	{"tipo": "roca", "estado": "mojado", "tamaño": "pequeño", "clase": "inerte"},
	{"tipo": "roca", "estado": "mojado", "tamaño": "gigante", "clase": "inerte"},
	
	# --- Casos de borde para ver cómo se ramifica el resto ---
	{"tipo": "planta", "estado": "viva", "tamaño": "mediano", "clase": "vegetal"},
	{"tipo": "animal", "estado": "activo", "tamaño": "mediano", "clase": "depredador"},
	{"tipo": "animal", "estado": "activo", "tamaño": "mediano", "clase": "presa"},
	{"tipo": "roca", "estado": "seco", "tamaño": "mediano", "clase": "inerte"},
]

	attributes = ["tipo", "estado", "tamaño"]
	
	if algorithm:
		algorithm.label_column = data[0].keys().filter(func(element): return not attributes.has(element))[0]
		algorithm.start_training(data, attributes, dtree)

		print("Training started!")

		next_step_button.visible = true
		start_training_button.visible = false


func _create_root_for_algorithm(attribute: String, label: String, is_leaf: bool, info_value: String) -> int:
	var dnode: DNode = preload(dnode_scene).instantiate()
	dnode.id = 0
	dnode.depth = 0
	dnode.inorder_index = 0.0
	dnode.attribute = attribute
	dnode.label = label
	dnode.text = label if is_leaf else attribute
	dnode.is_leaf = is_leaf
	dnode.information_variable_value = info_value

	# No popup menu if is not manual
	dnode.was_created_by_algorithm = true
	
	dtree.nodes_dict[0] = dnode
	dtree.nodes_container.add_child(dnode)
	dtree.root_id = 0
	next_node_id = 1
	
	return 0


func _add_child_node_for_algorithm(parent_id: int, branch_value, attribute: String, label: String, is_leaf: bool, info_value: String) -> int:
	var parent_dnode: DNode = dtree.nodes_dict.get(parent_id)
	if parent_dnode == null:
		print("Error: Parent node not found: ", parent_id)
		return -1
	
	# Check if a placeholder was pre-created for this branch and update it
	for id in parent_dnode.sons_id:
		var child: DNode = dtree.nodes_dict.get(id)
		if child != null and child.branch_value == branch_value:
			child.attribute                = attribute
			child.label                    = label
			child.is_leaf                  = is_leaf
			child.is_pending               = false
			child.information_variable_value = info_value
			child.apply_theme_animated(child.leaf_theme if is_leaf else child.noleaf_theme, label if is_leaf else attribute)
			return id
	
	# No placeholder found — create a brand-new node (fallback / root-child path)
	var new_id: int = next_node_id
	next_node_id += 1
	
	var dnode: DNode = preload(dnode_scene).instantiate()
	dnode.id = new_id
	dnode.parent_id = parent_id
	dnode.depth = parent_dnode.depth + 1
	dnode.attribute = attribute
	dnode.label = label
	dnode.text = label if is_leaf else attribute
	dnode.is_leaf = is_leaf
	dnode.branch_value = branch_value
	dnode.was_created_by_algorithm = true
	dnode.information_variable_value = info_value
	
	dtree.nodes_dict[new_id] = dnode
	dtree.nodes_container.add_child(dnode)
	parent_dnode.sons_id.append(new_id)
	
	return new_id


# Creates a placeholder DNode for each branch value and links them to the parent.
# Called before update_pending_parent_ids so the algorithm can map branch_value -> node_id.
func _create_placeholder_children(parent_id: int, parent_depth: int, branch_values: Array) -> void:
	var branch_to_id: Dictionary = {}
	for value in branch_values:
		var new_id: int = next_node_id
		next_node_id += 1
		
		var placeholder: DNode = preload(dnode_scene).instantiate()
		placeholder.id                    = new_id
		placeholder.parent_id             = parent_id
		placeholder.depth                 = parent_depth + 1
		placeholder.branch_value          = value
		placeholder.was_created_by_algorithm = true
		placeholder.is_pending            = true
		placeholder.text                  = "..."
		
		dtree.nodes_dict[new_id] = placeholder
		dtree.nodes_container.add_child(placeholder)
		dtree.nodes_dict[parent_id].sons_id.append(new_id)
		
		branch_to_id[value] = new_id
	
	if algorithm:
		algorithm.register_placeholder_node_ids(branch_to_id)


func _on_algorithm_add_node_requested(parent_id: int, branch_value, attribute: String, label: String, is_leaf: bool, children_branch_values: Array, info_value: String) -> void:
	# This is called by the algorithm to actually create nodes
	var created_node_id: int
	
	if parent_id == -1:  # Is root
		created_node_id = _create_root_for_algorithm(attribute, label, is_leaf, info_value)
	else:  # Is child
		created_node_id = _add_child_node_for_algorithm(parent_id, branch_value, attribute, label, is_leaf, info_value)
	
	if algorithm and created_node_id != -1:
		# Pre-create placeholder children BEFORE update_pending_parent_ids so that
		# register_placeholder_node_ids can match contexts that still have parent_id == -2.
		if not children_branch_values.is_empty():
			var depth: int = dtree.nodes_dict[created_node_id].depth
			_create_placeholder_children(created_node_id, depth, children_branch_values)
		# Now resolve -2 parent placeholders to the actual node ID
		algorithm.update_pending_parent_ids(created_node_id)
	
	window.update_current_text(algorithm.details)
	dtree.relayout_tree()
	_update_canvas()


func _on_step_button_pressed() -> void:
	next_step.emit()


func _on_detail_button_pressed():
	detail.emit()


# Algorithm signal handlers

#func _on_algorithm_step(step_type: String, step_data: Dictionary) -> void:
	#print("Step: ", step_type, " - ", step_data)
#
#
#func _on_algorithm_step_entropy(data_size: int, labels: Array) -> void:
	#print("Calculating entropy for ", data_size, " samples with labels: ", labels)
#
#
#func _on_algorithm_step_gain(attribute: String, gain: float) -> void:
	#print("Gain for ", attribute, ": ", gain)
#
#
#func _on_algorithm_step_best_attr(attribute: String, gain: float) -> void:
	#print("Best attribute selected: ", attribute, " with gain: ", gain)
	#node_creation_case = "default"
#
#
#func _on_algorithm_step_node(node_type: String, attribute: String, label: String) -> void:
	#print("Creating node - Type: ", node_type, ", Attr: ", attribute, ", Label: ", label)
#
#
#func _on_algorithm_step_branch(parent_attr: String, branch_value, _is_leaf: bool) -> void:
	#print("Creating branch from ", parent_attr, " with value ", branch_value)
#
#
#func _on_algorithm_all_same_class(label) -> void:
	#print("All same class: ", label)
	#node_creation_case = "all_same_class"
#
#
#func _on_algorithm_no_atributes_left(mayority) -> void:
	#print("No atributes left, the mayority label is ", mayority )
	#node_creation_case = "no_atributes_left"


func _on_algorithm_completed() -> void:
	print("Algorithm completed!")
	if next_step_button:
		next_step_button.disabled = true



func _update_canvas() -> void:
	if dtree and dtree.has_method("update_canvas_size_and_center"):
		dtree.update_canvas_size_and_center()
