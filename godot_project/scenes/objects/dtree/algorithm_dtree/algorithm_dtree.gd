extends Node
class_name AlgorithmDTree


# Signals for algorithm steps
#signal step_start(step_type: String, step_data: Dictionary)
#signal step_calculating_info_gain(data_size: int, labels: Array)
#signal step_calculating_gain(attribute: String, gain: float)
#signal step_best_attribute_selected(attribute: String, gain: float)
#signal step_creating_node(node_type: String, attribute: String, label: String)
#signal step_creating_branch(parent_attr: String, branch_value, is_leaf: bool)
#signal step_all_same_class(label: String)
#signal step_no_attributes_left(majority_label: String)
signal algorithm_completed()

# Signal to request node/edge creation (same as manual mode)
# children_branch_values carries the branch values for pre-creating placeholder children
signal add_node_requested(parent_id: int, branch_value, attribute: String, label: String, is_leaf: bool, children_branch_values: Array, info_value: String)


# Algorithm state
var is_running: bool = false
var current_step: int = 0

# Training data
var training_data: Array = []
var available_attributes: Array[String] = []

# Tree reference (passed from dtree.gd)
var dtree_ref: DTreeLogical

# Call stack for step-by-step execution
var call_stack: Array = []
var called_stack: Array = []

# Details dict of facts for the current node
# that is going to be used for futher explication
var details: Dictionary = {}

# Track parent node IDs for each context
var pending_parent_id: int = -1
var last_created_node_id: int = -1

var label_column: String


func _ready() -> void:
	SignalsObserver.start_evaluation.connect(_evaluate_dtree)
	#SignalsObserver.drop_data.connect()


# Buttons related functions #

func start_training(data: Array[Dictionary], attributes: Array[String], dtree: DTreeLogical) -> void:
	training_data = data
	available_attributes = attributes.duplicate()
	dtree_ref = dtree
	is_running = true
	current_step = 0
	call_stack.clear()
	pending_parent_id = -1
	last_created_node_id = -1

	# The "context" dictionaries contain for deach node the information
	# needed to process that node
	
	# Initialize the root node building process
	var root_context: Dictionary[String, Variant] = {
		"data": data,
		"attributes": attributes.duplicate(),
		"parent_id": -1,  # No parent for root
		"branch_value": null,
		"depth": 0,
		"node_id": -1  # Will be assigned when created
	}
	call_stack.append(root_context)
	
	


func next_step() -> void:
	if not is_running or call_stack.is_empty():
		algorithm_completed.emit()
		is_running = false
		return
	
	var context = call_stack.pop_back()
	called_stack.append(context)
	_build_node_step(context)

func previous_step() -> void:
	if called_stack.is_empty():
		return

	if not is_running:
		is_running = true

	var context = called_stack.pop_back()
	call_stack.append(context)
	_unbuild_node_step(context)


# Huge function: decide the node #

