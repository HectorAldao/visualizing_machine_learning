import pandas as pd
import numpy as np
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))

n_filas = 50
np.random.seed(42)

data = {
    'luz': np.random.uniform(-1, 1, n_filas),
    'humedad': np.random.uniform(-1, 1, n_filas),
    'acidez': np.random.uniform(-1, 1, n_filas)
}

df = pd.DataFrame(data)

df['crecimiento'] = 2 * df['luz'] + 2 * df['humedad'] - df['acidez'] + 1

nombre_archivo = 'datos_generados.csv'
df.to_csv(nombre_archivo, index=False)

print(df.head())
