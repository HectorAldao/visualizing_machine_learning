extends Node2D
class_name DNode


var id
var parent_id
var sons_id: Array[int] = []
var depth = 0
var inorder_index: float = 0.0


var can_remove := true



@onready var area_2d := $Area2D
@onready var sprite := $Sprite2D

 

signal change_child_requested(type_of_change: String)



func _ready():
	area_2d.input_pickable = true
	area_2d.connect("mouse_entered", _on_mouse_entered)
	area_2d.connect("mouse_exited", _on_mouse_exited)
	area_2d.connect("input_event", _on_area_input_event)


func _on_mouse_entered():
	sprite.modulate = Color(0, 1, 0)


func _on_mouse_exited():
	sprite.modulate = Color(1, 1, 1)  # Returns to normal


func _on_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton \
	and (event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_LEFT) \
	and event.pressed:
		_open_context_menu(event.position)


func _open_context_menu(mouse_pos: Vector2) -> void:
	var menu := PopupMenu.new()
	add_child(menu)
	menu.add_item("Add Child", 0)
	if can_remove:
		menu.add_item("Remove Node", 1)

	menu.id_pressed.connect(_on_menu_id_pressed)

	menu.position = mouse_pos
	menu.popup()


func _on_menu_id_pressed(menu_id: int) -> void:
	if menu_id == 0:
		emit_signal("change_child_requested", "add")
	elif menu_id == 1:
		emit_signal("change_child_requested", "remove")
