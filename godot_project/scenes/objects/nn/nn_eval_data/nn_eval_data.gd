class_name NnEvalData extends Label


# Attribute name used as the key when AlgorithmNn emits sample dictionaries.
var atr_name: String
# Visual channel this label belongs to: input, output or expected.
var container_role: String = "input"
# Neuron this value is visually attached to.
var target_neuron: Control

# Stable position beside the target neuron/column. Animations move away from and
# back to this point, instead of accumulating offsets over repeated samples.
var _home_position: Vector2 = Vector2.ZERO
var _tween: Tween

## Subscribes the label to training-value signals. Each label filters shared
## dictionaries by container_role and atr_name, so all visual values can travel
## through the same observer signal without leaking between containers.
func _ready() -> void:
	SignalsObserver.add_change_eval_data.connect(_on_change_nn_eval_data)
	SignalsObserver.nn_eval_data_enter_network.connect(_on_enter_network)
	SignalsObserver.clear_nn_eval_data.connect(_on_clear_nn_eval_data)
	modulate.a = 0.0

## Creates a value label already bound to the role/key pair it will display.
static func newone(new_atr_name: String, new_container_role: String = "input") -> NnEvalData:
	var evaldata: NnEvalData = preload(Constants.SCENES.nn_eval_data).instantiate()
	evaldata.atr_name = new_atr_name
	evaldata.container_role = new_container_role
	return evaldata


## Stores the neuron that should visually receive this value.
## NnEvalDataContainer uses this reference when recalculating layout.
func assign_neuron(neuron: Control) -> void:
	target_neuron = neuron


## Updates the resting position assigned by the container.
## The label is also snapped there so future animations start from a known state.
func set_home_position(new_home_position: Vector2) -> void:
	_home_position = new_home_position
	position = _home_position


## Reacts to the shared sample-value signal and ignores dictionaries that do not
## belong to this label's visual role or attribute key.
func _on_change_nn_eval_data(signal_container_role: String, dict_of_values: Dictionary, animate_appear: bool) -> void:
	if signal_container_role != container_role:
		return

	if not dict_of_values.has(atr_name):
		clear_value()
		return

	set_value(str(dict_of_values[atr_name]), animate_appear)


## Shows a new value. When animate_appear is true, the value enters from the
## left; otherwise it is placed beside the neuron immediately.
func set_value(new_value: String, animate_appear: bool = false) -> void:
	_kill_tween()
	text = format_display_value(new_value)
	visible = true

	if animate_appear:
		position = _home_position + Constants.NN_EVAL_DATA_APPEAR_OFFSET
		modulate.a = 0.0
		_tween = create_tween()
		_tween.set_parallel(true)
		_tween.tween_property(self, "position", _home_position, Constants.NN_EVAL_DATA_APPEAR_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "modulate:a", 1.0, Constants.NN_EVAL_DATA_APPEAR_FADE_TIME)
	else:
		position = _home_position
		modulate.a = 1.0


## Hides the value while keeping its attribute/neuron binding intact.
func clear_value() -> void:
	_kill_tween()
	text = ""
	modulate.a = 0.0
	position = _home_position


## Reacts only to clear messages addressed to this label's visual container.
func _on_clear_nn_eval_data(signal_container_role: String) -> void:
	if signal_container_role == container_role:
		clear_value()


## Plays the "value enters the network" animation when AlgorithmNn starts the
## forward pass for the current sample.
func _on_enter_network(signal_container_role: String) -> void:
	if signal_container_role != container_role:
		return

	animate_enter_network()


## Moves the current value rightwards and fades it out, used by input and output
## values when they visually enter/leave the network.
func animate_enter_network() -> void:
	if text.is_empty() or modulate.a <= 0.0:
		return

	_kill_tween()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", _home_position + Constants.NN_EVAL_DATA_ENTER_OFFSET, Constants.NN_EVAL_DATA_MOVE_FADE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, Constants.NN_EVAL_DATA_MOVE_FADE_TIME)


## Moves output values to the right after the full forward pass has finished.
func animate_leave_right() -> void:
	if text.is_empty() or modulate.a <= 0.0:
		return

	_kill_tween()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", _home_position + Constants.NN_EVAL_DATA_ENTER_OFFSET, Constants.NN_EVAL_DATA_MOVE_FADE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, Constants.NN_EVAL_DATA_MOVE_FADE_TIME)


## Fades out the expected target and replaces it with the error value that will
## be sent back during backpropagation.
func animate_expected_to_error(error_value: String) -> void:
	_kill_tween()
	position = _home_position
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, Constants.NN_EVAL_DATA_EXPECTED_FADE_TIME)
	_tween.finished.connect(func():
		text = format_display_value(error_value)
		reset_size()
		position = _home_position
		modulate.a = 1.0
		visible = true
	)


## Sends the error value leftwards, back toward the output layer, and fades it.
func animate_error_return_left() -> void:
	if text.is_empty() or modulate.a <= 0.0:
		return

	_kill_tween()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", _home_position + Constants.NN_EVAL_DATA_ERROR_RETURN_OFFSET, Constants.NN_EVAL_DATA_MOVE_FADE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, Constants.NN_EVAL_DATA_MOVE_FADE_TIME)


## Formats numeric values for compact display. Values are truncated, not rounded,
## so the visual text never suggests more precision than the stored value.
static func format_display_value(raw_value) -> String:
	var value_text: String = str(raw_value)
	if not value_text.is_valid_float():
		return value_text

	var value: float = float(value_text)
	var scale: float = pow(10.0, Constants.NN_EVAL_DATA_DISPLAY_DECIMALS)
	var truncated_abs: float = floor(abs(value) * scale) / scale
	var truncated_value: float = truncated_abs if value >= 0.0 else -truncated_abs
	return "%.*f" % [Constants.NN_EVAL_DATA_DISPLAY_DECIMALS, truncated_value]


## Stops any previous animation before a new sample value or movement starts.
func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
