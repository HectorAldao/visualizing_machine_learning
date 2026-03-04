extends Window


@onready var rich_text_label: RichTextLabel = $RichTextLabel

var selected_text: String
#var details_dict: Dictionary


#Step: training_started - { "data_size": 5, "attributes": ["color", "shape", "size"] }
#Calculating entropy for 5 samples with labels: ["apple", "apple", "banana", "banana", "orange"]
#Gain for color: 1.12192809488736
#Gain for shape: 0.97095059445467
#Gain for size: 0.97095059445467
#Best attribute selected: color with gain: 1.12192809488736
#Creating node - Type: internal, Attr: color, Label: 
#Creating branch from color with value orange
#Creating branch from color with value yellow
#Creating branch from color with value green
#Creating branch from color with value red

const template_texts: Dictionary[String, String] = {
	"internal" :
"Han bajado {numero_de_datos} datos por esta rama.
Estos {numero_de_datos} datos tenían las etiquetas {lista_etiquetas}.
En base a estas etiquetas se calcula la entropía de cada atributo de los datos.
Los datos tienen los atributos {lista_atributos}, por lo que hay que calcular {metrica_de_ganancia_de_info_1} para decidir cuál sirve para dividir los mejor.
{lista_ganancias_info}
El que tiene mejor {metrica_de_ganancia_de_info_2} es '{mejor_atributo}' con {valor_metrica_mejor_atributo}.
Las ramas que se crean a partir de '{mejor_atributo}' son:
{lista_ramas_mejor_atributo}",

	"leaf":
"Solo ha bajado {numero_de_datos} dato por esta rama.
Por lo tanto, para este conjunto de datos solo podemos asumir que los futuros datos que lleugen a esta rama tendrán la misma etiqueta: {lista_etiquetas}",

	"leaf_mayority":
"Han bajado {numero_de_datos} datos por esta rama.
Pero no quedan atributos sin recorrer para estos datos, es decir, todos los atributos han sido valorados para clasificar los datos.
Por lo que solo queda ver qué etiquetas tienen los datos resultantes.
Si todos tienen la misma etiqueta, perfecto, había datos repetidos o muy similares entre los datos, pero todos estos los clasificamos igual.
Si hay varias etiquetas, pues los atributos escogidos no sirven para diferenciar a la perfección todos los casos de nuestro conjunto de datos. Pero hay que seleccioniar una etiqueta para este nodo hoja, por lo que se escoje la etiqueta mayoritaria.
En este caso '{etiqueta_mayoritaria}'."
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func update_current_text(details_dict: Dictionary) -> void:
	match details_dict["tipo_de_nodo"]:
		"internal":
			selected_text = template_texts["internal"]
		"leaf":
			selected_text = template_texts["leaf"]
		"leaf_mayority":
			selected_text = template_texts["leaf_mayority"]
			
	rich_text_label.text = selected_text.format(details_dict)
