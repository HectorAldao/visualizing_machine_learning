class_name DNode
extends Button

# Theme for the leafs and the noleafs
var leaf_theme: Theme    = preload(Constants.THEMES.leaf)
var noleaf_theme: Theme  = preload(Constants.THEMES.noleaf)
var pending_theme: Theme = preload(Constants.THEMES.nodedefault)

# Logic related variables
var id: int
var parent_id: int
var sons_id: Array[int] = []
var depth: int = 0
var inorder_index: float = 0.0

var can_remove := true  # For the root node

# Whether the node has not yet been decided as leaf/internal (placeholder state)
var is_pending: bool = false


# ML related variables
var attribute: String = ""  # Attribute to split on (if not leaf)
var label: String = ""      # Class label (if leaf)
var is_leaf: bool = false   # Whether this is a leaf node
var branch_value = null     # The value this node represents from parent's split

# For the algorithmic mode
var was_created_by_algorithm: bool = false



# Signals
signal change_child_requested(type_of_change: String)
 


func _ready():
	# Fade in from transparent
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.75) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	if is_pending:
		theme = pending_theme
	elif is_leaf:
		theme = leaf_theme
	else:
		theme = noleaf_theme

	if not was_created_by_algorithm:
		mouse_filter = Control.MOUSE_FILTER_PASS
		gui_input.connect(_on_gui_input)


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
		change_child_requested.emit("add")
	elif menu_id == 1:
		change_child_requested.emit("remove")
