class_name EvalData extends Button


var data_dict: Dictionary
var label_column: String
var label_color: Color
var label_hex_color: String

const SATURATION_MIN: float = 1.0 / 3.0
const SATURATION_MAX: float = 2.0 / 3.0
const VALUE_MIN: float = 1.0 / 3.0
const VALUE_MAX: float = 2.0 / 3.0
const HUE_WINDOW: float = 1.0 / 18.0
const LABEL_COLOR_NAMES: Dictionary = {
	"red": 0.0,
	"rojo": 0.0,
	"green": 1.0 / 3.0,
	"verde": 1.0 / 3.0,
	"blue": 2.0 / 3.0,
	"azul": 2.0 / 3.0,
	"yellow": 1.0 / 6.0,
	"amarillo": 1.0 / 6.0,
	"purple": 5.0 / 6.0,
	"morado": 5.0 / 6.0,
	"pink": 11.0 / 12.0,
	"rosa": 11.0 / 12.0,
	"orange": 1.0 / 12.0,
	"naranja": 1.0 / 12.0,
}
const WHITE_COLOR_NAMES: Array[String] = ["white", "blanco"]
const BLACK_COLOR_NAMES: Array[String] = ["black", "negro"]


static func newone(data_dictionary: Dictionary, new_label_column: String = "") -> EvalData:
	var evaldata: EvalData = preload(Constants.SCENES.eval_data).instantiate()
	evaldata.data_dict = data_dictionary
	evaldata.label_column = new_label_column
	evaldata._apply_label_color()
	return evaldata


func get_label_hex_color() -> String:
	return label_hex_color


func _apply_label_color() -> void:
	var label_name := _get_label_name()
	label_color = _get_color_for_label(label_name)
	label_hex_color = label_color.to_html(false)

	begin_bulk_theme_override()
	_add_button_style_override(&"normal", label_color)
	_add_button_style_override(&"hover", label_color.lightened(0.12))
	_add_button_style_override(&"pressed", label_color.darkened(0.12))
	_add_button_style_override(&"hover_pressed", label_color.darkened(0.06))
	end_bulk_theme_override()


func _get_label_name() -> String:
	if label_column != "" and data_dict.has(label_column):
		return str(data_dict[label_column])
	return str(data_dict)


func _get_color_for_label(label_name: String) -> Color:
	var hash_value := _hash_string(label_name)
	var color_name := str(data_dict.get("color", "")).strip_edges().to_lower()

	if WHITE_COLOR_NAMES.has(color_name):
		var white_saturation := _hash_to_range(hash_value, 8, 0.0, 0.08)
		var white_value := _hash_to_range(hash_value, 16, 0.88, 1.0)
		return Color.from_hsv(_hash_to_unit(hash_value), white_saturation, white_value)

	if BLACK_COLOR_NAMES.has(color_name):
		var black_saturation := _hash_to_range(hash_value, 8, 0.0, 0.12)
		var black_value := _hash_to_range(hash_value, 16, 0.04, 0.16)
		return Color.from_hsv(_hash_to_unit(hash_value), black_saturation, black_value)

	var hue := _hash_to_unit(hash_value)
	if LABEL_COLOR_NAMES.has(color_name):
		hue = _wrap_unit(float(LABEL_COLOR_NAMES[color_name]) + _hash_to_range(hash_value, 0, -HUE_WINDOW, HUE_WINDOW))

	var saturation := _hash_to_range(hash_value, 8, SATURATION_MIN, SATURATION_MAX)
	var value := _hash_to_range(hash_value, 16, VALUE_MIN, VALUE_MAX)
	return Color.from_hsv(hue, saturation, value)


func _add_button_style_override(style_name: StringName, color: Color) -> void:
	var stylebox := _get_base_button_stylebox()
	stylebox.bg_color = color
	add_theme_stylebox_override(style_name, stylebox)


func _get_base_button_stylebox() -> StyleBoxFlat:
	var stylebox := get_theme_stylebox(&"normal", &"Button")
	if stylebox is StyleBoxFlat:
		return stylebox.duplicate() as StyleBoxFlat

	var fallback := StyleBoxFlat.new()
	fallback.set_corner_radius_all(10)
	fallback.set_border_width_all(1)
	fallback.border_color = Color(0.019607844, 0.003921569, 0.019607844)
	return fallback


static func _hash_string(text: String) -> int:
	var hash := 2166136261
	for i in range(text.length()):
		hash = int(hash ^ text.unicode_at(i))
		hash = int((hash * 16777619) & 0xffffffff)
	return hash


static func _hash_to_unit(hash: int, shift: int = 0) -> float:
	return float((hash >> shift) & 0xff) / 255.0


static func _hash_to_range(hash: int, shift: int, min_value: float, max_value: float) -> float:
	return lerpf(min_value, max_value, _hash_to_unit(hash, shift))


static func _wrap_unit(value: float) -> float:
	return fposmod(value, 1.0)
