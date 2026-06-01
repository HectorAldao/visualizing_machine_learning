extends PanelContainer


@export var color_good: Color
@export var color_error: Color


@onready var hboxcontainer: HBoxContainer = %DatasetsDtreeHBoxContainer
@onready var entrenar_button: Button = %SelectDatasetDtreeButton
@onready var informative_text: Label = %InformativeTextDtree
@onready var target_selector: VBoxContainer = %TargetSelectorDtree
@onready var target_scroll_container: ScrollContainerV2 = %TargetScrollContainerDtree


const DICT_OF_DATASETS: Dictionary = \
		{"Frutas": [
		[
			# Instancias originales
			{"color": "rojo", "forma": "redonda", "tamaño": "mediana", "class": "manzana"},
			{"color": "rojo", "forma": "redonda", "tamaño": "mediana", "class": "manzana"},
			{"color": "rojo", "forma": "redonda", "tamaño": "mediana", "class": "manzana"},
			{"color": "verde", "forma": "redonda", "tamaño": "mediana", "class": "manzana"},
			{"color": "amarillo", "forma": "alargada", "tamaño": "mediana", "class": "plátano"},
			#{"color": "verde", "forma": "alargada", "tamaño": "mediana", "class": "plátano"},
			{"color": "naranja", "forma": "redonda", "tamaño": "mediana", "class": "naranja"},
			
			# Nuevas instancias con características superpuestas (generan nodos hoja impuros)
			{"color": "rojo", "forma": "redonda", "tamaño": "grande", "class": "granada"}, # Colisiona con manzana
			{"color": "naranja", "forma": "redonda", "tamaño": "mediana", "class": "mandarina"}, # Colisiona con orange
			{"color": "verde", "forma": "alargada", "tamaño": "grande", "class": "pepino"}, # Colisiona con green plátano
			{"color": "verde", "forma": "alargada", "tamaño": "grande", "class": "calabacín"}, # Colisiona con green plátano

			{"color": "blanco", "forma": "redonda", "tamaño": "grande", "class": "melón"}, # Colisiona con green plátano
			{"color": "rojo", "forma": "redonda", "tamaño": "grande", "class": "sandía"}, # Colisiona con green plátano
			
			# Otras frutas para dar más volumen
			{"color": "rojo", "forma": "redonda", "tamaño": "pequeña", "class": "cereza"},
			{"color": "rojo", "forma": "redonda", "tamaño": "pequeña", "class": "fresa"}, # Colisiona con cereza
			{"color": "morado", "forma": "redonda", "tamaño": "pequeña", "class": "uva"},
			{"color": "morado", "forma": "redonda", "tamaño": "mediana", "class": "ciruela"},
			{"color": "morado", "forma": "redonda", "tamaño": "mediana", "class": "ciruela"},
			{"color": "rojo", "forma": "redonda", "tamaño": "mediana", "class": "ciruela"},
			{"color": "amarillo", "forma": "redonda", "tamaño": "mediana", "class": "ciruela"},
			{"color": "verde", "forma": "redonda", "tamaño": "pequeña", "class": "uva"},
			{"color": "amarillo", "forma": "redonda", "tamaño": "mediana", "class": "limón"},
			{"color": "verde", "forma": "redonda", "tamaño": "mediana", "class": "lima"}
		],
		["color", "forma", "tamaño"]
	],
	
	"Tenis": [
		[
			{"outlook": "sunny", "temperature": "hot", "humidity": "high", "wind": "weak", "class": "no"},
			{"outlook": "sunny", "temperature": "hot", "humidity": "high", "wind": "strong", "class": "no"},
			{"outlook": "overcast", "temperature": "hot", "humidity": "high", "wind": "weak", "class": "yes"},
			{"outlook": "rain", "temperature": "mild", "humidity": "high", "wind": "weak", "class": "yes"},
			{"outlook": "rain", "temperature": "cool", "humidity": "normal", "wind": "weak", "class": "yes"},
			{"outlook": "rain", "temperature": "cool", "humidity": "normal", "wind": "strong", "class": "no"},
			{"outlook": "overcast", "temperature": "cool", "humidity": "normal", "wind": "strong", "class": "yes"},
			{"outlook": "sunny", "temperature": "mild", "humidity": "high", "wind": "weak", "class": "no"},
			{"outlook": "sunny", "temperature": "cool", "humidity": "normal", "wind": "weak", "class": "yes"},
			{"outlook": "rain", "temperature": "mild", "humidity": "normal", "wind": "weak", "class": "yes"},
			{"outlook": "sunny", "temperature": "mild", "humidity": "normal", "wind": "strong", "class": "yes"},
			{"outlook": "overcast", "temperature": "mild", "humidity": "high", "wind": "strong", "class": "yes"},
			{"outlook": "overcast", "temperature": "hot", "humidity": "normal", "wind": "weak", "class": "yes"},
			{"outlook": "rain", "temperature": "mild", "humidity": "high", "wind": "strong", "class": "no"}
		],
		["outlook", "temperature", "humidity", "wind"]
	]
}


