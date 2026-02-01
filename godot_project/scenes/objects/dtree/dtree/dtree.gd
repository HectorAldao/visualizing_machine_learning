extends Node2D
class_name DTreeLogical

# Take the allready instantiated containters
@onready var nodes_container : Node2D = $ContenedorNodos
@onready var edges_container : Node2D = $ContenedorConexiones

var nodes_dict = {}
var root_id = null

const V_SPACING := 150.0
const H_SPACING := 120.0



func _ready():
	_create_root()
	relayout_tree()


func _create_root():
	var dnode : DNode = preload("res://scenes/objects/dtree/dnode/dnode.tscn").instantiate()
	dnode.id = 0
	dnode.depth = 0
	dnode.inorder_index = 0.0
	
	nodes_dict[0] = dnode
	nodes_container.add_child(dnode)

	root_id = 0



func _apply_positions():
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

var _current_inorder_index = 0

func relayout_tree():
	if root_id == null:
		return

	_current_inorder_index = 0
	_assign_inorder_indices(root_id)
	_apply_positions()
	_redraw_edges()

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
	edges_container.queue_redraw()


# Calcular las dimensiones del arbol
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

	var margin := 100.0  # margen alrededor del árbol
	var pos  := Vector2(min_x - margin, min_y - margin)
	var size := Vector2(
		(max_x - min_x) + margin * 2.0,
		(max_y - min_y) + margin * 2.0
	)
	return Rect2(pos, size)
