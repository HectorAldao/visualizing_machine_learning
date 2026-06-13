class_name DTreeLogical
extends Control


@export_file("*.tscn") var dnode_scene: String  # "res://scenes/objects/dtree/dnode/dnode.tscn"


const V_SPACING: float = 150.0
const H_SPACING: float = 120.0


# Display related variables
var nodes_dict = {}
var root_id = null
var _current_inorder_index = 0


# ML related variables
var mode: String = "manual"  # Mode: "manual" or "automatic"


@onready var nodes_container : Control = $NodeContainer
@onready var edges_container : Control = $ConectionContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	nodes_container.mouse_filter = Control.MOUSE_FILTER_PASS
	edges_container.mouse_filter = Control.MOUSE_FILTER_IGNORE



func set_mode(p_mode: String) -> void:
	mode = p_mode
	
	if mode == "manual":
		_create_root()
		relayout_tree()


func _create_root() -> void:
	var dnode : DNode = load(dnode_scene).instantiate()
	dnode.id = 0
	dnode.depth = 0
	dnode.inorder_index = 0.0
	
	nodes_dict[0] = dnode
	nodes_container.add_child(dnode)

	root_id = 0


func relayout_tree() -> void:
	if root_id == null or nodes_dict.is_empty():
		_redraw_edges()
		return

	_current_inorder_index = 0
	_assign_inorder_indices(root_id)
	_apply_positions()
	_redraw_edges()


func update_canvas_size_and_center() -> void:
	var tree_rect: Rect2 = get_tree_bounds()
	
	# DTree is a direct child of ScrollContainer
	# The container overrides the child's position,
	# so we must NOT set position here.
	# Instead, we translate the nodes inside the DTree so the tree content
	# is centered within the canvas area.
	
	var scroll_container: ScrollContainer = null
	var parent = get_parent()
	if parent is ScrollContainer:
		scroll_container = parent
	
	var parent_size := scroll_container.size if scroll_container else Vector2.ZERO
	
	var final_size := Vector2(
		max(tree_rect.size.x, parent_size.x),
		max(tree_rect.size.y, parent_size.y)
	)
	
	# Calculate how much to shift all node positions so the tree is
	# centered within the final_size canvas.
	var canvas_center   := final_size * 0.5
	var tree_bbox_center := tree_rect.position + tree_rect.size * 0.5
	var offset          := canvas_center - tree_bbox_center
	
	for node in nodes_dict.values():
		node.position += offset
	
	# Set the minimum size of this Control so the ScrollContainer gets
	# the correct scrollable area.
	custom_minimum_size = final_size
	
	# Scroll must be deferred: ScrollContainer only updates its scrollbar
	# max_value after a layout pass, which is triggered by changing
	# custom_minimum_size. Setting scroll_horizontal/vertical immediately
	# would be clamped to the old (smaller) range.
	if scroll_container:
		var target_h := int(canvas_center.x - parent_size.x * 0.5)
		var target_v := int(canvas_center.y - parent_size.y * 0.5)
		scroll_container.set_deferred("scroll_horizontal", target_h)
		scroll_container.set_deferred("scroll_vertical", target_v)


func expand_canvas_to_include_rect(local_rect: Rect2, margin: float = Constants.DTREE_CANVAS_MARGIN) -> void:
	var required_size := Vector2(
		max(custom_minimum_size.x, local_rect.position.x + local_rect.size.x + margin),
		max(custom_minimum_size.y, local_rect.position.y + local_rect.size.y + margin)
	)

	if required_size != custom_minimum_size:
		custom_minimum_size = required_size


func _apply_positions() -> void:
	print("_apply_positions called")
	var min_x = INF
	var max_x = -INF

	for id in nodes_dict.keys():
		var dnode = nodes_dict[id]

		var x = dnode.inorder_index * H_SPACING
		var y = dnode.depth * V_SPACING
		dnode.position = Vector2(x, y)

		min_x = min(min_x, x)
		max_x = max(max_x, x)

	# centrar el árbol en torno al (0,0) o al centro de la pantalla
	var center_x = (min_x + max_x) * 0.5
	for dnode in nodes_dict.values():
		dnode.position.x -= center_x


func _assign_inorder_indices(id: int) -> void:
	if id == null:
		return

	var dnode = nodes_dict[id]

	# Si no tiene hijos, es una hoja: se le asigna el siguiente índice libre
	if dnode.sons_id.is_empty():
		dnode.inorder_index = float(_current_inorder_index)
		_current_inorder_index += 1
	else:
		# Primero procesamos todos los hijos
		var first_index := INF
		var last_index := -INF

		for child_id in dnode.sons_id:
			_assign_inorder_indices(child_id)
			var child_dnode = nodes_dict[child_id]
			first_index = min(first_index, child_dnode.inorder_index)
			last_index = max(last_index, child_dnode.inorder_index)

		# El padre se queda centrado respecto al rango de sus hijos
		dnode.inorder_index = (first_index + last_index) * 0.5


func _redraw_edges():
	edges_container.refresh_connections()


# Calculate dtree dimensions
func get_tree_bounds() -> Rect2:
	#if nodes_visual.is_empty():
	if nodes_dict.is_empty():
		return Rect2(Vector2.ZERO, Vector2.ZERO)

	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF

	#for visual in nodes_visual.values():
	for node in nodes_dict.values():
		var p: Vector2 = node.position
		min_x = min(min_x, p.x)
		min_y = min(min_y, p.y)
		max_x = max(max_x, p.x)
		max_y = max(max_y, p.y)

	var margin := Constants.DTREE_CANVAS_MARGIN  # margen alrededor del árbol
	var pos  := Vector2(min_x - margin, min_y - margin)
	var tree_size := Vector2(
		(max_x - min_x) + margin * 2.0,
		(max_y - min_y) + margin * 2.0
	)
	return Rect2(pos, tree_size)


func remove_subtree_and_self(node_id: int) -> void:
	if not nodes_dict.has(node_id):
		return

	var dnode: DNode = nodes_dict[node_id]

	var children_copy: Array[int] = dnode.sons_id.duplicate()
	for child_id in children_copy:
		remove_subtree_and_self(child_id)

	if dnode.parent_id != null and nodes_dict.has(dnode.parent_id):
		var parent_dnode: DNode = nodes_dict[dnode.parent_id]
		parent_dnode.sons_id.erase(node_id)

	nodes_dict.erase(node_id)

	if root_id == node_id:
		root_id = null

	dnode.queue_free()


func restore_node_as_pending(node_id: int) -> void:
	if not nodes_dict.has(node_id):
		return

	var dnode: DNode = nodes_dict[node_id]
	dnode.attribute = ""
	dnode.label = ""
	dnode.is_leaf = false
	dnode.is_pending = true
	dnode.information_variable_value = ""
	var parent_attribute: String = ""
	if dnode.parent_id != null and nodes_dict.has(dnode.parent_id):
		parent_attribute = str(nodes_dict[dnode.parent_id].attribute)
	dnode.partition_details = {
		"tipo_de_nodo": "pending",
		"valor_rama": dnode.branch_value,
		"atributo_rama": parent_attribute,
	}
	dnode.apply_theme_animated(dnode.pending_theme, "...")
