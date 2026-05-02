import os
import onnx

def check_onnx_model(file_path):
    try:
        # Cargar el modelo
        model = onnx.load(file_path)

        # Verificar que el grafo sea válido (nodos, entradas, salidas, etc.)
        onnx.checker.check_model(model)
        
        print(f"Éxito: El archivo '{file_path}' se ha importado y verificado correctamente.")
        
    except Exception as e:
        print(f"Error: No se pudo cargar el modelo. Detalle: {e}")

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    check_onnx_model("network.onnx")
