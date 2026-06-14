import os
import onnx
from onnx import numpy_helper

def check_onnx_model(file_path):
    try:
        # Cargar el modelo
        model = onnx.load(file_path)

        # Verificar que el grafo sea válido (nodos, entradas, salidas, etc.)
        onnx.checker.check_model(model)
         
        print(f"Éxito: El archivo '{file_path}' se ha importado y verificado correctamente.")

        for initializer in model.graph.initializer:
            values = numpy_helper.to_array(initializer)
            print(f"\n{initializer.name}:")
            print(values)
         
    except Exception as e:
        print(f"Error: No se pudo cargar el modelo. Detalle: {e}")

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    check_onnx_model("network.onnx")
