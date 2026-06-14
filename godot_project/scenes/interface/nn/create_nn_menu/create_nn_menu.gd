extends PanelContainer


@onready var vboxcont: VBoxContainer = $VBoxContainer
@onready var new_neurons_layer: HBoxContainer = $VBoxContainer/NewNeuronsLayer
@onready var network_load_status_label: Label = $VBoxContainer/NetworkLoadStatusLabel

var nn_restr_dict: Dictionary[int, int]
var _web_nn_callback: Variant

var textedit_in: TextEdit
var textedit_out: TextEdit
var optionbutton_act_func_out: OptionButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# When a dataset is selected, there are restrictions about "in" and "out" neurons.
	# When this signal is emited, the dictionary with the restrictions is saved
	# on the nn menu for it to be used in the function "_check_wanted"
	SignalsObserver.establish_nn_dset_restrictions.connect(_on_restrictions_set)
	SignalsObserver.load_nn.connect(_load_network)

	for c in vboxcont.get_children():

		if c is Button:
			c.pressed.connect(_on_button_pressed.bind(c.name))

		elif c is HBoxContainer:

			if c.name == "NewNeuronsLayer":
				# The NewNeuronsLayer must have no preloaded submenus
				for child in c.get_children():
					c.remove_child(child)
					child.queue_free()

			else:
				var plus_button: Button = c.get_node("VBoxContainer").get_node("PlusButton")
				var minus_button: Button = c.get_node("VBoxContainer").get_node("MinusButton")
				var text_edit: TextEdit = c.get_node("TextEdit")

				plus_button.pressed.connect(_on_plus_pressed.bind(c))
				minus_button.pressed.connect(_on_minus_pressed.bind(c))
				text_edit.text_changed.connect(_on_text_changed.bind(c))

				if c.name == "NeuronsIn":

					textedit_in = text_edit

				if c.name == "NeuronsOut":

					textedit_out = text_edit

					optionbutton_act_func_out = c.get_node("VBoxContainer2").get_node("OptionButton")
					optionbutton_act_func_out.item_selected.connect(_on_output_activation_selected)
					if Variables.nn.nn_func_tmp_dict.has(-1):
						_select_output_activation_by_id(Variables.nn.nn_func_tmp_dict[-1])



func _on_button_pressed(which: String) -> void:
	print("[LOG] Signal 'create nn menu button' emited by %s" % which)
	match which:
		"LoadButton":
			SignalsObserver.load_nn.emit()
		"ReloadButton":
			SignalsObserver.reload_nn.emit()
			print(Variables.nn.nn_tmp_dict)  #debug
			print(Variables.nn.nn_func_tmp_dict)  #debug
		"StartButton": 
			SignalsObserver.reload_nn.emit()
			SignalsObserver.train_nn.emit()
			visible = false			#print(Variables.nn.nn_tmp_dict)  #debug


func _load_network() -> void:
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		_load_network_from_browser()
		return

	var file_dialog := FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray(["*.onnx, *.nnef ; Neural Network Files"])

	if "use_native_dialog" in file_dialog:
		file_dialog.use_native_dialog = true

	file_dialog.file_selected.connect(func(file_path: String):
		_import_network(file_path)
		file_dialog.queue_free()
	)

	file_dialog.canceled.connect(func():
		file_dialog.queue_free()
	)

	add_child(file_dialog)
	file_dialog.popup_centered_ratio(0.4)


