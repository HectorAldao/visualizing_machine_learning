class_name DNode
extends Button

# Theme for the leafs and the noleafs
var leaf_theme: Theme    = preload(Constants.THEMES.leaf)
var noleaf_theme: Theme  = preload(Constants.THEMES.noleaf)
var pending_theme: Theme = preload(Constants.THEMES.nodedefault)
var resalted_theme: Theme = preload(Constants.THEMES.resalted_dnode)

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
var information_variable_value: String = ""
var partition_details: Dictionary = {}

# For the algorithmic mode
var was_created_by_algorithm: bool = false
var _is_clicked_selected: bool = false



# Signals
signal change_child_requested(type_of_change: String)
 


func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Fade in from transparent
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.75) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	_apply_theme()

	if not was_created_by_algorithm:
		gui_input.connect(_on_gui_input)
	
	pressed.connect(_on_pressed)
	SignalsObserver.dtree_clicked_node_changed.connect(_on_clicked_dnode_changed)
	SignalsObserver.dtree_eval_data_selected.connect(_reset_clicked_selection)
	SignalsObserver.dtree_eval_data_advanced.connect(_reset_clicked_selection)
	SignalsObserver.drop_data.connect(_reset_clicked_selection)
	SignalsObserver.clear_window.connect(_reset_clicked_selection)
	SignalsObserver.dtree_training_finished.connect(_reset_clicked_selection)
	_on_clicked_dnode_changed(Variables.dtree_clicked_node_id)


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


# Crossfade to a new theme: fade out → swap → fade in
func apply_theme_animated(new_theme: Theme, new_text: String = text) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): text = new_text; theme = resalted_theme if _is_clicked_selected else new_theme)
	tween.tween_property(self, "modulate:a", 1.0, 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_pressed() -> void:
	if _is_current_clicked_selection():
		Variables.dtree_clicked_node_id = -1
		SignalsObserver.dtree_clicked_node_changed.emit(-1)
	else:
		Variables.dtree_clicked_node_id = id
		SignalsObserver.dtree_clicked_node_changed.emit(id)

	var details := partition_details.duplicate(true)
	if details.is_empty():
		details = {
			"tipo_de_nodo": "pending" if is_pending else "leaf" if is_leaf else "internal",
			"numero_de_datos": 0,
			"lista_etiquetas": [label] if label else [],
			"lista_atributos": [attribute] if attribute else [],
			"pureza_nodo": "sin datos",
			"etiqueta_mayoritaria": label,
			"valor_rama": branch_value,
		}

	details["node_id"] = id
	details["branch_value"] = branch_value
	details["attribute"] = attribute
	details["label"] = label
	details["is_leaf"] = is_leaf
	details["is_pending"] = is_pending
	SignalsObserver.dtree_node_selected.emit(details)


func _on_clicked_dnode_changed(node_id: int) -> void:
	_is_clicked_selected = node_id == id
	_apply_theme()


func _reset_clicked_selection(_arg1 = null, _arg2 = null, _arg3 = null) -> void:
	if Variables.dtree_clicked_node_id == -1:
		return

	Variables.dtree_clicked_node_id = -1
	SignalsObserver.dtree_clicked_node_changed.emit(-1)


func _is_current_clicked_selection() -> bool:
	return Variables.dtree_clicked_node_id == id


func _apply_theme() -> void:
	var target_theme: Theme = _get_base_theme()
	if _is_clicked_selected:
		target_theme = resalted_theme

	if theme != target_theme:
		theme = target_theme


func _get_base_theme() -> Theme:
	if is_pending:
		return pending_theme
	if is_leaf:
		return leaf_theme
	return noleaf_theme