var selected_option: String
var datast_info: Array[Dictionary]
var attrs_info: Array[String]
var target_attrs_info: Array[String]
var csv_display_name: String = ""
var csv_headers: Array[String] = []
var csv_raw_data: Array[Dictionary] = []
var _web_csv_callback: Variant
var _is_selecting_inference_dataset: bool = false
var _required_inference_attrs: Array[String] = []
var _required_inference_target_attrs: Array[String] = []


func _ready() -> void:

	entrenar_button.disabled = true
	target_scroll_container.visible = false
	entrenar_button.pressed.connect(_on_entrenar_button_pressed)

	for button: Button in hboxcontainer.get_children():
		button.pressed.connect(_on_button_pressed.bind(button.text))

func _on_entrenar_button_pressed():
	if _is_selecting_inference_dataset and not _validate_inference_dataset_structure():
		return

	SignalsObserver.dataset_selected.emit(datast_info, attrs_info)
	visible = false


func show_for_inference(required_attrs: Array[String], required_target_attrs: Array[String]) -> void:
	restart_dataset_selection()
	_is_selecting_inference_dataset = true
	_required_inference_attrs = required_attrs.duplicate()
	_required_inference_target_attrs = required_target_attrs.duplicate()
	entrenar_button.text = "Cargar Dataset"
	visible = true
	await get_tree().process_frame
	position = (get_parent_area_size() - size) / 2


func restart_dataset_selection() -> void:
	selected_option = ""
	datast_info = []
	attrs_info = []
	target_attrs_info = []
	_reset_csv_target_selector()
	informative_text.text = "Aún no se ha seleccionado dataset"
	informative_text.label_settings.font_color = color_good
	entrenar_button.text = "Seleccionar Dataset"
	entrenar_button.disabled = true

func _on_button_pressed(option: String):
	selected_option = option
	_on_dataset_selected()
	if option == "Csv":
		await get_tree().create_timer(1.0).timeout


## Changes the state of the selector depending on
## the selection, of if the csv was read without problem
func _on_dataset_selected():
	match selected_option:
		"Cargar\nCsv":
			_reset_csv_target_selector()
			_load_csv()
		_:
			_reset_csv_target_selector()
			informative_text.text = "Se seleccionó el dataset %s " % selected_option
			informative_text.label_settings.font_color = color_good
			datast_info = safe_get_array_of_dicts(DICT_OF_DATASETS[selected_option][0])
			attrs_info = safe_get_array_of_strings(DICT_OF_DATASETS[selected_option][1])
			target_attrs_info = _get_target_attrs_from_inputs(datast_info, attrs_info)
			if _is_selecting_inference_dataset and not _validate_inference_dataset_structure():
				entrenar_button.disabled = true
				return
			entrenar_button.disabled = false


## Opens a window to select a csv, reads it
## and returns and array with each entity
## on the csv as a dictionary.
func _load_csv():
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		_load_csv_from_browser()
		return

	var file_dialog = FileDialog.new()

	# Config to access to the file system
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray(["*.csv ; CSV Files"])

	# Use the native file selector
	# if it cant, will load the godot default
	if "use_native_dialog" in file_dialog:
		file_dialog.use_native_dialog = true

	# Connect to the selection signal
	file_dialog.file_selected.connect(func(file_path: String):
		_parse_csv(file_path)
		file_dialog.queue_free()
	)

	# Clear if canceled
	file_dialog.canceled.connect(func():
		file_dialog.queue_free()
	)

	add_child(file_dialog)
	file_dialog.popup_centered_ratio(0.4)