func _load_network_from_browser() -> void:
	var js_bridge = Engine.get_singleton("JavaScriptBridge")
	_web_nn_callback = js_bridge.create_callback(_on_web_network_loaded)
	js_bridge.get_interface("window").godotNnUploadCallback = _web_nn_callback

	js_bridge.eval(
		"""
		(function () {
			const input = document.createElement("input");
			input.type = "file";
			input.accept = ".onnx,.nnef";
			input.style.display = "none";
			input.addEventListener("change", function () {
				const file = input.files && input.files[0];
				if (!file) {
					input.remove();
					return;
				}
				const reader = new FileReader();
				reader.onload = function (event) {
					window.godotNnUploadCallback(event.target.result, file.name);
					input.remove();
				};
				reader.onerror = function () {
					window.godotNnUploadCallback("", file.name, "No se pudo leer el archivo.");
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


func _on_web_network_loaded(args: Array) -> void:
	if args.size() >= 3 and not str(args[2]).is_empty():
		_show_network_load_error(str(args[2]))
		return

	if args.size() < 2 or str(args[0]).is_empty() or str(args[1]).is_empty():
		_show_network_load_error("No se seleccionó ninguna red.")
		return

	var display_name := str(args[1])
	var extension := display_name.get_extension().to_lower()
	var temp_path := "user://selected_network.%s" % extension
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		_show_network_load_error("Error preparando la red: %d" % FileAccess.get_open_error())
		return

	file.store_string(str(args[0]))
	file.close()
	_import_network(temp_path, display_name)


func _import_network(file_path: String, display_name: String = "") -> void:
	var extension := file_path.get_extension().to_lower()
	var result: Dictionary

	match extension:
		"onnx":
			result = ONNXImporter.new().import_network(file_path)
		"nnef":
			result = NNEFImporter.new().import_network(file_path)
		_:
			_show_network_load_error("Formato de red no soportado: .%s" % extension)
			return

	if not result.get("ok", false):
		_show_network_load_error(str(result.get("message", "No se pudo cargar la red.")))
		return

	var imported_weights := _to_typed_weight_dict(result.get("weights", {}))
	var restriction_error := _get_network_restriction_error(imported_weights)
	if not restriction_error.is_empty():
		_show_network_load_error(restriction_error)
		return

	Variables.nn.nn_tmp_dict = imported_weights
	Variables.nn.nn_func_tmp_dict = _to_typed_activation_dict(result.get("activations", {}))
	var imported_biases: Dictionary = result.get("biases", {})
	if imported_biases.is_empty():
		Variables.nn.reset_biases_tmp_to_random()
	else:
		Variables.nn.nn_bias_tmp_dict = _to_typed_bias_dict(imported_biases)
	if not Variables.nn.nn_func_tmp_dict.has(-1):
		Variables.nn.nn_func_tmp_dict[-1] = Constants.ACT_FUNCS.identity

	if Variables.nn.nn_func_tmp_dict.has(-1):
		var output_activation_index := optionbutton_act_func_out.get_item_index(Variables.nn.nn_func_tmp_dict[-1])
		if output_activation_index >= 0:
			optionbutton_act_func_out.select(output_activation_index)

	SignalsObserver.reload_nn.emit.call_deferred()

	if display_name.is_empty():
		display_name = file_path.get_file()
	_show_network_load_success("Red cargada correctamente: %s" % display_name)


func _get_network_restriction_error(imported_weights: Dictionary[int, Array]) -> String:
	if nn_restr_dict.has(0):
		if not imported_weights.has(0):
			return "La red cargada no contiene capa de entrada."

		var expected_inputs: int = nn_restr_dict[0]
		var imported_inputs := imported_weights[0].size()
		if imported_inputs != expected_inputs:
			return "La red cargada tiene %d neuronas de entrada, pero el dataset requiere %d." % [imported_inputs, expected_inputs]

	if nn_restr_dict.has(-1):
		if not imported_weights.has(-1):
			return "La red cargada no contiene capa de salida."

		var expected_outputs: int = nn_restr_dict[-1]
		var imported_outputs := imported_weights[-1].size()
		if imported_outputs != expected_outputs:
			return "La red cargada tiene %d neuronas de salida, pero el dataset requiere %d." % [imported_outputs, expected_outputs]

	return ""


func _show_network_load_error(message: String) -> void:
	_show_network_load_status(message, true)


func _show_network_load_success(message: String) -> void:
	_show_network_load_status(message, false)


func _show_network_load_status(message: String, is_error: bool) -> void:
	network_load_status_label.text = message
	network_load_status_label.modulate = Color(1.0, 0.25, 0.25) if is_error else Color(0.25, 0.85, 0.35)
	network_load_status_label.visible = true
	if is_error:
		push_error(message)
	else:
		print("[LOG] %s" % message)


func _to_typed_weight_dict(source: Dictionary) -> Dictionary[int, Array]:
	var result: Dictionary[int, Array] = {}
	for key in source.keys():
		result[int(key)] = source[key]
	return result


func _to_typed_activation_dict(source: Dictionary) -> Dictionary[int, int]:
	var result: Dictionary[int, int] = {}
	for key in source.keys():
		result[int(key)] = int(source[key])
	return result


func _to_typed_bias_dict(source: Dictionary) -> Dictionary[int, Array]:
	var result: Dictionary[int, Array] = {}
	for key in source.keys():
		result[int(key)] = source[key]
	return result


## When the text is changed, there must change 1 or 2 things.
## Allways must change the dictionary "Variables.nn" respecting
## the limitations of each TextEdit,
## and in the case of a change in the number of layers, there must
## be changed the number of children of "NewNeuronsLayer".
func _on_text_changed(which: HBoxContainer) -> void:

	var submenu_name: String = which.name
	var textedit: TextEdit = which.get_child(1)
	if textedit.text == "":
		return
	var num_of_wanted_layers: int = int(textedit.text)

	match submenu_name:
		"NeuronsIn":

			num_of_wanted_layers = _check_wanted(num_of_wanted_layers, textedit, 1, 0)
			Variables.nn.set_layer_neuron_count_tmp(0, num_of_wanted_layers)
			_update_nn()

		"NeuronsOut":

			num_of_wanted_layers = _check_wanted(num_of_wanted_layers, textedit, 1, -1)
			Variables.nn.set_layer_neuron_count_tmp(-1, num_of_wanted_layers)
			_update_nn()

		"Layers":

			num_of_wanted_layers = _check_wanted(num_of_wanted_layers, textedit, 0)
			
			var old_num_of_hidden_layers: int = Variables.nn.nn_tmp_dict.size() - 2  # Minus the in-layer and out-layer

			# Because the number can be changed by hand (not peressing the plus and minus)
			# the amount of times that the change must be called is not predecible
			var num_of_neurons_changed: int = num_of_wanted_layers - old_num_of_hidden_layers

			# If new layers where added
			if num_of_neurons_changed > 0:

				# The range must be iterated in reverse because the childs must be added in order.
				# And because we have the amount of neurons wanted, is easier to just subtract to that
				# number a decreasing amount of neurons that must be changed instead of add one by one
				# checking with an "if" if the number is enough.
				for current_neurons_left_to_add in range(num_of_neurons_changed, 0, -1):

					# For each submenu, its index is the amount of neurons before it beeing added
					# (because its index is -1 the id of the neuron, that starts in 1 instead of 0
					# (because the 0 is for the in-layer, that is not a hidden-one)),
					# or what is the same: neurons_now = neurons_wanted - neurons_left_to_add
					var new_submenu_index: int = num_of_wanted_layers - current_neurons_left_to_add
					var new_submenu_neuron_id: int = new_submenu_index + 1

					# A submenu of neurons in that layer is created
					var submenu_neurons_in_layer: NeuronsInLayer = NeuronsInLayer.newone(new_submenu_neuron_id)

					# And added as child
					new_neurons_layer.add_child(submenu_neurons_in_layer)

					# The weights matrix is synchronized centrally in Variables.

			# If layers were deleted
			elif num_of_neurons_changed < 0:

				num_of_neurons_changed *= -1

				print("num_of_neurons_changed ", num_of_neurons_changed)  #debug
				for current_neurons_left_to_remove in range(num_of_neurons_changed, 0, -1):
					print("current_neurons_left_to_remove ", current_neurons_left_to_remove)  #debug

					var submenu_index_to_remove: int = num_of_wanted_layers + current_neurons_left_to_remove - 1

					# Each subnmenu's index $n$ corresponds to a neuron id $n+1$: submenu 0 -> neuron id 1
					# when removing a neuron, the variable "num" (num of neurons) is equal to the index
					# of the layer that is needed to be deleted.
					# Thats why the "get_child" uses "num" as the index
					var submenu_neurons_in_layer_to_remove: NeuronsInLayer = new_neurons_layer.get_child(submenu_index_to_remove)

					# Then the child is removed from the parent and deleted from the scene
					new_neurons_layer.remove_child(submenu_neurons_in_layer_to_remove)
					submenu_neurons_in_layer_to_remove.queue_free()

					# The weights matrix is synchronized centrally in Variables.

			else:
				# This print is only to check if the "text_changed" signal is emited
				# even if the text is "changed" to be the same.
				print("[LOG] The number of neurons to wich the text changed its the same")  #debug

			Variables.nn.set_hidden_layer_count_tmp(num_of_wanted_layers)
			_update_nn()
	

func _check_wanted(wanted: int, txtedt: TextEdit, minimum: int, is_in_or_out: int = 1) -> int:

	# If there are restrictions aplyed to layers 0 or -1, here are aplyed
	if nn_restr_dict.has(is_in_or_out):
		txtedt.text = str(nn_restr_dict[is_in_or_out])
		return nn_restr_dict[is_in_or_out]

	# There can't be less than a neuron, and less than 0 layers
	if wanted < minimum:
		txtedt.text = str(minimum)
		return minimum

	# There can't be more than Constants.NN_LIMITS.max_neurons neurons, and more than Constants.NN_LIMITS.max_layers layers
	if wanted > Constants.NN_LIMITS.max_neurons:
		txtedt.text = str(Constants.NN_LIMITS.max_neurons)
		return Constants.NN_LIMITS.max_neurons
	
	return wanted


func _on_plus_pressed(which: HBoxContainer) -> void:

	var submenu_name: String = which.name
	var textedit: TextEdit = which.get_child(1)
	var num: int = int(textedit.text)


	match submenu_name:
		"Layers":  # There can be no more that Constants.NN_LIMITS.max_layers layers
			if num < Constants.NN_LIMITS.max_layers:
				textedit.text = str(num + 1 )
				textedit.text_changed.emit()
		_:  # The number of neurons of in-layer and out-layer cant be more than Constants.NN_LIMITS.max_neurons
			if num < Constants.NN_LIMITS.max_neurons:
				textedit.text = str(num + 1 )
				textedit.text_changed.emit()


func _on_minus_pressed(which: HBoxContainer) -> void:

	var submenu_name: String = which.name
	var textedit: TextEdit = which.get_child(1)
	var num: int = int(textedit.text)


	match submenu_name:
		"Layers":  # There can be no hidden layers
			if num > 0:
				textedit.text = str(num - 1 )
				textedit.text_changed.emit()
		_:  # The number of neurons of in-layer and out-layer cant be less than 1
			if num > 1:
				textedit.text = str(num - 1 )
				textedit.text_changed.emit()


func _on_output_activation_selected(activation_index: int) -> void:
	var activation_func_id: int = optionbutton_act_func_out.get_item_id(activation_index)
	Variables.nn.set_layer_activation_tmp(-1, activation_func_id)
	_update_nn()


func _select_output_activation_by_id(activation_func_id: int) -> void:
	var activation_index: int = optionbutton_act_func_out.get_item_index(activation_func_id)
	if activation_index >= 0:
		optionbutton_act_func_out.select(activation_index)


func _on_restrictions_set(nn_restr: Dictionary[int, int]) -> void:

	# Save the dictionary for the restrictions to be aplyed
	# if the user tries to change them
	nn_restr_dict = nn_restr.duplicate()

	if nn_restr.has(0):
		textedit_in.text = str(nn_restr[0])
		textedit_in.text_changed.emit()

	if nn_restr.has(-1):
		textedit_out.text = str(nn_restr[-1])
		textedit_out.text_changed.emit()
	
		if nn_restr.has(-2):
			var restricted_activation: int = int(nn_restr[-2])
			Variables.nn.set_layer_activation_tmp(-1, restricted_activation)
			_select_output_activation_by_id(restricted_activation)
			optionbutton_act_func_out.disabled = true

	SignalsObserver.reload_nn.emit.call_deferred()

func _update_nn() -> void:
	SignalsObserver.reload_nn.emit.call_deferred()
