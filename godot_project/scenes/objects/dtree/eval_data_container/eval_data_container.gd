class_name EvalDataContainer extends Node2D


#var dtree: DTreeLogical
var data: Array[EvalData]
var nodes: Dictionary[int, Dictionary]  # keys() = "position", "attribute", "label", "branch"

const DROP_TWEEN_DURATION: float = 0.35


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
			"depth": dnode.depth,
			"attribute": dnode.attribute,
			"label": dnode.label,
			"branch": dnode.branch_value,
			"parent_id": dnode.parent_id
		}
	
	return evaldatacontainer


func _drop_one_data() -> void:

	# If all the data was droped, inform and do nothing
	if data.is_empty():
		SignalsObserver.all_data_droped.emit()
		return

	# Get a data do drop and add it to the scene as child
	var evaldata: EvalData = data.pop_front()
	add_child(evaldata)

	if evaldata == null:
		return
	if nodes.is_empty():
		return


	# Check if there is root
	var root_id: int = -1
	for node_id in nodes.keys():
		var node_info: Dictionary = nodes[node_id]
		if int(node_info.get("depth", 0)) == 0:
			root_id = int(node_id)
			break

	if root_id == -1:
		return

	# Explore the tree to determine the path
	var current_node_id: int = root_id
	while true:
		if not nodes.has(current_node_id):
			return

		var current_node: Dictionary = nodes[current_node_id]
		var current_position: Vector2 = current_node.get("position", evaldata.position)
		var tween := create_tween()
		tween.tween_property(evaldata, "position", current_position, DROP_TWEEN_DURATION) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_IN_OUT)
		await tween.finished

		var node_label: String = str(current_node.get("label", ""))
		if node_label != "":
			return

		var node_attribute: String = str(current_node.get("attribute", ""))
		if node_attribute == "" or not evaldata.data_dict.has(node_attribute):
			return

		var desired_branch_value = evaldata.data_dict[node_attribute]
		var next_node_id: int = -1

		for candidate_id in nodes.keys():
			var candidate_node: Dictionary = nodes[candidate_id]
			if int(candidate_node.get("parent_id", -1)) != current_node_id:
				continue
			if candidate_node.get("branch", null) == desired_branch_value:
				next_node_id = int(candidate_id)
				break

		if next_node_id == -1:
			return

		current_node_id = next_node_id