func _load_csv_from_browser():
	var js_bridge = Engine.get_singleton("JavaScriptBridge")
	_web_csv_callback = js_bridge.create_callback(_on_web_csv_loaded)
	js_bridge.get_interface("window").godotCsvUploadCallback = _web_csv_callback

	js_bridge.eval(
		"""
		(function () {
			const input = document.createElement("input");
			input.type = "file";
			input.accept = ".csv,text/csv";
			input.style.display = "none";
			input.addEventListener("change", function () {
				const file = input.files && input.files[0];
				if (!file) {
					input.remove();
					return;
				}
				const reader = new FileReader();
				reader.onload = function (event) {
					window.godotCsvUploadCallback(event.target.result, file.name);
					input.remove();
				};
				reader.onerror = function () {
					window.godotCsvUploadCallback("", file.name, "No se pudo leer el archivo.");
					input.remove();
				};
				reader.readAsText(file);
			});
			document.body.appendChild(input);
			input.click();
		})();
		""",
		true
	)


func _on_web_csv_loaded(args: Array) -> void:
	if args.size() >= 3 and not str(args[2]).is_empty():
		informative_text.text = str(args[2])
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	if args.is_empty() or str(args[0]).is_empty():
		informative_text.text = "No se seleccionó ningún CSV."
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	var csv_text := str(args[0])
	var temp_path := "user://selected_dtree_dataset.csv"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		informative_text.text = "Error preparando el CSV: %d" % error
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	file.store_string(csv_text)
	file.close()
	var display_name := "dataset.csv"
	if args.size() >= 2 and not str(args[1]).is_empty():
		display_name = str(args[1])

	_parse_csv(temp_path, display_name)


## Checks if the csv selected has the correct format
## and parses it to the corresponding file type
func _parse_csv(file_path: String, display_name: String = ""):
	var file = FileAccess.open(file_path, FileAccess.READ)

	if file == null:
		var error = FileAccess.get_open_error()
		informative_text.text = "Error abriendo el archivo: %d" % error
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	# Get columns
	var headers = safe_get_array_of_strings(file.get_csv_line() as Array)
	if headers.size() < 2:
		file.close()
		informative_text.text = "El CSV debe tener al menos dos columnas."
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	var data_array: Array[Dictionary] = []

	while true:
		var row = file.get_csv_line()
		if file.eof_reached():
			break  # Because the eof_reached only goes to true once it tries to reed over the lengh of the file

		if row.is_empty():
			continue

		# Map column with value for each row
		var row_dict = {}
		for i in range(min(headers.size(), row.size())):
			row_dict[headers[i]] = row[i]

		data_array.append(row_dict)

	file.close()

	if data_array.is_empty():
		informative_text.text = "El dataset no contiene filas."
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	if display_name.is_empty():
		display_name = file_path.get_file()

	csv_raw_data = data_array
	csv_headers = headers
	csv_display_name = display_name
	_show_csv_target_selector(csv_headers)


func _reset_csv_target_selector() -> void:
	target_scroll_container.visible = false
	for child in target_selector.get_children():
		target_selector.remove_child(child)
		child.queue_free()

	csv_display_name = ""
	csv_headers = []
	csv_raw_data = []
	target_attrs_info = []
	entrenar_button.disabled = true


func _show_csv_target_selector(headers: Array[String]) -> void:
	target_scroll_container.visible = true
	for child in target_selector.get_children():
		target_selector.remove_child(child)
		child.queue_free()

	var select_target_variable_label: Label = Label.new()
	select_target_variable_label.text = "Seleccione Variable Objetivo"
	target_selector.add_child(select_target_variable_label)

	for header in headers:
		var check_button := CheckButton.new()
		check_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		check_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		check_button.text = header
		check_button.toggled.connect(_on_target_check_toggled.bind(check_button))
		target_selector.add_child(check_button)

	informative_text.text = "Seleccione Variable Objetivo"
	informative_text.label_settings.font_color = color_good
	entrenar_button.disabled = true


func _on_target_check_toggled(button_pressed: bool, toggled_button: CheckButton) -> void:
	if button_pressed:
		for child in target_selector.get_children():
			if child is CheckButton and child != toggled_button:
				child.set_pressed_no_signal(false)

	var selected_targets: Array[String] = _get_selected_target_columns()
	if selected_targets.is_empty():
		informative_text.text = "Seleccione Variable Objetivo"
		informative_text.label_settings.font_color = color_good
		entrenar_button.disabled = true
		return

	var input_attrs := _get_input_attrs_from_targets(csv_headers, selected_targets)
	if input_attrs.is_empty():
		informative_text.text = "Debe quedar al menos un atributo de entrada."
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	datast_info = safe_get_array_of_dicts(csv_raw_data)
	attrs_info = input_attrs
	target_attrs_info = selected_targets
	if _is_selecting_inference_dataset and not _validate_inference_dataset_structure():
		entrenar_button.disabled = true
		return

	informative_text.text = "CSV cargado correctamente: %s\n%d datos" % [csv_display_name, datast_info.size()]
	informative_text.label_settings.font_color = color_good
	entrenar_button.disabled = false


