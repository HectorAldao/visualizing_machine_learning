extends Control


func _ready():
	var dtree = preload("res://scenes/objects/dtree/dtree/dtree.tscn").instantiate()
	add_child(dtree)

	var controller = preload("res://scenes/views/dtree/controller_dtree/controller_dtree.tscn").instantiate()
	add_child(controller)
	controller.initialize(dtree, self)
	# self.custom_minimum_size = Vector2(ancho, alto)



func update_canvas_size_and_center() -> void:

	var arbol: Node2D = $Arbol
	var tree_rect: Rect2 = arbol.get_tree_bounds()
	
	var needed := tree_rect.size
	
	# Que nunca sea más pequeño que el área visible del ScrollContainer
	var final_size := Vector2(
		max(needed.x, size.x),
		max(needed.y, size.y)
	)
	
	custom_minimum_size = final_size
	
	# Centrar el árbol dentro del canvas
	var canvas_center := final_size * 0.5
	var tree_center := tree_rect.position + tree_rect.size * 0.5
	arbol.position = canvas_center - tree_center
