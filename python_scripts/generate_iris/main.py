import pandas as pd
import numpy as np
import os

# Establecer el directorio de trabajo al del script
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# Parámetros de generación (500 por clase = 1500 filas en total)
n_muestras_por_clase = 1000 
np.random.seed(42)

# Generación de datos sintéticos basados en las estadísticas descriptivas de Iris (Media, Desviación Estándar)

# Longitud Sépalo,Anchura Sépalo,Longitud Pétalo,Anchura Pétalo,Tipo de Flor

# 1. Iris Setosa
setosa = pd.DataFrame({
    'Longitud Sépalo': np.random.normal(5.01, 0.35, n_muestras_por_clase),
    'Anchura Sépalo': np.random.normal(3.43, 0.38, n_muestras_por_clase),
    'Longitud Pétalo': np.random.normal(1.46, 0.17, n_muestras_por_clase),
    'Anchura Pétalo': np.random.normal(0.25, 0.10, n_muestras_por_clase),
    'Tipo de Flor': 'setosa'
})

# 2. Iris Versicolor
versicolor = pd.DataFrame({
    'Longitud Sépalo': np.random.normal(5.94, 0.51, n_muestras_por_clase),
    'Anchura Sépalo': np.random.normal(2.77, 0.31, n_muestras_por_clase),
    'Longitud Pétalo': np.random.normal(4.26, 0.47, n_muestras_por_clase),
    'Anchura Pétalo': np.random.normal(1.33, 0.20, n_muestras_por_clase),
    'Tipo de Flor': 'versicolor'
})

# 3. Iris Virginica
virginica = pd.DataFrame({
    'Longitud Sépalo': np.random.normal(6.59, 0.63, n_muestras_por_clase),
    'Anchura Sépalo': np.random.normal(2.97, 0.32, n_muestras_por_clase),
    'Longitud Pétalo': np.random.normal(5.55, 0.55, n_muestras_por_clase),
    'Anchura Pétalo': np.random.normal(2.03, 0.27, n_muestras_por_clase),
    'Tipo de Flor': 'virginica'
})

# Concatenar todos los subconjuntos
df = pd.concat([setosa, versicolor, virginica], ignore_index=True)

# Mezclar las filas aleatoriamente para que las eTipo de Flor no estén ordenadas
df = df.sample(frac=1, random_state=42).reset_index(drop=True)

# Truncar posibles valores negativos generados por la distribución normal
columnas_numericas = ['Longitud Sépalo', 'Anchura Sépalo', 'Longitud Pétalo', 'Anchura Pétalo']
df[columnas_numericas] = df[columnas_numericas].clip(lower=0.1)

# Redondear a 1 decimal para mantener el formato del dataset original
df[columnas_numericas] = df[columnas_numericas].round(1)

# Guardar en CSV
nombre_archivo = 'iris_sintetico_extendido.csv'
df.to_csv(nombre_archivo, index=False)

print(f"Dataset generado con {len(df)} filas.")
print(df.head())
