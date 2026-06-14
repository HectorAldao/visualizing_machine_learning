import torch
import torch.nn as nn
import onnx

class SimpleLinear(nn.Module):
    def __init__(self):
        super().__init__()
        self.linear = nn.Linear(3, 1, bias=True)
        # Pesos: [2, 2, -1], Bias: [1]
        self.linear.weight.data = torch.tensor([[2.0, 2.0, -1.0]])
        self.linear.bias.data = torch.tensor([1.0])

    def forward(self, x):
        return self.linear(x)

model = SimpleLinear()
model.eval()

dummy_input = torch.randn(1, 3)
onnx_path = 'new_network.onnx'

torch.onnx.export(
    model,
    dummy_input,
    onnx_path,
    input_names=['input'],
    output_names=['output'],
    dynamic_axes={'input': {0: 'batch'}, 'output': {0: 'batch'}},
    opset_version=17
)

print(f"Modelo exportado a {onnx_path}")

# Verificar
onnx_model = onnx.load(onnx_path)
onnx.checker.check_model(onnx_model)
print("Modelo ONNX verificado correctamente")
