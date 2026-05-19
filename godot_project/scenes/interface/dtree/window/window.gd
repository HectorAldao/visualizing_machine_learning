extends PanelContainer


@onready var vboxcontainer: VBoxContainer= $ScrollContainer/VBoxContainer
@onready var label0: Label = $ScrollContainer/VBoxContainer/Label0
@onready var label1: Label = $ScrollContainer/VBoxContainer/Label1
@onready var scroll_container: ScrollContainer = $ScrollContainer

# Scroll variables
@export var scroll_speed: int = 30
var is_middle_mouse_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO



const template_texts: Dictionary[String, Array] = {
	"internal" :
["Han bajado {numero_de_datos} datos por esta rama.
Estos {numero_de_datos} datos tenían las etiquetas {lista_etiquetas}.
En base a estas etiquetas se calcula la entropía de cada atributo de los datos.
Los datos tienen los atributos {lista_atributos}, por lo que hay que calcular {metrica_de_ganancia_de_info_1} para decidir cuál sirve para dividir los mejor.",
#{lista_ganancias}
"El que tiene mejor {metrica_de_ganancia_de_info_2} es '{mejor_atributo}' con {valor_metrica_mejor_atributo}.
Las ramas que se crean a partir de '{mejor_atributo}' son:
{lista_ramas_mejor_atributo}"],

	"internal_multi_atribute":
["Han bajado {numero_de_datos} datos por esta rama.
Estos {numero_de_datos} datos tenían las etiquetas {lista_etiquetas}.
En base a estas etiquetas se calcula la entropía de cada atributo de los datos.
Los datos tienen los atributos {lista_atributos}, por lo que hay que calcular {metrica_de_ganancia_de_info_1} para decidir cuál sirve para dividir los mejor.",
#{lista_ganancias}
"Hay {n_atributos_con_ganancia_maxima} atributos con mejor {metrica_de_ganancia_de_info_2}, con un valor de {valor_metrica_mejor_atributo}.
Por lo tanto se selecciona uno aleatoriamente y se prosigue, en este caso \"{mejor_atributo}\".
Las ramas que se crean a partir de '{mejor_atributo}' son:
{lista_ramas_mejor_atributo}"],

	"leaf":
["Ha bajado {numero_de_datos} datos por esta rama con la misma etiqueta.
Por lo tanto, para este conjunto de datos solo podemos asumir que los futuros datos que lleugen a esta rama tendrán la misma etiqueta: {lista_etiquetas}"],

	"leaf_mayority":
["Han bajado {numero_de_datos} datos por esta rama.
Pero no quedan atributos sin recorrer para estos datos, es decir, todos los atributos han sido valorados para clasificar los datos.
Por lo que solo queda ver qué etiquetas tienen los datos resultantes.",
"Si todos tienen la misma etiqueta, perfecto, había datos repetidos o muy similares entre los datos, pero todos estos los clasificamos igual.
Si hay varias etiquetas, pues los atributos escogidos no sirven para diferenciar a la perfección todos los casos de nuestro conjunto de datos. Pero hay que seleccioniar una etiqueta para este nodo hoja, por lo que se escoje la etiqueta mayoritaria.
En este caso '{etiqueta_mayoritaria}'."]
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_container.mouse_force_pass_scroll_events = false
	_ignore_mouse_input_for_window_content()


func update_current_text(details_dict: Dictionary) -> void:
	
	var plot_data: Dictionary[String, float]
	
	if typeof(details_dict["lista_ganancias"]) == TYPE_DICTIONARY:
		plot_data = details_dict["lista_ganancias"]
	
	_clean_lists(details_dict)
	
	var chart = vboxcontainer.get_node_or_null("BarsChart")
	if chart:
		vboxcontainer.remove_child(chart)
	
	var tipo_de_nodo: String = details_dict["tipo_de_nodo"]
	match tipo_de_nodo:
		"internal":
			label0.text = template_texts[tipo_de_nodo][0].format(details_dict)
			vboxcontainer.add_child(BarsChart.newone("Entropía por atributo", plot_data))
			call_deferred("_ignore_mouse_input_for_window_content")
			vboxcontainer.move_child(label1, -1)
			label1.text = template_texts[tipo_de_nodo][1].format(details_dict)
		"internal_multi_atribute":
			label0.text = template_texts[tipo_de_nodo][0].format(details_dict)
			vboxcontainer.add_child(BarsChart.newone("Entropía por atributo", plot_data))
			call_deferred("_ignore_mouse_input_for_window_content")
			vboxcontainer.move_child(label1, -1)
			label1.text = template_texts[tipo_de_nodo][1].format(details_dict)
		"leaf":
			label0.text = template_texts[tipo_de_nodo][0].format(details_dict)
			label1.text = ""
		"leaf_mayority":
			label0.text = template_texts[tipo_de_nodo][0].format(details_dict)
			label1.text = ""


## For each value on the input Dictionary that is an Array[String], it will
## change that Array for a string that concatenates each string element on
## it, adding commas and the corresponding conjunction among elements  
func _clean_lists(dict: Dictionary) -> void:
	for key in dict:
		var value = dict[key]
		var concatenation: String = ""
		
		if typeof(value) == TYPE_ARRAY:
			var cont: int = 0
			var size_arr: int = value.size()
			for i in value:
				cont += 1
				if typeof(i) == TYPE_STRING:
					if concatenation == "":  # If its the first
						concatenation = "\"" + i + "\""
					elif cont == size_arr:  # If its the last
						concatenation += ", y " + "\"" + i + "\""
					else:  # If is nor the first or the last
						concatenation += ", " + "\"" + i + "\""
			dict[key] = concatenation
						
		elif typeof(value) == TYPE_DICTIONARY:
			for key_v in value:  # If the value is a dict (as in "lista_ganancias"), change it to a string
				concatenation += str(key_v) + " = " + str(value[key_v]) + "\n"
			dict[key] = concatenation


func _ignore_mouse_input_for_window_content() -> void:
	_set_mouse_filter_recursive(scroll_container, Control.MOUSE_FILTER_IGNORE)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _set_mouse_filter_recursive(node: Node, filter: Control.MouseFilter) -> void:
	if node is Control:
		node.mouse_filter = filter

	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)


# How to move the ScrollContainer
func _gui_input(event: InputEvent) -> void:
	# Handle mouse motion for middle mouse dragging
	if event is InputEventMouseMotion and is_middle_mouse_dragging:
		# The scroll aplied is going to be the dif frame to frame of
		# where the mause where and where the mouse is
		var delta_position = event.position - last_mouse_position

		# The diff is aplied
		scroll_container.scroll_horizontal -= int(delta_position.x)
		scroll_container.scroll_vertical -= int(delta_position.y)

		# The new position is saved and the input is set as handled
		last_mouse_position = event.position
		accept_event()
	
	# If there is a mouse event
	if event is InputEventMouseButton:
		# Move the view with middle mouse
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_middle_mouse_dragging = true
				last_mouse_position = event.position
			else:
				is_middle_mouse_dragging = false

			accept_event()
		
		# Move scroll container view
		elif event.pressed and not event.ctrl_pressed:
			# Save the diference frame to frame
			var delta: int = 0
			
			# Determine direction
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				delta = -scroll_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				delta = scroll_speed
				
			# Apply scroll
			if delta != 0:
				# Check Shift for horizontal scrolling
				if event.shift_pressed:
					scroll_container.scroll_horizontal += delta
				else:
					scroll_container.scroll_vertical += delta
				
				# Optional: do not pass the input to lower nodes
				accept_event()
