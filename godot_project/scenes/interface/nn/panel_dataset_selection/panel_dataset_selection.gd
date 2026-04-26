extends PanelContainer


@export var color_good: Color
@export var color_error: Color


@onready var hboxcontainer: HBoxContainer = $VBoxContainer/HBoxContainer
@onready var entrenar_button: Button = $VBoxContainer/Button
@onready var informative_text: Label = $VBoxContainer/PanelContainer/Label


const posible_y_column_names: Array[String] = ["class", "Class", "y", "Y", "label", "Label", "target", "Target"]
const DICT_OF_DATASETS: Dictionary = {
	"EnemyAI": [
		[
			{"health": 0.15, "stamina": 0.80, "distance": 0.50, "class": "curarse"},
			{"health": 0.90, "stamina": 0.95, "distance": 0.10, "class": "atacar"},
			{"health": 0.40, "stamina": 0.10, "distance": 0.20, "class": "defender"},
			{"health": 0.85, "stamina": 0.40, "distance": 0.90, "class": "acechar"},
			{"health": 0.20, "stamina": 0.15, "distance": 0.15, "class": "defender"},
			{"health": 0.70, "stamina": 0.80, "distance": 0.05, "class": "atacar"},
			{"health": 0.10, "stamina": 0.05, "distance": 0.80, "class": "curarse"},
			{"health": 0.55, "stamina": 0.60, "distance": 0.65, "class": "acechar"}
		],
		["health", "stamina", "distance"],
		[Constants.ACT_FUNCS.softmax]
	],
	"Cultivos": [
		[
			{"hydration": 0.85, "light": 0.90, "nutrients": 0.75, "temperature": 0.60, "target": 12.45},
			{"hydration": 0.20, "light": 0.50, "nutrients": 0.30, "temperature": 0.40, "target": 2.10},
			{"hydration": 0.55, "light": 0.10, "nutrients": 0.60, "temperature": 0.55, "target": 4.35},
			{"hydration": 0.95, "light": 0.95, "nutrients": 0.90, "temperature": 0.85, "target": 15.80},
			{"hydration": 0.40, "light": 0.40, "nutrients": 0.15, "temperature": 0.90, "target": 3.25},
			{"hydration": 0.70, "light": 0.75, "nutrients": 0.50, "temperature": 0.50, "target": 9.15},
			{"hydration": 0.10, "light": 0.85, "nutrients": 0.45, "temperature": 0.25, "target": 1.50},
			{"hydration": 0.60, "light": 0.60, "nutrients": 0.80, "temperature": 0.70, "target": 10.20}
		],
		["hydration", "light", "nutrients", "temperature"],
		[Constants.ACT_FUNCS.identity]
	]
}


var selected_option: String
var datast_info: Array[Dictionary]
var attrs_info: Array[String]
var act_func_restriction: int
var nn_restrictions: Dictionary[int, int]
var target_column_name: String = ""
var class_decoder_map: Dictionary = {}
var _web_csv_callback: Variant


func _ready() -> void:

	entrenar_button.disabled = true
	entrenar_button.pressed.connect(_on_entrenar_button_pressed)

	for button: Button in hboxcontainer.get_children():
		button.pressed.connect(_on_button_pressed.bind(button.text))

	SignalsObserver.train_nn.connect(_on_nn_train_started)

func _on_entrenar_button_pressed():
	SignalsObserver.dataset_selected_nn.emit(datast_info, attrs_info, nn_restrictions)
	visible = false

func _on_nn_train_started():
	visible = false

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
			_load_csv()
		_:  # If a default dataset was selected

			# Save its info on the relevant variables
			datast_info = safe_get_array_of_dicts(DICT_OF_DATASETS[selected_option][0])
			attrs_info = safe_get_array_of_strings(DICT_OF_DATASETS[selected_option][1])
			act_func_restriction = DICT_OF_DATASETS[selected_option][2][0]

			# Extract its analysis to ensure the correct change of informative text
			# and restrictions over the nn
			var target_info = _analyze_and_prepare_target(datast_info)
			if not target_info["ok"]:
				informative_text.text = target_info["message"]
				informative_text.label_settings.font_color = color_error
				entrenar_button.disabled = true
				return

			# Set the stablished restrictions
			nn_restrictions = {0: attrs_info.size(), -1: target_info["count"], -2: act_func_restriction}  # Restrictions for "in" and "out"

			informative_text.text = _build_dataset_summary_text(selected_option, attrs_info.size(), target_info)
			informative_text.label_settings.font_color = color_good
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
	var display_name := "dataset.csv"
	if args.size() >= 2 and not str(args[1]).is_empty():
		display_name = str(args[1])

	var temp_path := "user://selected_nn_dataset.csv"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		informative_text.text = "Error preparando el CSV: %d" % error
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	file.store_string(csv_text)
	file.close()
	_parse_csv(temp_path, display_name)


