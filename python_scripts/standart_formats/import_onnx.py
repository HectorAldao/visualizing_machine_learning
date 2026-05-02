import torch
from onnx2torch import convert

# 1. Cargar y convertir el modelo ONNX a un objeto nn.Module de PyTorch
ruta_onnx = 'modelo.onnx'
model_pytorch = convert(ruta_onnx)

# 2. Poner el modelo en modo evaluación
model_pytorch.eval()

# 3. Verificar con un tensor de prueba (ejemplo para una imagen RGB de 224x224)
input_dummy = torch.randn(1, 3, 224, 224)

with torch.no_grad():
    output = model_pytorch(input_dummy)

print(f"Forma del output: {output.shape}")
