extends PanelContainer

const TREE_FILE_PATH: String = "user://tree.json"

@export var algorithm_name: String = ""

@onready var load_button: Button = %LoadButton
@onready var save_button: Button = %SaveButton
@onready var home_button: Button = %HomeButton


func _ready() -> void:
	
	# Update the text depending on the algorithm
	load_button.text = load_button.text + algorithm_name
	save_button.text = save_button.text + algorithm_name

	%MainMenuButton.pressed.connect(func(): visible = not visible)
	
	# Connect buttons
	home_button.pressed.connect(_go_home)
	load_button.pressed.connect(_on_load_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)

	if _is_nn_algorithm():
		load_button.visible = false


func _is_nn_algorithm() -> bool:
	return algorithm_name.to_lower() == "red"


func _on_load_button_pressed() -> void:
	if _is_nn_algorithm():
		return

	_load_tree(TREE_FILE_PATH)


func _on_save_button_pressed() -> void:
	if _is_nn_algorithm():
		_show_network_export_panel()
		return

	_save_tree(TREE_FILE_PATH)


func _show_network_export_panel() -> void:
	var panel_export_format := get_node_or_null("%PanelExportFormat") as PanelContainer
	if panel_export_format == null:
		push_error("PanelExportFormat was not found in the current view.")
		return

	panel_export_format.visible = true


func _save_tree(file_path: String) -> void:
	var dtree := _get_current_dtree()
	if dtree == null:
		return

	var json_string := JSON.stringify(_tree_to_json_data(dtree), "\t")
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("It was not possible to open the file to write: %s" % file_path)
		return

	file.store_string(json_string)
	file.close()
	print("Tree saved")


func _load_tree(file_path: String) -> void:
	var json_content := _load_json_content(file_path)
	if json_content.is_empty():
		return

	var json := JSON.new()
	var error := json.parse(json_content)
	if error != OK:
		push_error("Could not parse %s: %s at line %d" % [file_path, json.get_error_message(), json.get_error_line()])
		return

	if not (json.data is Dictionary):
		push_error("Tree json must contain a dictionary.")
		return

	var tree_data := _normalize_tree_data(json.data)
	if tree_data.is_empty():
		return

	var dtree := _get_current_dtree()
	if dtree == null:
		return

	_clear_tree(dtree)
	dtree.mode = str(tree_data.get("mode", dtree.mode))

	var nodes_data: Dictionary = tree_data["nodes"]
	for node_key in nodes_data.keys():
		var raw_node_data = nodes_data[node_key]
		if not (raw_node_data is Dictionary):
			continue

		var fallback_id := int(str(node_key)) if str(node_key).is_valid_int() else 0
		var dnode := _create_dnode_from_data(raw_node_data, fallback_id, dtree.mode)
		if dtree.nodes_dict.has(dnode.id):
			dnode.queue_free()
			continue

		dtree.nodes_dict[dnode.id] = dnode
		dtree.nodes_container.add_child(dnode)

	dtree.root_id = _resolve_root_id(dtree, tree_data.get("root_id", null))
	_update_node_remove_flags(dtree)
	_update_controller_after_load(dtree)
	dtree.relayout_tree()
	dtree.update_canvas_size_and_center()
	print("Tree loaded")


