import nnef

def check_nnef_model(path):
    try:
        # Carga la estructura del grafo
        # 'path' puede ser la carpeta .nnef o un archivo comprimido
        graph = nnef.load_graph(path)
        
        # Si llega aquí sin lanzar excepciones, la sintaxis del grafo es válida
        print(f"Éxito: El modelo NNEF en '{path}' se ha importado correctamente.")
        
    except Exception as e:
        print(f"Error: Fallo en la carga del modelo NNEF. Detalle: {e}")

if __name__ == "__main__":
    check_nnef_model("network.nnef")