func _build_node_step(context: Dictionary) -> void:

	var data: Array = context["data"]
	var attributes: Array = context["attributes"]
	var parent_id: int = context["parent_id"]
	var branch_value = context.get("branch_value", null)
	var depth: int = context["depth"]
	
	# Get the list of ground truth
	var labels = _get_labels(data)
	
	details["lista_etiquetas"] = labels
	details["numero_de_datos"] = data.size()
	details["lista_atributos"] = attributes
	
	# Get the set of labels
	var unique_labels: Array = _get_unique_labels(labels)
	

	# First, check if the node has some "extreme" case

	# Check if all samples belong to the same class
	if unique_labels.size() == 1:
		# If all the samples belong to the same class, pick it
		var label = labels[0]

		details["tipo_de_nodo"] = "leaf"
		
		add_node_requested.emit(parent_id, branch_value, "", label, true, [], "")
		return
	
	# Check if no attributes left
	if attributes.is_empty():
		# If there is no atribute left, pick the majority class
		var majority_label = _majority_class(labels)
		
		details["tipo_de_nodo"] = "leaf_majority"
		details["etiqueta_mayoritaria"] = majority_label
		
		add_node_requested.emit(parent_id, branch_value, "", majority_label, true, [], "")
		return
	
	# Calculate information gain for all attributes
	#details["ganancias_info"] = {}
	var gains: Dictionary[String, float] = _information_gains_for_all_atributes(attributes, data)
	
	#var concatenation: String = ""
	#for key in gains:
		#concatenation += str(key) + " = " + str(gains[key]) + "\n"
	details["lista_ganancias"] = gains
	
	
	# Select best attribute
	var best_attr: String = ""
	var best_gain: float = -INF
	for attr in gains:
		if gains[attr] > best_gain:
			best_gain = gains[attr]
			best_attr = attr
	
	# Count how many attributes have the maximum gain
	var max_gain_attributes: Array = []
	for attr in gains:
		if gains[attr] == best_gain:
			max_gain_attributes.append(attr)
	
	details["mejor_atributo"] = best_attr
	details["valor_metrica_mejor_atributo"] = best_gain
	details["n_atributos_con_ganancia_maxima"] = max_gain_attributes.size()
	
	# Set node type based on whether there are multiple attributes with max gain
	if max_gain_attributes.size() > 1:
		details["tipo_de_nodo"] = "internal_multi_atribute"
	else:
		details["tipo_de_nodo"] = "internal"
	
	# Create branches for each attribute value in the data
	var best_attr_values_set: Array = _attribute_values_set_in_data(data, best_attr)
	
	var remaining_attrs: Array = _get_remaining_attrs(attributes, best_attr)

	# For each value of the selected atribute in the data
  	# Add child contexts to call stack (in reverse order so they process in correct order)
	var ramas_mejor_atributo: Array
	for i in range(best_attr_values_set.size() - 1, -1, -1):
		var value = best_attr_values_set[i]
		var subset_of_data_with_value = []
		for row in data:
			if row[best_attr] == value:
				subset_of_data_with_value.append(row)
				
		ramas_mejor_atributo.append(value)
		#step_creating_branch.emit(best_attr, value, subset_of_data_with_value.is_empty())
		
		if subset_of_data_with_value.is_empty():
			# Empty subset - create leaf with majority class
			var majority = _majority_class(labels)
			var child_context = {
				"data": [{"class": majority}],  # Dummy data
				"attributes": [],
				"parent_id": -2,
				"branch_value": value,
				"depth": depth + 1,
				"is_empty_leaf": true
			}
			call_stack.append(child_context)
		else:
			# Continue building subtree
			var child_context = {
				"data": subset_of_data_with_value,
				"attributes": remaining_attrs.duplicate(),
				"parent_id": -2,
				"branch_value": value,
				"depth": depth + 1
			}
			call_stack.append(child_context)
	
	details["lista_ramas_mejor_atributo"] = ramas_mejor_atributo
	# Create internal node AFTER adding children to stack
	# This ensures children are in the call stack when update_pending_parent_ids is called
	add_node_requested.emit(parent_id, branch_value, best_attr, "", false, best_attr_values_set, "%.2f" % best_gain)



func _unbuild_node_step(context: Dictionary) -> void:
	if dtree_ref == null:
		return

	var node_id: int = _resolve_context_node_id(context)
	if node_id == -1:
		return

	var is_internal_node: bool = _is_internal_context(context)
	if is_internal_node:
		_remove_child_contexts_for_parent(node_id)
		_remove_visual_children_for_node(node_id)

	var parent_id: int = context.get("parent_id", -1)
	var had_placeholder: bool = int(context.get("node_id", -1)) >= 0

	if parent_id == -1:
		dtree_ref.remove_subtree_and_self(node_id)
		context["node_id"] = -1
	elif had_placeholder:
		dtree_ref.restore_node_as_pending(node_id)
	else:
		dtree_ref.remove_subtree_and_self(node_id)
		context["node_id"] = -1

	dtree_ref.relayout_tree()
	if dtree_ref.has_method("update_canvas_size_and_center"):
		dtree_ref.update_canvas_size_and_center()


func _resolve_context_node_id(context: Dictionary) -> int:
	var context_node_id: int = int(context.get("node_id", -1))
	if context_node_id >= 0 and dtree_ref.nodes_dict.has(context_node_id):
		return context_node_id

	var parent_id: int = int(context.get("parent_id", -1))
	if parent_id == -1:
		return int(dtree_ref.root_id) if dtree_ref.root_id != null else -1

	if not dtree_ref.nodes_dict.has(parent_id):
		return -1

	var parent_node: DNode = dtree_ref.nodes_dict[parent_id]
	var branch_value = context.get("branch_value", null)
	for child_id in parent_node.sons_id:
		if not dtree_ref.nodes_dict.has(child_id):
			continue
		var child_node: DNode = dtree_ref.nodes_dict[child_id]
		if child_node.branch_value == branch_value:
			return child_id

	return -1


func _is_internal_context(context: Dictionary) -> bool:
	var data: Array = context.get("data", [])
	var attributes: Array = context.get("attributes", [])
	var labels: Array = _get_labels(data)
	var unique_labels: Array = _get_unique_labels(labels)

	if unique_labels.size() == 1:
		return false

	if attributes.is_empty():
		return false

	return true


