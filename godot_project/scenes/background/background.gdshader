shader_type canvas_item;

// Define cuántas veces quieres que se repita la textura en los ejes X e Y.
// Debes ajustar estos valores según la proporción de tu pantalla y la textura.
uniform vec2 uv_scale = vec2(2.0, 2.0);

void fragment() {
    // Multiplicar los UV por la escala hace que excedan el valor de 1.0,
    // permitiendo que el hardware aplique el modo Mirror.
    COLOR = texture(TEXTURE, UV * uv_scale);
}