func _load_json_content(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("It was not possible to open the file to read: %s" % file_path)
		return ""

	var content := file.get_as_text()
	file.close()
	return content


func _get_current_dtree() -> DTreeLogical:
	var dtree := get_node_or_null("%DTree") as DTreeLogical
	if dtree == null:
		push_error("DTree was not found in the current view.")

	return dtree


func _tree_to_json_data(dtree: DTreeLogical) -> Dictionary:
	var nodes_data: Dictionary = {}
	for node_id in dtree.nodes_dict.keys():
		var dnode: DNode = dtree.nodes_dict[node_id]
		nodes_data[str(node_id)] = _dnode_to_json_data(dnode)

	return {
		"root_id": dtree.root_id,
		"mode": dtree.mode,
		"nodes": nodes_data,
	}


func _dnode_to_json_data(dnode: DNode) -> Dictionary:
	return {
		"id": dnode.id,
		"parent_id": dnode.parent_id,
		"sons_id": dnode.sons_id,
		"depth": dnode.depth,
		"inorder_index": dnode.inorder_index,
		"text": dnode.text,
		"can_remove": dnode.can_remove,
		"is_pending": dnode.is_pending,
		"attribute": dnode.attribute,
		"label": dnode.label,
		"is_leaf": dnode.is_leaf,
		"branch_value": dnode.branch_value,
		"information_variable_value": dnode.information_variable_value,
		"partition_details": dnode.partition_details.duplicate(true),
		"was_created_by_algorithm": dnode.was_created_by_algorithm,
	}


func _normalize_tree_data(raw_tree_data: Dictionary) -> Dictionary:
	if raw_tree_data.has("nodes"):
		var nodes = raw_tree_data["nodes"]
		if not (nodes is Dictionary):
			push_error("Tree json field 'nodes' must be a dictionary.")
			return {}

		return raw_tree_data

	# Old tree.json files stored the nodes dictionary directly.
	return {
		"root_id": 0,
		"nodes": raw_tree_data,
	}


func _create_dnode_from_data(node_data: Dictionary, fallback_id: int, tree_mode: String) -> DNode:
	var dnode: DNode = load(Constants.SCENES.dnode).instantiate()
	dnode.id = int(node_data.get("id", fallback_id))
	dnode.parent_id = int(node_data.get("parent_id", 0))
	dnode.sons_id = _to_int_array(node_data.get("sons_id", []))
	dnode.depth = int(node_data.get("depth", 0))
	dnode.inorder_index = float(node_data.get("inorder_index", 0.0))
	dnode.can_remove = bool(node_data.get("can_remove", true))
	dnode.is_pending = bool(node_data.get("is_pending", false))
	dnode.attribute = _variant_to_string(node_data.get("attribute", ""))
	dnode.label = _variant_to_string(node_data.get("label", ""))
	dnode.is_leaf = bool(node_data.get("is_leaf", false))
	dnode.branch_value = node_data.get("branch_value", null)
	dnode.information_variable_value = _variant_to_string(node_data.get("information_variable_value", ""))
	dnode.partition_details = _to_dictionary(node_data.get("partition_details", {}))
	dnode.was_created_by_algorithm = bool(node_data.get("was_created_by_algorithm", tree_mode != "manual"))
	dnode.text = _variant_to_string(node_data.get("text", _get_dnode_fallback_text(dnode)))

	if dnode.text.is_empty():
		dnode.text = _get_dnode_fallback_text(dnode)

	return dnode


func _clear_tree(dtree: DTreeLogical) -> void:
	for child in dtree.nodes_container.get_children():
		child.queue_free()
	for child in dtree.edges_container.get_children():
		child.queue_free()

	var existing_connections = dtree.edges_container.get("_connections")
	if existing_connections is Dictionary:
		existing_connections.clear()

	dtree.nodes_dict.clear()
	dtree.root_id = null


func _resolve_root_id(dtree: DTreeLogical, raw_root_id: Variant) -> Variant:
	if raw_root_id != null and dtree.nodes_dict.has(int(raw_root_id)):
		return int(raw_root_id)

	if dtree.nodes_dict.has(0):
		return 0

	if dtree.nodes_dict.is_empty():
		return null

	var node_ids := dtree.nodes_dict.keys()
	node_ids.sort()
	return node_ids[0]


func _update_node_remove_flags(dtree: DTreeLogical) -> void:
	for node_id in dtree.nodes_dict.keys():
		var dnode: DNode = dtree.nodes_dict[node_id]
		dnode.can_remove = node_id != dtree.root_id


func _update_controller_after_load(dtree: DTreeLogical) -> void:
	var controller := get_node_or_null("%ControllerDTree") as ControllerDTree
	if controller == null:
		return

	controller.dtree = dtree
	controller.next_node_id = _get_next_node_id(dtree)
	if controller.mode == "manual":
		controller._connect_all_node_signals()


func _get_next_node_id(dtree: DTreeLogical) -> int:
	var next_id := 0
	for node_id in dtree.nodes_dict.keys():
		next_id = max(next_id, int(node_id) + 1)

	return next_id


func _get_dnode_fallback_text(dnode: DNode) -> String:
	if dnode.is_pending:
		return "..."
	if dnode.is_leaf and not dnode.label.is_empty():
		return dnode.label
	if not dnode.attribute.is_empty():
		return dnode.attribute
	if not dnode.label.is_empty():
		return dnode.label

	return str(dnode.id)


func _to_int_array(raw_value: Variant) -> Array[int]:
	var result: Array[int] = []
	if not (raw_value is Array):
		return result

	for value in raw_value:
		result.append(int(value))

	return result


func _to_dictionary(raw_value: Variant) -> Dictionary:
	if raw_value is Dictionary:
		return raw_value.duplicate(true)

	return {}


func _variant_to_string(raw_value: Variant) -> String:
	if raw_value == null:
		return ""

	return str(raw_value)


## Returns to home menu
func _go_home() -> void:
	get_tree().change_scene_to_file(Constants.SCENES.main_menu)