func _remove_child_contexts_for_parent(parent_node_id: int) -> void:
	for i in range(call_stack.size() - 1, -1, -1):
		var ctx = call_stack[i]
		if int(ctx.get("parent_id", -999999)) == parent_node_id:
			call_stack.remove_at(i)


func _remove_visual_children_for_node(node_id: int) -> void:
	if not dtree_ref.nodes_dict.has(node_id):
		return

	var dnode: DNode = dtree_ref.nodes_dict[node_id]
	var children_copy: Array[int] = dnode.sons_id.duplicate()
	for child_id in children_copy:
		dtree_ref.remove_subtree_and_self(child_id)


# Helper functions

func _get_labels(data: Array) -> Array:
	var labels = []
	for row in data:
		labels.append(row[label_column])
	return labels


func _get_unique_labels(labels: Array) -> Array:
	var unique_labels: Array = []
	for label in labels:
		if not unique_labels.has(label):
			unique_labels.append(label)
	return unique_labels


func _majority_class(labels: Array) -> String:
	# Count in a dictionary the amount of data with each label
	var counts: Dictionary  = {}
	for label in labels:
		if not counts.has(label):
			counts[label] = 0
		counts[label] += 1
	
	# And iterate through the dictionary to get the highest
	var max_label = ""
	var max_count = 0
	for label in counts:
		if counts[label] > max_count:
			max_count = counts[label]
			max_label = label
	
	return max_label


func _entropy(labels: Array) -> float:
	
	details["metrica_de_ganancia_de_info_1"] = "la entropía"
	details["metrica_de_ganancia_de_info_2"] = "entropía"
	
	if labels.is_empty():
		return 0.0
	
	var total = labels.size()
	var counts = {}
	
	for label in labels:
		if not counts.has(label):
			counts[label] = 0
		counts[label] += 1
	
	var entropy_val = 0.0
	for count in counts.values():
		var p = float(count) / float(total)
		if p > 0:
			entropy_val -= p * log(p) / log(2)
	
	return entropy_val


func _information_gains_for_all_atributes(attributes: Array, data) -> Dictionary[String, float]:
	var gains: Dictionary[String, float] = {}
	for attr in attributes:
		var gain = _information_gain(data, attr)
		gains[attr] = gain
		#details["ganancias_info"][attr] = gain
		#step_calculating_gain.emit(attr, gain)
	return gains
	

func _information_gain(data: Array, attribute: String) -> float:
	var labels = _get_labels(data)
	var total_entropy = _entropy(labels)
	var total_size = data.size()
	
	var subsets = {}
	for row in data:
		var value = row[attribute]
		if not subsets.has(value):
			subsets[value] = []
		subsets[value].append(row)
	
	var weighted_entropy = 0.0
	for subset in subsets.values():
		var weight = float(subset.size()) / float(total_size)
		var subset_labels = _get_labels(subset)
		weighted_entropy += weight * _entropy(subset_labels)
	
	return total_entropy - weighted_entropy


func _attribute_values_set_in_data(data, best_attr) -> Array:
	var values: Array = []
	for row in data:
		var value = row[best_attr]
		if not values.has(value):
			values.append(value)
	return values


func _get_remaining_attrs(attributes, best_attr) -> Array:
	var remaining_attrs = []
	for attr in attributes:
		if attr != best_attr:
			remaining_attrs.append(attr)
	return remaining_attrs


func update_pending_parent_ids(actual_node_id: int) -> void:
	# Replace all -2 placeholders in call stack with the actual node ID
	last_created_node_id = actual_node_id
	for context in call_stack:
		if context["parent_id"] == -2:
			context["parent_id"] = actual_node_id


func register_placeholder_node_ids(branch_to_id: Dictionary) -> void:
	# Called by the controller after pre-creating placeholder children.
	# Contexts still have parent_id == -2 at this point (called before update_pending_parent_ids).
	# Match each context to its pre-allocated node ID by branch_value.
	for context in call_stack:
		if context["parent_id"] == -2:
			var bv = context.get("branch_value", null)
			if branch_to_id.has(bv):
				context["node_id"] = branch_to_id[bv]



# ---------------- Evaluation ---------------- #


func _evaluate_dtree(dataset_to_evaluate: Array[Dictionary]) -> void:

	var array_of_evaldatas: Array[EvalData]
	for d in dataset_to_evaluate:
		array_of_evaldatas.append(EvalData.newone(d))

	var current_scene: Node = get_tree().current_scene
	current_scene.add_child(EvalDataContainer.newone(dtree_ref, array_of_evaldatas))


	#for n in dataset_to_evaluate.size():
	#	pass
	#pass
