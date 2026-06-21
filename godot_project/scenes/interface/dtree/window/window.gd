extends PanelContainer

@export var font_size: int = 20

@onready var vboxcontainer: VBoxContainer= $ScrollContainerV2/VBoxContainer
@onready var label0: Label = $ScrollContainerV2/VBoxContainer/Label0
@onready var latexformula: LatexFormula = $ScrollContainerV2/VBoxContainer/LatexFormula
@onready var label1: Label = $ScrollContainerV2/VBoxContainer/Label1
@onready var scroll_container: ScrollContainer = $ScrollContainerV2

# Scroll variables
@export var scroll_speed: int = 30
var is_middle_mouse_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO
var current_evaldata_instance_id: int = -1
var current_evaldata_text: String = ""
var current_chart_title: String = ""
var current_chart_data: Dictionary[String, float] = {}


const ENTROPY_FORMULA: String = "\\begin{aligned}&H(S) : \\text{entropía del atributo } S\\\\&c : \\text{número de etiquetas distintas}\\\\&p_i : \\text{proporción de datos con la etiqueta } i\\\\&H(S) = -\\sum_{i=1}^{c} p_i\\log_2(p_i)\\end{aligned}"

const ZERO_ENTROPY_EXPLANATION: String = "\n\n{texto_atributos} {verbo_entropia} entropía 0 porque, con los datos que llegan a este nodo, dividir por {texto_referencia} no reduce la incertidumbre sobre la etiqueta: las proporciones de etiquetas quedan igual o no aportan una separación útil. Por eso su valor es 0 y no ayuda a decidir mejor la clasificación."
const TRAINING_FINISHED_TEXT: String = "Entrenamiento finalizado, continúe con la evaluación pulsando 'Evaluar'."



