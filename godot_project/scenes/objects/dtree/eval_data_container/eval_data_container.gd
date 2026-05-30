class_name EvalDataContainer extends Control


#var dtree: DTreeLogical
var data: Array[EvalData]
var nodes: Dictionary[int, Dictionary]  # keys() = "position", "size", "attribute", "label", "branch", "data_count"
var active_evaldata: EvalData = null
var active_node_id: int = -1
var evaldata_tweens: Dictionary = {}
var evaldata_move_queues: Dictionary = {}

const DROP_TWEEN_DURATION: float = 0.35
const LEAF_DATA_MARGIN: float = 12.0
const LEAF_DATA_SPACING: float = 28.0


#func _init(new_dtree: DTreeLogical = null, new_data: Array[EvalData] = []) -> void:
#	data = new_data
#	if new_dtree == null:
#		return
#	
#	var dtree_nodes: Dictionary = new_dtree.nodes_dict
#	for n in dtree_nodes:
#		var dnode: DNode = dtree_nodes[n]
#		nodes[n] = {
#			"position": dnode.position,
#			"depth": dnode.depth,
#			"attribute": dnode.attribute,
#			"label": dnode.label,
#			"branch": dnode.branch_value,
#			"parent_id": dnode.parent_id
#		}

func _ready() -> void:
	SignalsObserver.drop_data.connect(_drop_one_data)


static func newone(new_dtree: DTreeLogical, new_data: Array[EvalData]) -> EvalDataContainer:
	
	var evaldatacontainer: EvalDataContainer = preload(Constants.SCENES.eval_data_container).instantiate()
	#evaldatacontainer.dtree = new_dtree
	evaldatacontainer.data = new_data
	
	var dtree_nodes: Dictionary = new_dtree.nodes_dict
	for n in dtree_nodes:
		var dnode: DNode = dtree_nodes[n]
		evaldatacontainer.nodes[n] = {
			"position": dnode.position,
			"size": dnode.size,
			"depth": dnode.depth,
			"attribute": dnode.attribute,
			"label": dnode.label,
			"branch": dnode.branch_value,
			"parent_id": dnode.parent_id,
			"data_count": 0
		}
	
	return evaldatacontainer


func _drop_one_data() -> void:

	if nodes.is_empty():
		return

	if active_evaldata == null:
		_start_next_evaldata()
		return

	var next_node_id: int = _get_next_node_id(active_node_id, active_evaldata)
	if next_node_id == -1:
		_clear_active_evaldata()
		_start_next_evaldata()
		return

	active_node_id = next_node_id
	_queue_evaldata_move_to_node(active_evaldata, active_node_id)
	_clear_active_evaldata_if_path_ended()


func _start_next_evaldata() -> void:
	# If all the data was droped, inform and do nothing
	if data.is_empty():
		SignalsObserver.all_data_droped.emit()
		return

	var root_id: int = _get_root_id()
	if root_id == -1:
		return

	# Get a data do drop and add it to the scene as child
	active_evaldata = data.pop_front()
	if active_evaldata == null:
		return

	add_child(active_evaldata)
	active_evaldata.reset_size()
	active_node_id = root_id
	_queue_evaldata_move_to_node(active_evaldata, active_node_id)
	_clear_active_evaldata_if_path_ended()


func _get_root_id() -> int:
	for node_id in nodes.keys():
		var node_info: Dictionary = nodes[node_id]
		if int(node_info.get("depth", 0)) == 0:
			return int(node_id)
	return -1


func _queue_evaldata_move_to_node(evaldata: EvalData, node_id: int) -> void:
	if evaldata == null or not nodes.has(node_id):
		return

	var current_node: Dictionary = nodes[node_id]
	var data_count: int = int(current_node.get("data_count", 0))
	var current_center: Vector2 = _get_evaldata_target_center(current_node, _get_evaldata_center(evaldata), data_count)
	var current_position: Vector2 = _get_evaldata_position_from_center(evaldata, current_center)
	current_node["data_count"] = data_count + 1
	var move_queue: Array = evaldata_move_queues.get(evaldata, [])
	move_queue.append(current_position)
	evaldata_move_queues[evaldata] = move_queue
	_play_next_queued_evaldata_move(evaldata)


func _play_next_queued_evaldata_move(evaldata: EvalData) -> void:
	if evaldata == null:
		return

	if evaldata_tweens.has(evaldata):
		var active_tween: Tween = evaldata_tweens[evaldata]
		if active_tween != null and active_tween.is_valid() and active_tween.is_running():
			return

	var move_queue: Array = evaldata_move_queues.get(evaldata, [])
	if move_queue.is_empty():
		evaldata_tweens.erase(evaldata)
		evaldata_move_queues.erase(evaldata)
		return

	var next_position: Vector2 = move_queue.pop_front()
	evaldata_move_queues[evaldata] = move_queue
	var tween: Tween = create_tween().bind_node(self)
	evaldata_tweens[evaldata] = tween
	tween.tween_property(evaldata, "position", next_position, DROP_TWEEN_DURATION) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_expand_scroll_to_include_evaldata.bind(evaldata))
	tween.finished.connect(_on_evaldata_tween_finished.bind(evaldata))


func _on_evaldata_tween_finished(evaldata: EvalData) -> void:
	evaldata_tweens.erase(evaldata)
	_play_next_queued_evaldata_move(evaldata)


func _get_next_node_id(current_node_id: int, evaldata: EvalData) -> int:
	if evaldata == null or not nodes.has(current_node_id):
		return -1

	var current_node: Dictionary = nodes[current_node_id]
	var node_label: String = str(current_node.get("label", ""))
	if node_label != "":
		return -1

	var node_attribute: String = str(current_node.get("attribute", ""))
	if node_attribute == "" or not evaldata.data_dict.has(node_attribute):
		return -1

	var desired_branch_value = evaldata.data_dict[node_attribute]
	for candidate_id in nodes.keys():
		var candidate_node: Dictionary = nodes[candidate_id]
		if int(candidate_node.get("parent_id", -1)) != current_node_id:
			continue
		if candidate_node.get("branch", null) == desired_branch_value:
			return int(candidate_id)

	return -1


func _clear_active_evaldata_if_path_ended() -> void:
	if _get_next_node_id(active_node_id, active_evaldata) == -1:
		_clear_active_evaldata()


func _clear_active_evaldata() -> void:
	active_evaldata = null
	active_node_id = -1


func _get_evaldata_target_center(node_info: Dictionary, fallback_center: Vector2, stack_index: int) -> Vector2:
	var node_position: Vector2 = node_info.get("position", fallback_center)
	var node_label: String = str(node_info.get("label", ""))
	if node_label == "":
		return node_position

	var node_size: Vector2 = node_info.get("size", Vector2.ZERO)
	return node_position + Vector2(node_size.x * 0.5, node_size.y + LEAF_DATA_MARGIN + stack_index * LEAF_DATA_SPACING)


func _get_evaldata_center(evaldata: EvalData) -> Vector2:
	return evaldata.position + evaldata.size * 0.5


func _get_evaldata_position_from_center(evaldata: EvalData, center: Vector2) -> Vector2:
	return center - evaldata.size * 0.5


func _expand_scroll_to_include_evaldata(evaldata: EvalData) -> void:
	var dtree := _get_dtree()
	if dtree == null or not dtree.has_method("expand_canvas_to_include_rect"):
		return

	dtree.expand_canvas_to_include_rect(Rect2(evaldata.position, evaldata.size))


func _get_dtree() -> DTreeLogical:
	var current := get_parent()
	while current != null:
		if current is DTreeLogical:
			return current
		current = current.get_parent()
	return null
