class_name LatexFormula extends TextureRect

@export var formula: String = ""
var text_color: Color = Color.WHITE
var resolution_scale: float = 10.0  # Cambiado a float para el cargador SVG
var _web_element_id: String = ""
var _has_web_position: bool = false
var _last_web_rect: Rect2
var _last_web_viewport_size: Vector2

@onready var _http: HTTPRequest = $HTTPRequest


static func newone(latex_text: String, color: Color = Color.WHITE) -> LatexFormula:
	# Asegúrate de que la ruta en Constants sea correcta
	var new_latexformula: LatexFormula = preload(Constants.SCENES.latex_formula).instantiate()
	new_latexformula.formula = latex_text
	new_latexformula.text_color = color
	return new_latexformula


func _ready() -> void:
	_web_element_id = "godot-latex-formula-%s" % get_instance_id()
	set_process(_uses_web_mathjax())

	if _uses_web_mathjax():
		texture = null
		if not formula.is_empty():
			request_formula(formula)
		return

	# Conexión segura
	if not _http.request_completed.is_connected(_on_request_completed):
		_http.request_completed.connect(_on_request_completed)
	
	if not formula.is_empty():
		request_formula(formula)


func request_formula(latex_string: String) -> void:
	formula = latex_string
	
	# Si el nodo aún no está en el árbol, esperamos al _ready
	if not is_inside_tree():
		return

	if _uses_web_mathjax():
		texture = null
		_render_formula_with_mathjax()
		return

	var encoded_formula = formula.uri_encode()
	# La escala en la URL afecta al ViewBox del SVG, pero no a la rasterización en Godot
	var url = "https://math.vercel.app/?from=%s" % [encoded_formula]
	
	var error = _http.request(url)
	if error != OK:
		push_error("LatexFormula: Error al iniciar petición HTTP.")


func reset_sprite() -> void:
	formula = ""
	texture = null
	if _uses_web_mathjax():
		_has_web_position = false
		_hide_web_formula()
	#centered = true
	#offset = Vector2.ZERO


func _process(_delta: float) -> void:
	if _uses_web_mathjax() and not formula.is_empty():
		_update_web_formula_position()


func _exit_tree() -> void:
	if _uses_web_mathjax():
		_remove_web_formula()


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		push_error("LatexFormula: API error %d" % response_code)
		return
		
	var svg_text = body.get_string_from_utf8()
	
	# Procesamiento de color
	var hex_color = "#" + text_color.to_html(false)
	svg_text = svg_text.replace("currentColor", hex_color)
	# Algunas APIs usan fill="#000", otras fill="black"
	svg_text = svg_text.replace("fill=\"black\"", "fill=\"" + hex_color + "\"")
	svg_text = svg_text.replace("fill=\"#000\"", "fill=\"" + hex_color + "\"")
	
	var image = Image.new()
	# CRÍTICO: Aplicar resolution_scale aquí para evitar que se vea pixelado
	var err = image.load_svg_from_string(svg_text, resolution_scale)
	
	if err == OK:
		texture = ImageTexture.create_from_image(image)
		#centered = false
		#offset.y = -texture.get_height() / 2.0
	else:
		push_error("LatexFormula: Error al parsear SVG. Verifica si el SVG es válido.")


func _uses_web_mathjax() -> bool:
	return OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge")


func _render_formula_with_mathjax() -> void:
	var js_bridge = Engine.get_singleton("JavaScriptBridge")
	var js := """
(function () {
	const id = %s;
	const latex = %s;
	const color = %s;
	let element = document.getElementById(id);
	if (!element) {
		element = document.createElement("div");
		element.id = id;
		element.style.position = "absolute";
		element.style.pointerEvents = "none";
		element.style.zIndex = "20";
		element.style.overflow = "visible";
		element.style.textAlign = "left";
		document.body.appendChild(element);
	}
	element.style.display = latex ? "block" : "none";
	element.style.color = color;
	element.textContent = "\\[" + latex + "\\]";
	const typeset = function () {
		if (!window.MathJax || !MathJax.typesetPromise) {
			window.setTimeout(typeset, 50);
			return;
		}
		if (MathJax.typesetClear) {
			MathJax.typesetClear([element]);
		}
		MathJax.typesetPromise([element]);
	};
	typeset();
})();
""" % [JSON.stringify(_web_element_id), JSON.stringify(formula), JSON.stringify("#" + text_color.to_html(false))]
	js_bridge.eval(js, true)
	_update_web_formula_position(true)


func _update_web_formula_position(force_update: bool = false) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var rect := get_global_rect()
	if not force_update and _has_web_position and rect == _last_web_rect and viewport_size == _last_web_viewport_size:
		return

	_has_web_position = true
	_last_web_rect = rect
	_last_web_viewport_size = viewport_size

	var js_bridge = Engine.get_singleton("JavaScriptBridge")
	var js := """
(function () {
	const element = document.getElementById(%s);
	const canvas = document.querySelector("canvas");
	if (!element || !canvas) {
		return;
	}
	const canvasRect = canvas.getBoundingClientRect();
	const scaleX = canvasRect.width / %f;
	const scaleY = canvasRect.height / %f;
	element.style.left = (canvasRect.left + %f * scaleX) + "px";
	element.style.top = (canvasRect.top + %f * scaleY) + "px";
	element.style.width = (%f * scaleX) + "px";
	element.style.minHeight = (%f * scaleY) + "px";
	element.style.fontSize = (16 * scaleY) + "px";
})();
""" % [JSON.stringify(_web_element_id), viewport_size.x, viewport_size.y, rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	js_bridge.eval(js, true)


func _hide_web_formula() -> void:
	var js_bridge = Engine.get_singleton("JavaScriptBridge")
	var js := """
(function () {
	const element = document.getElementById(%s);
	if (element) {
		element.style.display = "none";
	}
})();
""" % JSON.stringify(_web_element_id)
	js_bridge.eval(js, true)


func _remove_web_formula() -> void:
	var js_bridge = Engine.get_singleton("JavaScriptBridge")
	var js := """
(function () {
	const element = document.getElementById(%s);
	if (element) {
		element.remove();
	}
})();
""" % JSON.stringify(_web_element_id)
	js_bridge.eval(js, true)
