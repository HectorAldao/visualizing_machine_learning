class_name LatexRenderer
extends TextureRect

signal render_completed(latex: String, raster_scale: float)
signal render_failed(latex: String, error: String)

const BRIDGE_CLASS := "LatexSvgGenerator"
const _GDEXTENSION := preload("res://addons/latex_renderer/latex_renderer.gdextension")

static var _texture_cache: Dictionary = {}

@export_multiline var formula: String = "":
	set(value):
		if formula == value:
			return
		formula = value
		_request_render()
	get:
		return formula

@export_range(0.05, 64.0, 0.05, "or_greater") var resolution_scale: float = 4.0:
	set(value):
		var next_scale := max(value, 0.05)
		if is_equal_approx(resolution_scale, next_scale):
			return
		resolution_scale = next_scale
		_request_render()
	get:
		return resolution_scale

@export var formula_color: Color = Color.WHITE:
	set(value):
		formula_color = value
		self_modulate = formula_color
	get:
		return formula_color

@export_range(0.0, 256.0, 0.01, "or_greater") var svg_font_size: float = 40.0:
	set(value):
		var next_size := clamp(value, 0.0, 256.0)
		if is_equal_approx(svg_font_size, next_size):
			return
		svg_font_size = next_size
		_request_render()
	get:
		return svg_font_size

@export_range(0.0, 128.0, 1.0, "or_greater") var svg_padding: float = 10.0:
	set(value):
		var next_padding := clamp(value, 0.0, 128.0)
		if is_equal_approx(svg_padding, next_padding):
			return
		svg_padding = next_padding
		_request_render()
	get:
		return svg_padding

@export var fit_control_to_formula: bool = true
@export var force_synchronous: bool = false

var text_color: Color:
	set(value):
		formula_color = value
	get:
		return formula_color

var _request_serial: int = 0
var _active_task_ids: Array[int] = []


func _ready() -> void:
	self_modulate = formula_color
	set_process(false)
	if not formula.strip_edges().is_empty():
		_request_render()


func _process(_delta: float) -> void:
	for index in range(_active_task_ids.size() - 1, -1, -1):
		var task_id := _active_task_ids[index]
		if WorkerThreadPool.is_task_completed(task_id):
			WorkerThreadPool.wait_for_task_completion(task_id)
			_active_task_ids.remove_at(index)

	if _active_task_ids.is_empty():
		set_process(false)


func _exit_tree() -> void:
	for task_id in _active_task_ids:
		WorkerThreadPool.wait_for_task_completion(task_id)
	_active_task_ids.clear()


func request_formula(latex_string: String) -> void:
	formula = latex_string


func set_formula(latex_string: String) -> void:
	formula = latex_string


func set_formula_color(color: Color) -> void:
	formula_color = color


func set_resolution_scale(scale: float) -> void:
	resolution_scale = scale


func rerender() -> void:
	_request_render(true)


func reset_sprite() -> void:
	_request_serial += 1
	formula = ""
	texture = null
	custom_minimum_size = Vector2.ZERO


static func clear_cache() -> void:
	_texture_cache.clear()


func _request_render(skip_cache: bool = false) -> void:
	if not is_inside_tree():
		return

	_request_serial += 1
	var serial := _request_serial
	var latex := formula.strip_edges()

	if latex.is_empty():
		texture = null
		custom_minimum_size = Vector2.ZERO
		return

	var raster_scale := max(resolution_scale, 0.05)
	var cache_key := _make_cache_key(latex, raster_scale, svg_font_size, svg_padding)

	if not skip_cache and _texture_cache.has(cache_key):
		texture = _texture_cache[cache_key]
		_update_minimum_size(texture as Texture2D, raster_scale)
		render_completed.emit(latex, raster_scale)
		return

	if _should_use_worker_pool():
		var node_ref: WeakRef = weakref(self)
		var task_id := WorkerThreadPool.add_task(func() -> void:
			var result := _build_image(latex, raster_scale, svg_font_size, svg_padding)
			var node: Object = node_ref.get_ref()
			if node != null:
				node.call_deferred("_apply_render_result", serial, cache_key, latex, raster_scale, result)
		, false, "LatexRenderer formula rasterization")

		if task_id >= 0:
			_active_task_ids.append(task_id)
			set_process(true)
			return

	var result := _build_image(latex, raster_scale, svg_font_size, svg_padding)
	_apply_render_result(serial, cache_key, latex, raster_scale, result)


func _should_use_worker_pool() -> bool:
	if force_synchronous:
		return false
	if OS.has_feature("web") and not OS.has_feature("threads"):
		return false
	if OS.has_feature("nothreads"):
		return false
	return true


func _apply_render_result(serial: int, cache_key: String, latex: String, raster_scale: float, result: Dictionary) -> void:
	if serial != _request_serial:
		return

	if not result.get("ok", false):
		var error := str(result.get("error", "Unknown LaTeX render error"))
		push_error("LatexRenderer: " + error)
		render_failed.emit(latex, error)
		return

	var image: Image = result["image"]
	var image_texture := ImageTexture.create_from_image(image)
	_texture_cache[cache_key] = image_texture
	texture = image_texture
	_update_minimum_size(image_texture, raster_scale)
	render_completed.emit(latex, raster_scale)


func _update_minimum_size(image_texture: Texture2D, raster_scale: float) -> void:
	if not fit_control_to_formula or image_texture == null:
		return
	custom_minimum_size = image_texture.get_size() / max(raster_scale, 0.05)


static func _build_image(latex: String, raster_scale: float, font_size: float, padding: float) -> Dictionary:
	if not ClassDB.class_exists(BRIDGE_CLASS):
		return {
			"ok": false,
			"error": "GDExtension class %s is not loaded. Build the Rust library and enable the addon." % BRIDGE_CLASS,
		}

	var bridge: Object = ClassDB.instantiate(BRIDGE_CLASS)
	if bridge == null:
		return {"ok": false, "error": "Could not instantiate %s." % BRIDGE_CLASS}

	var svg_value: Variant = bridge.call("render_svg", latex, font_size, padding)
	if typeof(svg_value) != TYPE_STRING:
		return {"ok": false, "error": "Rust renderer returned a non-string SVG value."}

	var svg_text := String(svg_value)
	if svg_text.is_empty():
		return {"ok": false, "error": "Rust renderer returned an empty SVG string."}

	var image := Image.new()
	var error := image.load_svg_from_string(svg_text, raster_scale)
	if error != OK:
		return {"ok": false, "error": "Image.load_svg_from_string failed with error code %d." % error}

	return {"ok": true, "image": image}


static func _make_cache_key(latex: String, raster_scale: float, font_size: float, padding: float) -> String:
	return "%s\nscale=%.4f;font=%.2f;padding=%.2f" % [latex, raster_scale, font_size, padding]
