import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
import joblib
import os

def load_csv_data(csv_path):
    """Carga los datos del CSV generado por el monitor cardiaco."""
    df = pd.read_csv(csv_path)
    # Asegura que los datos sean numéricos donde corresponde
    df['bpm'] = pd.to_numeric(df['bpm'], errors='coerce').fillna(0)
    df['amp'] = pd.to_numeric(df['amp'], errors='coerce').fillna(0)
    df['raw'] = pd.to_numeric(df['raw'], errors='coerce').fillna(0)
    return df

def extract_features(df, window_minutes=40):
    """Extrae características de los últimos X minutos para la predicción."""
    # Suponiendo 1 muestra por segundo, 40 minutos = 2400 muestras
    window_size = window_minutes * 60
    if len(df) < window_size:
        window = df
    else:
        window = df.iloc[-window_size:]
    features = {
        'bpm_mean': window['bpm'].mean(),
        'bpm_std': window['bpm'].std(),
        'amp_mean': window['amp'].mean(),
        'amp_std': window['amp'].std(),
        'raw_mean': window['raw'].mean(),
        'raw_std': window['raw'].std(),
        'alerta_count': (window['estado'] == 'Alerta').sum(),
    }
    return np.array([list(features.values())])

def load_model(model_path='modelo_infarto.joblib'):
    """Carga el modelo de IA entrenado para predecir infartos."""
    if not os.path.exists(model_path):
        # Si no hay modelo, crea uno dummy (NO USAR EN PRODUCCIÓN)
        from sklearn.dummy import DummyClassifier
        dummy = DummyClassifier(strategy='uniform')
        dummy.fit([[0]*7], [0])
        joblib.dump(dummy, model_path)
    return joblib.load(model_path)

def predict_infarct_risk(csv_path, model_path='modelo_infarto.joblib'):
    df = load_csv_data(csv_path)
    X = extract_features(df)
    model = load_model(model_path)
    pred = model.predict(X)[0]
    prob = model.predict_proba(X)[0][1] if hasattr(model, 'predict_proba') else None
    return pred, prob

if __name__ == '__main__':
    import sys
    if len(sys.argv) < 2:
        print('Uso: python predecir_infarto.py archivo.csv')
        exit(1)
    csv_path = sys.argv[1]
    pred, prob = predict_infarct_risk(csv_path)
    if pred == 1:
        print(f'ALERTA: Riesgo de infarto detectado en los próximos 40 minutos. Probabilidad: {prob:.2f}')
    else:
        print(f'Sin riesgo de infarto detectado. Probabilidad: {prob:.2f}' if prob is not None else 'Sin riesgo de infarto detectado.')