func _validate_inference_dataset_structure() -> bool:
	var missing_attrs: Array[String] = _get_missing_names(_required_inference_attrs, attrs_info)
	if not missing_attrs.is_empty():
		informative_text.text = "El dataset de inferencia no tiene estos atributos de entrada: %s" % ", ".join(missing_attrs)
		informative_text.label_settings.font_color = color_error
		return false

	var extra_attrs: Array[String] = _get_missing_names(attrs_info, _required_inference_attrs)
	if not extra_attrs.is_empty():
		informative_text.text = "El dataset de inferencia tiene atributos de entrada extra: %s" % ", ".join(extra_attrs)
		informative_text.label_settings.font_color = color_error
		return false
	if attrs_info != _required_inference_attrs:
		informative_text.text = "El orden de los atributos de entrada no coincide con el usado al entrenar."
		informative_text.label_settings.font_color = color_error
		return false

	var missing_targets: Array[String] = _get_missing_names(_required_inference_target_attrs, target_attrs_info)
	if not missing_targets.is_empty():
		informative_text.text = "El dataset de inferencia no tiene esta variable objetivo: %s" % ", ".join(missing_targets)
		informative_text.label_settings.font_color = color_error
		return false

	var extra_targets: Array[String] = _get_missing_names(target_attrs_info, _required_inference_target_attrs)
	if not extra_targets.is_empty():
		informative_text.text = "El dataset de inferencia tiene variables objetivo extra: %s" % ", ".join(extra_targets)
		informative_text.label_settings.font_color = color_error
		return false
	if target_attrs_info != _required_inference_target_attrs:
		informative_text.text = "La variable objetivo no coincide con la usada al entrenar."
		informative_text.label_settings.font_color = color_error
		return false

	return true


func _get_missing_names(required_names: Array[String], available_names: Array[String]) -> Array[String]:
	var missing_names: Array[String] = []
	for required_name in required_names:
		if not available_names.has(required_name):
			missing_names.append(required_name)
	return missing_names


func _get_selected_target_columns() -> Array[String]:
	var selected_targets: Array[String] = []
	for child in target_selector.get_children():
		if child is CheckButton and child.button_pressed:
			selected_targets.append(child.text)
	return selected_targets


func _get_input_attrs_from_targets(headers: Array[String], target_cols: Array[String]) -> Array[String]:
	var input_attrs: Array[String] = []
	for header in headers:
		if not target_cols.has(header):
			input_attrs.append(header)
	return input_attrs


func _get_target_attrs_from_inputs(data_array: Array[Dictionary], input_attrs: Array[String]) -> Array[String]:
	var target_attrs: Array[String] = []
	if data_array.is_empty():
		return target_attrs

	for key in data_array[0].keys():
		var key_text := str(key)
		if not input_attrs.has(key_text):
			target_attrs.append(key_text)

	return target_attrs


## Takes an Array and ensures that it is returned as and Array[Dictionay]
## At the time of writing this code, Godot does not suppot nested complex types
## such as Array[Array[Dictionary]].
## So its necessary this function to keep the hard typed in other parts of the code
## where the nesting does not goes that deep.
func safe_get_array_of_dicts(data: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if data is Array:
		for item in data:
			if item is Dictionary:
				result.append(item.duplicate(true))
			else:
				print("An element on the so called \"Array of Dictionary\" isn't a Dictionary: {item}")

	return result


## Takes an Array and ensures that it is returned as and Array[Dictionay]
## At the time of writing this code, Godot does not suppot nested complex types
## such as Array[Array[Dictionary]].
## So its necessary this function to keep the hard typed in other parts of the code
## where the nesting does not goes that deep.
func safe_get_array_of_strings(data: Array) -> Array[String]:
	var result: Array[String] = []

	if data is Array:
		for item in data:
			if item is String:
				result.append(item)
			else:
				print("An element on the so called \"Array of String\" isn't a String: {item}")

	return result
