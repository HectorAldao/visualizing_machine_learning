extends Control


@export_file("*.tscn") var dtree_scene: String  # "scenes/objects/dtree/dtree/dtree.tscn" "scenes/objects/dtree/dtree/dtree.gd"


var dtree: DTreeLogical



func load_tree_with_mode(mode: String):
	# Load and add the tree scene
	dtree = load(dtree_scene).instantiate()
	add_child(dtree)
	
	# Set the mode on the tree
	dtree.set_mode(mode)



func update_canvas_size_and_center() -> void:

	#var arbol: Node2D = $DTree
	var tree_rect: Rect2 = dtree.get_tree_bounds()
	
	var needed := tree_rect.size
	
	# Never smaller than the visible area of the ScrollContainer
	var final_size := Vector2(
		max(needed.x, size.x),
		max(needed.y, size.y)
	)
	
	# Set the atribute of the node Control
	custom_minimum_size = final_size
	
	# Center the dtree inside the canvas
	var canvas_center := final_size * 0.5
	var tree_center := tree_rect.position + tree_rect.size * 0.5
	dtree.position = canvas_center - tree_center
