class_name LatexFormula extends Sprite2D

@export var formula: String = ""
var text_color: Color = Color.WHITE
var resolution_scale: float = 10.0  # Cambiado a float para el cargador SVG

@onready var _http: HTTPRequest = $HTTPRequest


static func newone(latex_text: String, color: Color = Color.WHITE) -> LatexFormula:
	# Asegúrate de que la ruta en Constants sea correcta
	var new_latexformula: LatexFormula = preload(Constants.SCENES.latex_formula).instantiate()
	new_latexformula.formula = latex_text
	new_latexformula.text_color = color
	return new_latexformula


func _ready() -> void:
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

	var encoded_formula = formula.uri_encode()
	# La escala en la URL afecta al ViewBox del SVG, pero no a la rasterización en Godot
	var url = "https://math.vercel.app/?from=%s" % [encoded_formula]
	
	var error = _http.request(url)
	if error != OK:
		push_error("LatexFormula: Error al iniciar petición HTTP.")


func reset_sprite() -> void:
	formula = ""
	texture = null
	centered = true
	offset = Vector2.ZERO


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
		centered = false
		offset.y = -texture.get_height() / 2.0
	else:
		push_error("LatexFormula: Error al parsear SVG. Verifica si el SVG es válido.")
