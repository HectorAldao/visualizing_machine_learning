extends PanelContainer


@export var color_good: Color
@export var color_error: Color


@onready var hboxcontainer: HBoxContainer = $VBoxContainer/HBoxContainer
@onready var entrenar_button: Button = $VBoxContainer/Button
@onready var informative_text: Label = $VBoxContainer/PanelContainer/Label


const DICT_OF_DATASETS: Dictionary = \
	{"Frutas":
		[
			[
			{"color": "red", "shape": "round", "size": "big", "class": "apple"},
			{"color": "green", "shape": "round", "size": "big", "class": "apple"},
			{"color": "yellow", "shape": "long", "size": "medium", "class": "banana"},
			{"color": "green", "shape": "long", "size": "medium", "class": "banana"},
			{"color": "orange", "shape": "round", "size": "medium", "class": "orange"},
			],
			["color", "shape", "size"]
		]
	}


var selected_option: String
var datast_info: Array[Dictionary]
var attrs_info: Array[String]


func _ready() -> void:
	
	entrenar_button.disabled = true
	entrenar_button.pressed.connect(_on_entrenar_button_pressed)
	
	for button: Button in hboxcontainer.get_children():
		button.pressed.connect(_on_button_pressed.bind(button.text))

func _on_entrenar_button_pressed():
	SignalsObserver.dataset_selected.emit(datast_info, attrs_info)
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
		"Csv":
			_load_csv()
		_:
			informative_text.text = "Se seleccionó el dataset %s " % selected_option
			informative_text.label_settings.font_color = color_good
			datast_info = safe_get_array_of_dicts(DICT_OF_DATASETS[selected_option][0])
			attrs_info = safe_get_array_of_strings(DICT_OF_DATASETS[selected_option][1])
			entrenar_button.disabled = false


## Opens a window to select a csv, reads it
## and returns and array with each entity
## on the csv as a dictionary.
func _load_csv():
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


## Checks if the csv selected has the correct format
## and parses it to the corresponding file type
func _parse_csv(file_path):
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		var error = FileAccess.get_open_error()
		informative_text.text = "Error abriendo el archivo: %d" % error
		informative_text.label_settings.font_color = color_error
		entrenar_button.disabled = true
		return
	
	# Get columns
	var headers = file.get_csv_line()
	
	var data_array = []
	
	while not file.eof_reached():
		var row = file.get_csv_line()
		
		if row.is_empty():
			continue
		
		# Map column with value for each row
		var row_dict = {}
		for i in range(min(headers.size(), row.size())):
			row_dict[headers[i]] = row[i]
		
		data_array.append(row_dict)
	
	file.close()
	
	informative_text.text = "CSV cargado correctamente: %d datos" % data_array.size()
	informative_text.label_settings.font_color = color_good
	datast_info = data_array
	attrs_info = headers
	entrenar_button.disabled = false


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
				result.append(item)
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
