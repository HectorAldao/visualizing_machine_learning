import torch
import torch.nn as nn
import torch.optim as optim
import pandas as pd
from torch.utils.data import DataLoader, TensorDataset

# Carga y preparación de datos
def load_data(file_path):
    # Carga el CSV situado en la misma carpeta
    df = pd.read_csv(file_path)
    
    # Convertimos a tensores de tipo float32
    # .iloc[:, 0:3] selecciona las primeras 3 columnas (entradas)
    # .iloc[:, 3] selecciona la cuarta columna (salida)
    inputs = torch.tensor(df.iloc[:, 0:3].values, dtype=torch.float32)
    targets = torch.tensor(df.iloc[:, 3].values, dtype=torch.float32).view(-1, 1)
    
    return inputs, targets

# Definición del modelo (sin bias)
class SimpleNet(nn.Module):
    def __init__(self):
        super(SimpleNet, self).__init__()
        self.linear = nn.Linear(3, 1)
        
    def forward(self, x):
        return self.linear(x)

# --- Ejecución ---

# Nombre del archivo en la misma carpeta
csv_filename = 'datos_generados.csv' 

try:
    X, Y = load_data(csv_filename)
    dataset = TensorDataset(X, Y)
    loader = DataLoader(dataset, batch_size=2, shuffle=True)

    model = SimpleNet()
    criterion = nn.MSELoss()
    optimizer = optim.SGD(model.parameters(), lr=0.01)

    # Bucle de entrenamiento
    for epoch in range(20):
        for batch_x, batch_y in loader:
            outputs = model(batch_x)
            loss = criterion(outputs, batch_y)
            
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            
        if (epoch + 1) % 10 == 0:
            print(f'Epoch [{epoch+1}/50], Loss: {loss.item():.4f}')

    print("\nPesos finales del modelo:")
    print(model.linear.weight.data)
    print("\nBias final del modelo:")
    print(model.linear.bias.data)

except FileNotFoundError:
    print(f"Error: No se encontró el archivo '{csv_filename}' en la carpeta actual.")
