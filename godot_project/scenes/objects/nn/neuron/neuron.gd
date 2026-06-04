class_name Neuron extends Button

var _id: int = -2
var _layer_id: int = -2


var _normal_theme: Theme
var _resalted_theme: Theme = preload(Constants.THEMES.resalted_neuron)
var _clicked_theme: Theme = preload(Constants.THEMES.clicked_neuron)
var _is_evaluated: bool = false
var _is_clicked_selected: bool = false


func _ready() -> void:
	_normal_theme = theme
	pressed.connect(_on_pressed)
	SignalsObserver.forward_step_completed.connect(_on_training_step_completed)
	SignalsObserver.backward_step_completed.connect(_on_training_step_completed)
	SignalsObserver.nn_layer_resalted.connect(_on_layer_resalted)
	SignalsObserver.train_nn.connect(_reset_evaluated_theme)
	SignalsObserver.train_nn.connect(_reset_clicked_selection)
	SignalsObserver.train_nn_next_neuron.connect(_reset_clicked_selection)
	SignalsObserver.train_nn_next_layer.connect(_reset_clicked_selection)
	SignalsObserver.train_nn_next_step.connect(_reset_evaluated_theme)
	SignalsObserver.train_nn_next_step.connect(_reset_clicked_selection)
	SignalsObserver.train_nn_complete.connect(_reset_evaluated_theme)
	SignalsObserver.train_nn_complete.connect(_reset_clicked_selection)
	SignalsObserver.nn_neuron_text_changed.connect(_on_neuron_text_changed)
	SignalsObserver.nn_clicked_neuron_changed.connect(_on_clicked_neuron_changed)
	_apply_cached_text()


static func newone(new_id: int, new_layer_id) -> Neuron:
	var new_neuron: Neuron = preload(Constants.SCENES.neuron).instantiate()
	new_neuron._id = new_id
	new_neuron._layer_id = new_layer_id
	return new_neuron


func _on_pressed() -> void:
	if _is_current_clicked_selection():
		Variables.nn_clicked_neuron_id = -1
		Variables.nn_clicked_neuron_layer_id = -9999
		SignalsObserver.nn_clicked_neuron_changed.emit(-9999, -1)
	else:
		Variables.nn_clicked_neuron_id = _id
		Variables.nn_clicked_neuron_layer_id = _layer_id
		SignalsObserver.nn_clicked_neuron_changed.emit(_layer_id, _id)

	SignalsObserver.info_neuron.emit(_id, _layer_id)


func _on_training_step_completed(layer_id: int, neuron_id: int, _value: float) -> void:
	_set_evaluated(neuron_id == _id and layer_id == _layer_id)


func _on_layer_resalted(layer_id: int) -> void:
	_set_evaluated(layer_id == _layer_id)


func _on_neuron_text_changed(layer_id: int, neuron_id: int, new_text: String) -> void:
	if layer_id != _layer_id or neuron_id != _id:
		return

	text = new_text
	print("[LOG] Neuron %d on layer %d changed text to '%s'" % [_id, _layer_id, new_text])


func _apply_cached_text() -> void:
	if has_nn_neuron_text(_layer_id, _id):
		_on_neuron_text_changed(_layer_id, _id, get_nn_neuron_text(_layer_id, _id))


func _set_evaluated(is_evaluated: bool) -> void:
	_is_evaluated = is_evaluated
	_apply_theme()


func _apply_theme() -> void:
	var target_theme: Theme = _normal_theme
	if _is_evaluated:
		target_theme = _resalted_theme
	if _is_clicked_selected:
		target_theme = _clicked_theme

	if theme != target_theme:
		theme = target_theme


func _reset_evaluated_theme() -> void:
	_set_evaluated(false)


func _on_clicked_neuron_changed(layer_id: int, neuron_id: int) -> void:
	_is_clicked_selected = layer_id == _layer_id and neuron_id == _id
	_apply_theme()


func _reset_clicked_selection(_arg1 = null, _arg2 = null, _arg3 = null) -> void:
	if Variables.nn_clicked_neuron_id == -1 and Variables.nn_clicked_neuron_layer_id == -9999:
		return

	Variables.nn_clicked_neuron_id = -1
	Variables.nn_clicked_neuron_layer_id = -9999
	SignalsObserver.nn_clicked_neuron_changed.emit(-9999, -1)


func _is_current_clicked_selection() -> bool:
	return Variables.nn_clicked_neuron_id == _id and Variables.nn_clicked_neuron_layer_id == _layer_id


func has_nn_neuron_text(layer_id: int, neuron_id: int) -> bool:
	if not Variables.nn_layer_neuron_texts.has(layer_id):
		return false

	return neuron_id >= 0 and neuron_id < Variables.nn_layer_neuron_texts[layer_id].size()


func get_nn_neuron_text(layer_id: int, neuron_id: int) -> String:
	if not has_nn_neuron_text(layer_id, neuron_id):
		return ""

	return str(Variables.nn_layer_neuron_texts[layer_id][neuron_id])
