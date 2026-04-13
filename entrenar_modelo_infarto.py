
# Entrenamiento de modelo de IA para predicción de infarto usando datos simulados realistas
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
import joblib

# Cargar los datos simulados
df = pd.read_csv('datos_entrenamiento_infarto.csv')

# Seleccionar características y etiqueta
y = df['infarto_40min']
X = df[['heart_rate', 'blood_pressure', 'spo2']]

# Dividir en entrenamiento y prueba
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Entrenar el modelo
clf = RandomForestClassifier(n_estimators=100, random_state=42)
clf.fit(X_train, y_train)

# Evaluar el modelo
y_pred = clf.predict(X_test)
print('Accuracy:', accuracy_score(y_test, y_pred))
print(classification_report(y_test, y_pred))

# Guardar el modelo entrenado
joblib.dump(clf, 'modelo_infarto.joblib')
print('Modelo guardado como modelo_infarto.joblib')
