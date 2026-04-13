from flask import Flask, request, jsonify
import joblib
import numpy as np
import os

app = Flask(__name__)
data_history = []  # Lista para guardar historial
MAX_HISTORY = 100  # Puedes ajustar el tamaño del historial

@app.route('/api/datos', methods=['POST'])
def recibir_datos():
    global data_history
    data = request.get_json()
    data_history.append(data)
    # Limitar el historial a los últimos MAX_HISTORY elementos
    if len(data_history) > MAX_HISTORY:
        data_history = data_history[-MAX_HISTORY:]
    print("Dato recibido:", data)
    return jsonify({"status": "ok"})

@app.route('/api/datos', methods=['GET'])
def obtener_datos():
    return jsonify(data_history)


# --- Endpoint de predicción de infarto ---
@app.route('/api/prediccion_infarto', methods=['GET'])
def prediccion_infarto():
    # Cargar modelo solo una vez (mejor en global para producción)
    modelo_path = os.path.join(os.path.dirname(__file__), 'modelo_infarto.joblib')
    clf = joblib.load(modelo_path)
    # Tomar los últimos 2400 datos (40 minutos si 1 dato/seg)
    VENTANA = 2400
    ultimos = data_history[-VENTANA:] if len(data_history) >= VENTANA else data_history
    if not ultimos:
        return jsonify({'error': 'No hay datos suficientes'}), 400
    # Extraer features: heart_rate, blood_pressure, spo2
    X = []
    for d in ultimos:
        try:
            hr = float(d.get('heart_rate', 0))
            bp = float(d.get('blood_pressure', 0))
            spo2 = float(d.get('spo2', 0))
        except Exception:
            hr, bp, spo2 = 0, 0, 0
        X.append([hr, bp, spo2])
    X = np.array(X)
    # Promedio de predicción sobre la ventana
    y_pred = clf.predict(X)
    riesgo = int(np.mean(y_pred) > 0.5)
    return jsonify({'riesgo_infarto': bool(riesgo), 'ventana': y_pred.tolist(), 'ventana_minutos': len(ultimos)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
