import numpy as np
import pandas as pd
from datetime import datetime, timedelta

np.random.seed(42)

# Parámetros de simulación
data_size = 1000
start_time = datetime(2026, 4, 1, 8, 0, 0)

# Simulación de datos fisiológicos
heart_rate = np.random.normal(loc=75, scale=10, size=data_size)  # lpm
blood_pressure = np.random.normal(loc=120, scale=15, size=data_size)  # mmHg
spo2 = np.random.normal(loc=97, scale=2, size=data_size)  # % oxígeno

# Simulación de timestamps
timestamps = [start_time + timedelta(minutes=i) for i in range(data_size)]

# Patrón realista: mayor riesgo si FC > 100, PA > 140, SpO2 < 93
risk = ((heart_rate > 100).astype(int) + (blood_pressure > 140).astype(int) + (spo2 < 93).astype(int))

# Probabilidad base de infarto
base_prob = 0.03
# Aumenta la probabilidad si hay factores de riesgo
infarto_prob = base_prob + 0.25 * (risk > 0) + 0.4 * (risk > 1)

# Generar columna objetivo (1=infarto en los próximos 40 min, 0=no)
infarto = (np.random.rand(data_size) < infarto_prob).astype(int)

# Crear DataFrame
sim_data = pd.DataFrame({
    'timestamp': [t.strftime('%Y-%m-%d %H:%M:%S') for t in timestamps],
    'heart_rate': np.round(heart_rate, 1),
    'blood_pressure': np.round(blood_pressure, 1),
    'spo2': np.round(spo2, 1),
    'infarto_40min': infarto
})

# Guardar a CSV
sim_data.to_csv('datos_entrenamiento_infarto.csv', index=False)

print('Archivo datos_entrenamiento_infarto.csv generado con 1000 filas.')