const template_texts: Dictionary[String, Array] = {
	"internal" :
["Han bajado {numero_de_datos} datos por esta rama.
Estos {numero_de_datos} datos tenían las etiquetas {lista_etiquetas}.
La entropía se calcula como:
Los datos tienen los atributos {lista_atributos}, por lo que hay que calcular {metrica_de_ganancia_de_info_1} para decidir cuál sirve para dividirlos mejor.",
#{lista_ganancias}
"El que tiene mejor {metrica_de_ganancia_de_info_2} es '{mejor_atributo}' con {valor_metrica_mejor_atributo}.
Las ramas que se crean a partir de '{mejor_atributo}' son:
{lista_ramas_mejor_atributo}"],

	"internal_multi_atribute":
["Han bajado {numero_de_datos} datos por esta rama.
Estos {numero_de_datos} datos tenían las etiquetas {lista_etiquetas}.
La entropía se calcula como:
Los datos tienen los atributos {lista_atributos}, por lo que hay que calcular {metrica_de_ganancia_de_info_1} para decidir cuál sirve para dividirlos mejor.",
#{lista_ganancias}
"Hay {n_atributos_con_ganancia_maxima} atributos con mejor {metrica_de_ganancia_de_info_2}, con un valor de {valor_metrica_mejor_atributo}.
Por lo tanto se selecciona uno aleatoriamente y se prosigue, en este caso \"{mejor_atributo}\".
Las ramas que se crean a partir de '{mejor_atributo}' son:
{lista_ramas_mejor_atributo}"],

	"leaf":
["Ha bajado {numero_de_datos} datos por esta rama con la misma etiqueta.
Por lo tanto, para este conjunto de datos solo podemos asumir que los futuros datos que lleguen a esta rama tendrán la misma etiqueta: {lista_etiquetas}"],

	"leaf_mayority":
	["Han bajado {numero_de_datos} datos por esta rama.
Pero no quedan atributos sin recorrer para estos datos, es decir, todos los atributos han sido valorados para clasificar los datos.
Por lo que solo queda ver qué etiquetas tienen los datos resultantes.",
"Si todos tienen la misma etiqueta, perfecto, había datos repetidos o muy similares entre los datos, pero todos estos los clasificamos igual.
Si hay varias etiquetas, pues los atributos escogidos no sirven para diferenciar a la perfección todos los casos de nuestro conjunto de datos. Pero hay que seleccionar una etiqueta para este nodo hoja, por lo que se escoge la etiqueta mayoritaria.
En este caso '{etiqueta_mayoritaria}'."],

	"leaf_majority":
	["Han bajado {numero_de_datos} datos por esta rama.
Pero no quedan atributos sin recorrer para estos datos, es decir, todos los atributos han sido valorados para clasificar los datos.
Por lo que solo queda ver qué etiquetas tienen los datos resultantes.",
"Si todos tienen la misma etiqueta, perfecto, había datos repetidos o muy similares entre los datos, pero todos estos los clasificamos igual.
Si hay varias etiquetas, pues los atributos escogidos no sirven para diferenciar a la perfección todos los casos de nuestro conjunto de datos. Pero hay que seleccionar una etiqueta para este nodo hoja, por lo que se escoge la etiqueta mayoritaria.
En este caso '{etiqueta_mayoritaria}'."],

	"node_partition":
	["Este nodo es un nodo {tipo_visual_de_nodo}.
Por este camino han bajado {numero_de_datos} datos{texto_rama}.
La pureza de este nodo es {pureza_nodo}: {numero_etiqueta_mayoritaria} de {numero_de_datos} datos tienen la etiqueta mayoritaria '{etiqueta_mayoritaria}'.
Las etiquetas que llegan a este nodo son {lista_etiquetas}.",
"{texto_decision_nodo}"],

	"node_pending":
	["Este nodo es un nodo pendiente.",
"{texto_decision_nodo}"],

	"eval_data":
	["La etiqueta real es '{etiqueta}'.",
"Sus características son:
{caracteristicas}"],

	"eval_data_current":
	["El dato siendo evaluado tiene la etiqueta '{etiqueta}', y sus atributos son:
{caracteristicas}"],

	"eval_node_root":
	["El dato entra por el nodo raíz.
Este nodo divide usando el atributo '{atributo_division}'.
En el dato actual, '{atributo_division}' vale '{valor_atributo}', así que bajará por la rama '{valor_atributo}'."],

	"eval_node_spine":
	["El dato llega a un nodo de decisión.
Este nodo divide usando el atributo '{atributo_division}'.
Como en el dato actual '{atributo_division}' vale '{valor_atributo}', el dato continuará por la rama '{valor_atributo}'."],

	"eval_node_leaf_correct":
	["El dato llega a un nodo hoja que clasifica como '{etiqueta_nodo}'.
La etiqueta real del dato también es '{etiqueta_real}', así que la clasificación es correcta."],

	"eval_node_leaf_wrong":
	["El dato llega a un nodo hoja que clasifica como '{etiqueta_nodo}', pero su etiqueta real es '{etiqueta_real}'.
Por lo tanto, la clasificación es incorrecta.
{explicacion_error_clasificacion}"]
}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_container.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll_container.mouse_force_pass_scroll_events = false
	_ignore_mouse_input_for_window_content()
	
	label0.add_theme_font_size_override("font_size", font_size)
	label1.add_theme_font_size_override("font_size", font_size)
	latexformula.request_formula(ENTROPY_FORMULA)
	_set_entropy_formula_visible(false)
	if not SignalsObserver.dtree_node_selected.is_connected(update_node_partition_text):
		SignalsObserver.dtree_node_selected.connect(update_node_partition_text)
	if not SignalsObserver.dtree_eval_data_selected.is_connected(update_eval_data_text):
		SignalsObserver.dtree_eval_data_selected.connect(update_eval_data_text)
	if not SignalsObserver.dtree_eval_data_advanced.is_connected(update_eval_data_advanced_text):
		SignalsObserver.dtree_eval_data_advanced.connect(update_eval_data_advanced_text)
	if not SignalsObserver.dtree_training_finished.is_connected(show_training_finished_text):
		SignalsObserver.dtree_training_finished.connect(show_training_finished_text)

	SignalsObserver.clear_window.connect(clear)



## Clears all the content in the window
func clear() -> void:
	_clear_clicked_dnode_window_snapshot()
	label0.text = ""
	label1.text = ""
	latexformula.reset_sprite()
	_set_entropy_formula_visible(false)
	_remove_chart()
	current_evaldata_instance_id = -1
	current_evaldata_text = ""


func show_training_finished_text() -> void:
	_clear_clicked_dnode_window_snapshot()
	clear()
	label0.text = TRAINING_FINISHED_TEXT


func update_current_text(details_dict: Dictionary) -> void:
	_clear_clicked_dnode_window_snapshot()
	details_dict = details_dict.duplicate(true)
	
	var plot_data: Dictionary[String, float] = {}
	
	if details_dict.has("lista_ganancias") and typeof(details_dict["lista_ganancias"]) == TYPE_DICTIONARY:
		plot_data = details_dict["lista_ganancias"]
	var zero_entropy_explanation: String = _build_zero_entropy_explanation(plot_data)
	
	_clean_lists(details_dict)
	
	_remove_chart()
	
	var tipo_de_nodo: String = details_dict["tipo_de_nodo"]
	match tipo_de_nodo:
		"internal":
			_set_entropy_formula_visible(true)
			label0.text = template_texts[tipo_de_nodo][0].format(details_dict)
			_add_chart("Entropía por atributo", plot_data)
			call_deferred("_ignore_mouse_input_for_window_content")
			vboxcontainer.move_child(label1, -1)
			label1.text = template_texts[tipo_de_nodo][1].format(details_dict) + zero_entropy_explanation
		"internal_multi_atribute":
			_set_entropy_formula_visible(true)
			label0.text = template_texts[tipo_de_nodo][0].format(details_dict)
			_add_chart("Entropía por atributo", plot_data)
			call_deferred("_ignore_mouse_input_for_window_content")
			vboxcontainer.move_child(label1, -1)
			label1.text = template_texts[tipo_de_nodo][1].format(details_dict) + zero_entropy_explanation
		"leaf":
			_set_entropy_formula_visible(false)
			label0.text = template_texts[tipo_de_nodo][0].format(details_dict)
			label1.text = ""
		"leaf_mayority":
			_set_entropy_formula_visible(false)
			label0.text = template_texts[tipo_de_nodo][0].format(details_dict)
			label1.text = ""
		"leaf_majority":
			_set_entropy_formula_visible(false)
			label0.text = template_texts[tipo_de_nodo][0].format(details_dict)
			label1.text = template_texts[tipo_de_nodo][1].format(details_dict)


func update_node_partition_text(details_dict: Dictionary) -> void:
	if _should_restore_clicked_dnode_window():
		restore_clicked_dnode_window_snapshot()
		return

	_cache_clicked_dnode_window_snapshot()

	details_dict = details_dict.duplicate(true)
	_prepare_partition_details(details_dict)
	_clean_lists(details_dict)

	_remove_chart()
	_set_entropy_formula_visible(false)

	var template_key: String = "node_pending" if _is_pending_node(details_dict) else "node_partition"
	label0.text = template_texts[template_key][0].format(details_dict)
	label1.text = template_texts[template_key][1].format(details_dict)


func update_eval_data_text(details_dict: Dictionary) -> void:
	_clear_clicked_dnode_window_snapshot()
	details_dict = details_dict.duplicate(true)
	_clean_lists(details_dict)

	_remove_chart()
	_set_entropy_formula_visible(false)

	label0.text = template_texts["eval_data"][0].format(details_dict)
	label1.text = template_texts["eval_data"][1].format(details_dict)


func update_eval_data_advanced_text(node_type: int, eval_data_info: Dictionary, node_info: Dictionary) -> void:
	_clear_clicked_dnode_window_snapshot()
	_remove_chart()
	_set_entropy_formula_visible(false)

	var data_details: Dictionary = eval_data_info.duplicate(true)
	var evaldata_instance_id: int = int(data_details.get("evaldata_instance_id", -1))
	_clean_lists(data_details)
	var evaldata_text: String = template_texts["eval_data_current"][0].format(data_details)
	if current_evaldata_instance_id != evaldata_instance_id or label0.text != current_evaldata_text:
		current_evaldata_instance_id = evaldata_instance_id
		current_evaldata_text = evaldata_text
		label0.text = evaldata_text

	var node_details: Dictionary = node_info.duplicate(true)
	_prepare_eval_node_details(node_type, eval_data_info, node_details)
	_clean_lists(node_details)

	match node_type:
		Constants.DNODES.root:
			label1.text = template_texts["eval_node_root"][0].format(node_details)
		Constants.DNODES.spine:
			label1.text = template_texts["eval_node_spine"][0].format(node_details)
		Constants.DNODES.hoja:
			if bool(node_details.get("clasificacion_correcta", false)):
				label1.text = template_texts["eval_node_leaf_correct"][0].format(node_details)
			else:
				label1.text = template_texts["eval_node_leaf_wrong"][0].format(node_details)


func _prepare_eval_node_details(node_type: int, eval_data_info: Dictionary, node_details: Dictionary) -> void:
	if not node_details.has("atributo_division"):
		node_details["atributo_division"] = node_details.get("attribute", "")
	if not node_details.has("etiqueta_nodo"):
		node_details["etiqueta_nodo"] = node_details.get("label", "")
	if node_details.get("valor_atributo", null) == null:
		node_details["valor_atributo"] = "sin valor"

	if node_type != Constants.DNODES.hoja:
		return

	var etiqueta_real: String = str(eval_data_info.get("etiqueta", ""))
	var etiqueta_nodo: String = str(node_details.get("etiqueta_nodo", ""))
	node_details["etiqueta_real"] = etiqueta_real
	node_details["clasificacion_correcta"] = etiqueta_real == etiqueta_nodo

	if bool(node_details["clasificacion_correcta"]):
		return

	var pureza: float = float(node_details.get("pureza_nodo_valor", 0.0))
	if pureza >= 1.0:
		node_details["explicacion_error_clasificacion"] = "Este nodo es completamente puro: en los datos de entrenamiento que llegaron aquí todas las muestras tenían la etiqueta '%s'. Si este dato tiene otra etiqueta, significa que en los datos de entrenamiento no había ninguna muestra como esta." % etiqueta_nodo
	else:
		node_details["explicacion_error_clasificacion"] = "Este nodo no era completamente puro. Durante el entrenamiento llegaron muestras con distintas etiquetas, pero la etiqueta real '%s' no consiguió suficientes muestras como para superar a la etiqueta ganadora '%s'." % [etiqueta_real, etiqueta_nodo]


func _prepare_partition_details(details_dict: Dictionary) -> void:
	var tipo_de_nodo: String = details_dict.get("tipo_de_nodo", "")
	var is_pending_node: bool = _is_pending_node(details_dict)
	var is_leaf_node: bool = bool(details_dict.get("is_leaf", tipo_de_nodo.begins_with("leaf")))
	details_dict["tipo_visual_de_nodo"] = "pendiente" if is_pending_node else "hoja" if is_leaf_node else "de decisión"

	var branch_value = details_dict.get("valor_rama", details_dict.get("branch_value", null))
	details_dict["texto_rama"] = "" if branch_value == null else " desde la rama '%s'" % str(branch_value)

	if is_pending_node:
		var branch_attribute: String = str(details_dict.get("atributo_rama", details_dict.get("parent_attribute", "")))
		details_dict["texto_decision_nodo"] = "Aún no se ha decidido la característica por la que partirá este nodo."
		if not branch_attribute.is_empty() and branch_value != null:
			details_dict["texto_decision_nodo"] += " Solo se sabe que los datos que vengan por aquí tendrán la característica '%s' con el valor '%s'." % [branch_attribute, str(branch_value)]
		elif branch_value != null:
			details_dict["texto_decision_nodo"] += " Solo se sabe que los datos que vengan por aquí llegan desde la rama '%s'." % str(branch_value)
		return

	if not details_dict.has("pureza_nodo"):
		details_dict["pureza_nodo"] = "sin datos"
	if not details_dict.has("numero_etiqueta_mayoritaria"):
		details_dict["numero_etiqueta_mayoritaria"] = 0
	if not details_dict.has("etiqueta_mayoritaria"):
		details_dict["etiqueta_mayoritaria"] = details_dict.get("label", "")
	if not details_dict.has("lista_etiquetas"):
		details_dict["lista_etiquetas"] = []

	if is_leaf_node:
		details_dict["texto_decision_nodo"] = "Como es hoja, la partición termina aquí y el nodo clasifica con la etiqueta '%s'." % str(details_dict.get("label", details_dict.get("etiqueta_mayoritaria", "")))
	else:
		var formatted_branches: Dictionary = {"lista_ramas_mejor_atributo": details_dict.get("lista_ramas_mejor_atributo", "")}
		_clean_lists(formatted_branches)
		details_dict["texto_decision_nodo"] = "Como es un nodo de decisión, la partición continúa dividiendo por el atributo '%s'. Sus ramas posibles son: %s." % [str(details_dict.get("attribute", details_dict.get("mejor_atributo", ""))), str(formatted_branches["lista_ramas_mejor_atributo"])]


func _is_pending_node(details_dict: Dictionary) -> bool:
	return bool(details_dict.get("is_pending", false)) or str(details_dict.get("tipo_de_nodo", "")) == "pending"


func _build_zero_entropy_explanation(plot_data: Dictionary[String, float]) -> String:
	var zero_entropy_attributes: Array[String] = []
	for attribute in plot_data:
		if is_zero_approx(plot_data[attribute]):
			zero_entropy_attributes.append(attribute)

	if zero_entropy_attributes.is_empty():
		return ""

	var attributes_text: String = _format_attribute_list(zero_entropy_attributes)
	var explanation_details: Dictionary[String, String] = {
		"texto_atributos": "El atributo %s" % attributes_text if zero_entropy_attributes.size() == 1 else "Los atributos %s" % attributes_text,
		"verbo_entropia": "tiene" if zero_entropy_attributes.size() == 1 else "tienen",
		"texto_referencia": "ese atributo" if zero_entropy_attributes.size() == 1 else "esos atributos"
	}
	return ZERO_ENTROPY_EXPLANATION.format(explanation_details)


func _format_attribute_list(attributes: Array[String]) -> String:
	var attributes_text: String = ""
	for i in range(attributes.size()):
		var attribute_text: String = "'%s'" % attributes[i]
		if i == 0:
			attributes_text = attribute_text
		elif i == attributes.size() - 1:
			attributes_text += " y " + attribute_text
		else:
			attributes_text += ", " + attribute_text
	return attributes_text


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
	for child in scroll_container.get_children():
		_set_mouse_filter_recursive(child, Control.MOUSE_FILTER_IGNORE)
	scroll_container.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_entropy_formula_visible(formula_is_visible: bool) -> void:
	latexformula.visible = formula_is_visible


func _remove_chart() -> void:
	var chart = vboxcontainer.get_node_or_null("BarsChart")
	if chart:
		vboxcontainer.remove_child(chart)
		chart.queue_free()
	current_chart_title = ""
	current_chart_data.clear()


func _add_chart(chart_title: String, chart_data: Dictionary[String, float]) -> void:
	current_chart_title = chart_title
	current_chart_data = chart_data.duplicate(true)
	vboxcontainer.add_child(BarsChart.newone(chart_title, chart_data))


func _should_restore_clicked_dnode_window() -> bool:
	return Variables.dtree_clicked_node_id == -1 \
		and not Variables.dtree_clicked_node_window_snapshot.is_empty()


func _cache_clicked_dnode_window_snapshot() -> void:
	if not Variables.dtree_clicked_node_window_snapshot.is_empty():
		return

	Variables.dtree_clicked_node_window_snapshot = {
		"label0": label0.text,
		"label1": label1.text,
		"latex_formula": latexformula.formula,
		"latex_visible": latexformula.visible,
		"current_evaldata_instance_id": current_evaldata_instance_id,
		"current_evaldata_text": current_evaldata_text,
		"chart_title": current_chart_title,
		"chart_data": current_chart_data.duplicate(true),
	}


func restore_clicked_dnode_window_snapshot() -> void:
	if Variables.dtree_clicked_node_window_snapshot.is_empty():
		return

	var cached_window: Dictionary = Variables.dtree_clicked_node_window_snapshot
	label0.text = str(cached_window.get("label0", ""))
	label1.text = str(cached_window.get("label1", ""))
	current_evaldata_instance_id = int(cached_window.get("current_evaldata_instance_id", -1))
	current_evaldata_text = str(cached_window.get("current_evaldata_text", ""))

	_remove_chart()
	var chart_data: Dictionary[String, float] = _to_float_dictionary(cached_window.get("chart_data", {}))
	if not chart_data.is_empty():
		_add_chart(str(cached_window.get("chart_title", "")), chart_data)
		call_deferred("_ignore_mouse_input_for_window_content")
		vboxcontainer.move_child(label1, -1)

	var cached_formula: String = str(cached_window.get("latex_formula", ""))
	if cached_formula.strip_edges().is_empty():
		latexformula.reset_sprite()
	else:
		latexformula.request_formula(cached_formula)
	_set_entropy_formula_visible(bool(cached_window.get("latex_visible", false)))

	Variables.dtree_clicked_node_window_snapshot.clear()


func _clear_clicked_dnode_window_snapshot(_arg1 = null, _arg2 = null, _arg3 = null) -> void:
	Variables.dtree_clicked_node_window_snapshot.clear()


func _to_float_dictionary(source: Variant) -> Dictionary[String, float]:
	var result: Dictionary[String, float] = {}
	if not (source is Dictionary):
		return result

	for key in source:
		result[str(key)] = float(source[key])
	return result


func _set_mouse_filter_recursive(node: Node, filter: Control.MouseFilter) -> void:
	if node is Control:
		node.mouse_filter = filter

	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)


# How to move the ScrollContainer
#func _gui_input(event: InputEvent) -> void:
	## Handle mouse motion for middle mouse dragging
	#if event is InputEventMouseMotion and is_middle_mouse_dragging:
		## The scroll aplied is going to be the dif frame to frame of
		## where the mause where and where the mouse is
		#var delta_position = event.position - last_mouse_position
#
		## The diff is aplied
		#scroll_container.scroll_horizontal -= int(delta_position.x)
		#scroll_container.scroll_vertical -= int(delta_position.y)
#
		## The new position is saved and the input is set as handled
		#last_mouse_position = event.position
		#accept_event()
	#
	## If there is a mouse event
	#if event is InputEventMouseButton:
		## Move the view with middle mouse
		#if event.button_index == MOUSE_BUTTON_MIDDLE:
			#if event.pressed:
				#is_middle_mouse_dragging = true
				#last_mouse_position = event.position
			#else:
				#is_middle_mouse_dragging = false
#
			#accept_event()
		#
		## Move scroll container view
		#elif event.pressed and not event.ctrl_pressed:
			## Save the diference frame to frame
			#var delta: int = 0
			#
			## Determine direction
			#if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				#delta = -scroll_speed
			#elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				#delta = scroll_speed
				#
			## Apply scroll
			#if delta != 0:
				## Check Shift for horizontal scrolling
				#if event.shift_pressed:
					#scroll_container.scroll_horizontal += delta
				#else:
					#scroll_container.scroll_vertical += delta
				#
				## Optional: do not pass the input to lower nodes
				#accept_event()
