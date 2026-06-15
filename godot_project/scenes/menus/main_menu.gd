extends Control


# For the menu
@export var max_width: float = 700.0
@export var horizontal_margin: float = 0

@onready var dtree_button: Button = %DTreeButton
@onready var nn_button: Button = %NeuralNetworkButton
@onready var start_button: Button = %StartButton

@onready var title_label: Label = %TitleLabel
@onready var text_label: Label = %TextLabel
@onready var preview_of_algorithm: TextureRect = %PreviewOfAlgorithm

@onready var panelcontainer: PanelContainer = %PanelContainer
@onready var hbox_container: HBoxContainer = %TopHBoxContainer
@onready var vbox_container: VBoxContainer = %MainMenuVBoxContainer
@onready var panel_container_menu: PanelContainer = %PanelContainerMenu
@onready var select_algorithm_menu: VBoxContainer = %SelectAlgorithmVBoxContainerMenu


var selected_algorithm: int = 0:
	set(new_value):
		selected_algorithm = new_value
		_update_panel()

var preview_original_index: int = 0
var preview_original_parent: Container


func _ready() -> void:
	# Connect the press of the button to the load of the scene
	dtree_button.pressed.connect(_on_d_tree_button_pressed)
	nn_button.pressed.connect(_on_nn_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)

	start_button.disabled = true
	preview_original_parent = preview_of_algorithm.get_parent()
	preview_original_index = preview_of_algorithm.get_index()

	get_viewport().size_changed.connect(_update_size)
	_update_size()



func _on_d_tree_button_pressed() -> void:
	selected_algorithm = 1


func _on_nn_button_pressed() -> void:
	selected_algorithm = 2


func _on_start_button_pressed() -> void:
	match selected_algorithm:
		1:
			if _is_horizontal():
				get_tree().change_scene_to_file(Constants.SCENES.dtree_view_horizontal)
			else:
				get_tree().change_scene_to_file(Constants.SCENES.dtree_view)
		2:
			if _is_horizontal():
				get_tree().change_scene_to_file(Constants.SCENES.nn_view)
			else:
				get_tree().change_scene_to_file(Constants.SCENES.nn_view_vertical)
		_:
			# This shold not happen, because the button should be disabled
			# if there is no selected algorithm. But in case it happended
			start_button.disabled = true


func _update_panel() -> void:
	match selected_algorithm:
		1:
			start_button.disabled = false
			preview_of_algorithm.texture = load(Constants.SPRITES.dtree)
		2:
			start_button.disabled = false
			preview_of_algorithm.texture = load(Constants.SPRITES.nn)
		_:
			return

	_update_text(selected_algorithm)


func _update_text(algorithm: int) -> void:
	const dict_of_text: Dictionary[int, Array] = {
		1: ["Árbol de decisión",
			"El árbol de decisión es un modelo que clasifica los datos en base a sus características.

Durante el entranamiento, en los nodos del árbol se decide qué característica de los datos usar para dividirlos de la forma que más se separen.
Este criterio de división es conocido como 'ganancia de información', y se puede calcular con fórmulas como la entropía.
El particionamiento continúa en cada rama del árbol hasta que todos los ejemplos del nodo pertenecen a la misma clase o se han agotado las características a evaluar.

Durante el test, los datos descienden por las ramas que indican sus características hasta llegar a un nodo hoja, que determina la clasificación del árbol para ese dato."
			],
		2: ["Red neuronal",
			"Una red neuronal aproxima una función.

			Está formada por capas, que se conectan una detrás de otra. Estas capas contienen neuronas, que reciben como entrada las salidas de todas las neuronas de la capa anterior y devuelven un valor. Y cada neurona tiene unos números llamados 'pesos', y tiene tantos como neuronas haya en la capa anterior.

El entrenamiento de una red cuenta con dos fases. La primera es la de propagación hacia adelante. El dato de entranamiento pasa por la red. La salida de la capa final es la predicción de la red para ese dato. La segunda es la retropropagación. En base a cuánto falló la red se calcula cuánto modificar los pesos para que la proxima vez falle menos."
#La primera fase es la de propagación hacia adelante. Cada neurona calcula la multiplicación de sus entradas por los sus pesos, después los suma junto con un número (llamado bias), y al resultado lo pasa por una función (llamada función de activación).
#La segunda fase es la retropropagación. De la última capa sale un número por cada neurona en esa capa. Esos números son la predicción de la red. Esta predicción se compara con el valor real que tendría que dar una red neuronal perfecta. Esta comparación se hace con una función de error, que devuelve un número diciendo cuánto ha fallado la red. Con respecto a este error se pueden calcular las derivadas parciales de los pesos de las neuronas. Y con estas derivadas se puede calcular cuánto cambiar los pesos para que la red falle menos.
			]
		}
	
	title_label.text = dict_of_text[algorithm][0]
	text_label.text = dict_of_text[algorithm][1]


#func _update_size() -> void:
#
#	var viewport_size: Vector2 = get_viewport_rect().size
#	var available_width: float = viewport_size.x - horizontal_margin * 2.0
#	var available_height: float = viewport_size.y - horizontal_margin * 2.0
#	panelcontainer.custom_minimum_size.x = min(max_width, available_width)
#	panelcontainer.custom_minimum_size.y = available_height

func _update_size() -> void:
	var viewport: Viewport = get_viewport()
	var window_size: Vector2 = Vector2(get_window().size)
	var display_scale: float = DisplayServer.screen_get_scale()
	if display_scale <= 0.0:
		display_scale = 1.0

	var canvas_scale: Vector2 = viewport.get_stretch_transform().get_scale() / display_scale
	if canvas_scale.x <= 0.0 or canvas_scale.y <= 0.0:
		var visible_size: Vector2 = viewport.get_visible_rect().size
		canvas_scale = (window_size / display_scale) / visible_size

	#var visual_window_size: Vector2 = window_size / display_scale
	#var available_width: float = maxf(0.0, visual_window_size.x - horizontal_margin * 2.0)
	#var available_height: float = maxf(0.0, visual_window_size.y - horizontal_margin * 2.0)
	#var target_width: float = available_width if _is_horizontal() else min(max_width, available_width)
	#panelcontainer.custom_minimum_size.x = target_width / canvas_scale.x
	#panelcontainer.custom_minimum_size.y = available_height / canvas_scale.y
	_update_layout_orientation()


func _update_layout_orientation() -> void:
	var target_parent: Container = hbox_container if _is_horizontal() else vbox_container
	if panel_container_menu.get_parent() != target_parent:
		panel_container_menu.reparent(target_parent, false)
		panel_container_menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel_container_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_update_preview_orientation()


func _update_preview_orientation() -> void:
	var horizontal: bool = _is_horizontal()
	var target_parent: Container = select_algorithm_menu if horizontal else preview_original_parent
	if preview_of_algorithm.get_parent() != target_parent:
		preview_of_algorithm.reparent(target_parent, false)

	if horizontal:
		target_parent.move_child(preview_of_algorithm, target_parent.get_child_count() - 1)
	else:
		target_parent.move_child(preview_of_algorithm, mini(preview_original_index, target_parent.get_child_count() - 1))


## Check if the screen is in vertical or horizontal
func _is_horizontal() -> bool:
	var window_size: Vector2 = get_window().size
	return window_size.x >= window_size.y
