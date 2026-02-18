class_name DNode
extends Button


# Logic related variables
var id: int
var parent_id: int
var sons_id: Array[int] = []
var depth: int = 0
var inorder_index: float = 0.0

var can_remove := true  # For the root node


# ML related variables
var attribute: String = ""  # Attribute to split on (if not leaf)
var label: String = ""      # Class label (if leaf)
var is_leaf: bool = false   # Whether this is a leaf node
var branch_value = null     # The value this node represents from parent's split



# Signals
signal change_child_requested(type_of_change: String)
 


func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	connect("gui_input", _on_gui_input)


func _on_gui_input(event: InputEvent):
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

	var global_mouse_pos = get_screen_position() + mouse_pos
	menu.position = global_mouse_pos
	menu.popup()


func _on_menu_id_pressed(menu_id: int) -> void:
	if menu_id == 0:
		emit_signal("change_child_requested", "add")
	elif menu_id == 1:
		emit_signal("change_child_requested", "remove")
