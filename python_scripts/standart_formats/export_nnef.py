import torch
import torch.nn as nn
import os

class SimpleLinear(nn.Module):
    def __init__(self):
        super().__init__()
        self.linear = nn.Linear(3, 1, bias=True)
        # Pesos: [2, 2, -1], Bias: [0]
        self.linear.weight.data = torch.tensor([[2.0, 2.0, -1.0]])
        self.linear.bias.data = torch.tensor([0.0])

    def forward(self, x):
        return self.linear(x)

model = SimpleLinear()
model.eval()
# Paso 1: Exportar a ONNX como intermediario
onnx_path = 'network_nnef_temp.onnx'
torch.onnx.export(
    model,
    torch.randn(1, 3),
    onnx_path,
    input_names=['input'],
    output_names=['output'],
    opset_version=17
)

# Paso 2: Convertir ONNX a NNEF usando nnef-tools
nnef_path = 'new_network.nnef'

try:
    from nnef_tools.conversion import convert
    convert(
        input_model=onnx_path,
        output_model=nnef_path,
        input_format='onnx',
        output_format='nnef'
    )
    print(f"Modelo exportado a {nnef_path}")
except ImportError:
    # Alternativa: generar NNEF manualmente como texto
    nnef_content = """# NNEF graph definition
version 1.0;

graph simple_linear(
    input: tensor<1, 3>
) -> (output: tensor<1, 1>)
{
    weights = constant<1, 3>(data = [2.0, 2.0, -1.0]);
    bias = constant<1>(data = [0.0]);
    output = matmul(input, transpose(weights)) + bias;
}
"""
    with open(nnef_path, 'w') as f:
        f.write(nnef_content)
    print(f"Modelo exportado a {nnef_path} (formato manual)")

# Limpiar archivo temporal
if os.path.exists(onnx_path):
    os.remove(onnx_path)
