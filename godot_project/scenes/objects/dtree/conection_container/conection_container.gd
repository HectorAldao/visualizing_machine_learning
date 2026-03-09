extends Control

# "parentId_childId" -> Conection node
# Tracks live connections so existing ones are never re-created (and thus never re-animated)
var _connections: Dictionary = {}

func refresh_connections() -> void:
	var dtree = get_parent() as DTreeLogical

	# Build the set of edges that should currently exist
	var desired: Dictionary = {}
	for ln in dtree.nodes_dict.values():
		for child_id in ln.sons_id:
			var key: String = str(ln.id) + "_" + str(child_id)
			desired[key] = [ln.id, child_id]

	# Remove connections whose edge no longer exists
	for key in _connections.keys():
		if not desired.has(key):
			_connections[key].free()
			_connections.erase(key)

	# Add connections for edges that are new
	for key in desired:
		if not _connections.has(key):
			var ids: Array = desired[key]
			_draw_edge(ids[0], ids[1], key)

func _draw_edge(parent_id: int, child_id: int, key: String) -> void:
	var tree = get_parent() as DTreeLogical
	var parent_node = tree.nodes_dict[parent_id]
	var child_node  = tree.nodes_dict[child_id]

	var conection: Conection = preload(Constants.SCENES.conection).instantiate()
	conection.from_node = parent_node
	conection.to_node   = child_node

	if child_node.branch_value != null:
		conection.text = str(child_node.branch_value)

	add_child(conection)
	_connections[key] = conection
