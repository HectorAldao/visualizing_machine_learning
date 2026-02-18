extends Node
class_name AlgorithmDTree


# Signals for algorithm steps
signal step_start(step_type: String, step_data: Dictionary)
signal step_calculating_entropy(data_size: int, labels: Array)
signal step_calculating_gain(attribute: String, gain: float)
signal step_best_attribute_selected(attribute: String, gain: float)
signal step_creating_node(node_type: String, attribute: String, label: String)
signal step_creating_branch(parent_attr: String, branch_value, is_leaf: bool)
signal step_all_same_class(label: String)
signal step_no_attributes_left(majority_label: String)
signal algorithm_completed()

# Signal to request node/edge creation (same as manual mode)
signal add_node_requested(parent_id: int, branch_value, attribute: String, label: String, is_leaf: bool)


# Algorithm state
var is_running: bool = false
var is_paused: bool = true
var current_step: int = 0

# Training data
var training_data: Array = []
var available_attributes: Array[String] = []

# Tree reference (passed from dtree.gd)
var tree_ref = null

# Call stack for step-by-step execution
var call_stack: Array = []

# Track parent node IDs for each context
var pending_parent_id: int = -1
var last_created_node_id: int = -1


func start_training(data: Array[Dictionary], attributes: Array[String], tree) -> void:
	training_data = data
	available_attributes = attributes.duplicate()
	tree_ref = tree
	is_running = true
	is_paused = true
	current_step = 0
	call_stack.clear()
	pending_parent_id = -1
	last_created_node_id = -1
	
	# Initialize the root node building process
	var root_context = {
		"data": data,
		"attributes": attributes.duplicate(),
		"parent_id": -1,  # No parent for root
		"branch_value": null,
		"depth": 0,
		"node_id": -1  # Will be assigned when created
	}
	call_stack.append(root_context)
	
	emit_signal("step_start", "training_started", {
		"data_size": data.size(),
		"attributes": attributes
	})


func next_step() -> void:
	if not is_running or call_stack.is_empty():
		emit_signal("algorithm_completed")
		is_running = false
		return
	
	is_paused = false
	_process_next_step()
	is_paused = true


func _process_next_step() -> void:
	if call_stack.is_empty():
		emit_signal("algorithm_completed")
		is_running = false
		return
	
	var context = call_stack.pop_back()
	_build_node_step(context)


func _build_node_step(context: Dictionary) -> void:
	var data: Array = context["data"]
	var attributes: Array = context["attributes"]
	var parent_id: int = context["parent_id"]
	var branch_value = context.get("branch_value", null)
	var depth: int = context["depth"]
	
	var labels = _get_labels(data)
	
	emit_signal("step_calculating_entropy", data.size(), labels)
	
	# Check if all samples belong to the same class
	var unique_labels = []
	for label in labels:
		if not unique_labels.has(label):
			unique_labels.append(label)
	
	if unique_labels.size() == 1:
		# Leaf node - all same class
		var label = labels[0]
		emit_signal("step_all_same_class", label)
		emit_signal("step_creating_node", "leaf", "", label)
		
		# Request node creation
		emit_signal("add_node_requested", parent_id, branch_value, "", label, true)
		return
	
	# Check if no attributes left
	if attributes.is_empty():
		# Leaf node - majority class
		var majority = _majority_class(labels)
		emit_signal("step_no_attributes_left", majority)
		emit_signal("step_creating_node", "leaf_majority", "", majority)
		
		emit_signal("add_node_requested", parent_id, branch_value, "", majority, true)
		return
	
	# Calculate information gain for all attributes
	var gains = {}
	for attr in attributes:
		var gain = _information_gain(data, attr)
		gains[attr] = gain
		emit_signal("step_calculating_gain", attr, gain)
	
	# Select best attribute
	var best_attr = ""
	var best_gain = -INF
	for attr in gains:
		if gains[attr] > best_gain:
			best_gain = gains[attr]
			best_attr = attr
	
	emit_signal("step_best_attribute_selected", best_attr, best_gain)
	emit_signal("step_creating_node", "internal", best_attr, "")
	
	# Create branches for each attribute value
	var values = []
	for row in data:
		var value = row[best_attr]
		if not values.has(value):
			values.append(value)
	
	# Add child contexts to call stack (in reverse order so they process in correct order)
	var remaining_attrs = []
	for attr in attributes:
		if attr != best_attr:
			remaining_attrs.append(attr)
	
	for i in range(values.size() - 1, -1, -1):
		var value = values[i]
		var subset = []
		for row in data:
			if row[best_attr] == value:
				subset.append(row)
		
		emit_signal("step_creating_branch", best_attr, value, subset.is_empty())
		
		if subset.is_empty():
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
				"data": subset,
				"attributes": remaining_attrs.duplicate(),
				"parent_id": -2,
				"branch_value": value,
				"depth": depth + 1
			}
			call_stack.append(child_context)
	
	# Create internal node AFTER adding children to stack
	# This ensures children are in the call stack when update_pending_parent_ids is called
	emit_signal("add_node_requested", parent_id, branch_value, best_attr, "", false)


# Helper functions

func _get_labels(data: Array) -> Array:
	var labels = []
	for row in data:
		labels.append(row["class"])
	return labels


func _majority_class(labels: Array) -> String:
	var counts = {}
	for label in labels:
		if not counts.has(label):
			counts[label] = 0
		counts[label] += 1
	
	var max_label = ""
	var max_count = 0
	for label in counts:
		if counts[label] > max_count:
			max_count = counts[label]
			max_label = label
	
	return max_label


func _entropy(labels: Array) -> float:
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


func update_pending_parent_ids(actual_node_id: int) -> void:
	# Replace all -2 placeholders in call stack with the actual node ID
	last_created_node_id = actual_node_id
	for context in call_stack:
		if context["parent_id"] == -2:
			context["parent_id"] = actual_node_id