## Checks if the csv selected has the correct format
## and parses it to the corresponding file type
func _parse_csv(file_path, display_name: String = ""):
	var file = FileAccess.open(file_path, FileAccess.READ)

	# If there were a problem with the file
	if file == null:
		var error = FileAccess.get_open_error()
		informative_text.text = "Error abriendo el archivo: %d" % error
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	# Get columns
	var headers = safe_get_array_of_strings(file.get_csv_line() as Array)
	var target_col_name = _find_target_column(headers)
	if target_col_name.is_empty():
		file.close()
		informative_text.text = "El CSV no tiene columna objetivo (class, y, label, ...)."
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	# Each data its going to be in this Array
	var data_array: Array[Dictionary] = []

	# While true, but is while there is lines to read
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

	# Delete the target column. No loger needed
	headers.erase(target_col_name)

	# The "target_info" is used to show the text in the UI
	var target_info = _analyze_and_prepare_target(data_array, target_col_name)

	# If there were an error with the analyze
	if not target_info["ok"]:
		print("[LOG] The parsed csv wasn't parsed well") #debug
		informative_text.text = target_info["message"]
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return

	if target_info.kind == "classification":
		act_func_restriction = Constants.ACT_FUNCS.softmax
	elif target_info.kind == "regression":
		act_func_restriction = Constants.ACT_FUNCS.identity

	# If there weren't an error,
	# change the text
	if display_name.is_empty():
		display_name = file_path.get_file()
	informative_text.text = _build_dataset_summary_text(display_name, headers.size(), target_info)
	informative_text.label_settings.font_color = color_good
	# and update the info
	datast_info = data_array
	attrs_info = headers
	nn_restrictions = {0: headers.size(), -1: target_info["count"], -2: act_func_restriction}  # Restrictions for "in" and "out"
	entrenar_button.disabled = false


## To find the name on the target column
func _find_target_column(headers: Array[String]) -> String:
	for col_name in posible_y_column_names:
		if headers.has(col_name):
			return col_name
	return ""


## Processes the target column, ensuring that if is a string, it changes to
## int, asociating an int to each class. Returns the Dictionary of information
## needed by the information_text to explain the data loaded.
func _analyze_and_prepare_target(data_array: Array[Dictionary], target_col_hint: String = "") -> Dictionary:
	if data_array.is_empty():
		return {"ok": false, "message": "El dataset no contiene filas."}

	# Datasets coming from constants can contain read-only dictionaries.
	# Clone each row to a mutable dictionary before any in-place update.
	for i in range(data_array.size()):
		var mutable_row: Dictionary = data_array[i].duplicate(true)
		data_array[i] = mutable_row

	var resolved_target_col = target_col_hint
	if resolved_target_col.is_empty():
		resolved_target_col = _find_target_column(safe_get_array_of_strings(data_array[0].keys()))

	if resolved_target_col.is_empty():
		return {"ok": false, "message": "No se detectó columna objetivo (class, y, label, ...)."}

	var has_string_values = false
	var has_float_values = false
	var has_int_values = false

	for row in data_array:
		if not row.has(resolved_target_col):
			continue
		var normalized_value = _normalize_numeric_value(row[resolved_target_col])
		row[resolved_target_col] = normalized_value
		match typeof(normalized_value):
			TYPE_STRING:
				has_string_values = true
			TYPE_FLOAT:
				has_float_values = true
			TYPE_INT:
				has_int_values = true

	var info: Dictionary = {
		"ok": true,
		"target_col": resolved_target_col,
		"kind": "classification",
		"count": 0,
	}

	class_decoder_map = {}

	if has_string_values:
		class_decoder_map = one_hot_encode_string_targets(data_array, resolved_target_col)
		Variables.nn_output_class_decoder = class_decoder_map
		info["kind"] = "classification"
		info["count"] = class_decoder_map.size()
	elif has_float_values and not has_int_values:
		var unique_float_values: Dictionary = {}
		for row in data_array:
			if row.has(resolved_target_col):
				unique_float_values[row[resolved_target_col]] = true
		Variables.nn_output_class_decoder = {}
		info["kind"] = "regression"
		#info["count"] = unique_float_values.size()
		info["count"] = 1  #TODO: make that the regression problemens can have more than one target

	else:
		var unique_int_classes: Dictionary = {}
		for row in data_array:
			if row.has(resolved_target_col):
				unique_int_classes[int(row[resolved_target_col])] = true
		Variables.nn_output_class_decoder = {}
		info["kind"] = "classification"
		info["count"] = unique_int_classes.size()

	target_column_name = resolved_target_col
	return info


func _normalize_numeric_value(value: Variant) -> Variant:
	if value is String:
		var text: String = value.strip_edges()
		if text.is_valid_int():
			return int(text)
		if text.is_valid_float():
			return float(text)
	return value


func _build_dataset_summary_text(dataset_name: String, input_attrs_count: int, target_info: Dictionary) -> String:
	var summary = "Se cargó el dataset %s.\nTiene %d atributos de entrada" % [dataset_name, input_attrs_count]
	if target_info["kind"] == "classification":
		var classes_count: int = int(target_info["count"])
		summary += " y %d clases,\nse establecerán %d neuronas de entrada y %d de salida\ny se recomienda función de activación softmax\npara la capa de salida" % [classes_count, input_attrs_count, classes_count]
	else:  # regression
		summary += " y %d valores a predecir" % int(target_info["count"])
	return summary


## Encodes string labels to integer ids and returns a decoder map: int -> original string.
func one_hot_encode_string_targets(data_array: Array[Dictionary], target_col_name: String) -> Dictionary:
	var string_to_int: Dictionary = {}
	var int_to_string: Dictionary = {}
	var current_index := 0

	for row in data_array:
		if not row.has(target_col_name):
			continue

		var label_text := str(row[target_col_name])
		if not string_to_int.has(label_text):
			string_to_int[label_text] = current_index
			int_to_string[current_index] = label_text
			current_index += 1

		row[target_col_name] = string_to_int[label_text]

	return int_to_string


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
				var mutable_item: Dictionary = item.duplicate(true)
				result.append(mutable_item)
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
