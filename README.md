# Visualizing Mahine Learning

Este trabajo de fin de grado es una aplicación web creada en Godot que permite entender de forma interactiva el funcionamiento de modelos de machine learning gracias a la implementacion de los mismos en el lenguaje del propio motor.

Concretamente, los modelos implementado son los árboles de decisión (en su forma más básica) y las redes neuronales (en su forma más básica también, el mlp)

Lo que permite la aplicación es primero ver paso a paso la evolución de los algoritmos.
En el caso del árbol, cómo se van decidiendo en base a los datos de entrada el cómo se van creando las diferentes ramas, al tiempo que se explica en una ventana la toma de decisiones con gráficas sobre la entropía de cada atributo y una explicacion de lo que esto significa.
En la red neuronal, cúales son los cálculos neurona a neurona en el forward pass, junto con animaciones de por dónde entran los datos, qué camino recorren, y explicaciones de las funciones de activación, así como el backward pass, mostrando cómo se actualizan los gradientes neurona a neurona junto con explicacioens de cómo se calcula el error.

Y después ver la evaluación de los mismos.
En el árbol, el proceso de decisión en base a las características (categóricas, no contínuas) de con qué etiqueta se clasifica cada dato.
Y en la red, el proceso de forward pass.

Gracias a que Godot permite exportar los proyectos a html5, este es desplegado en [GitHubPages en este mismo repositorio](https://hectoraldao.github.io/visualizing_machine_learning/)
