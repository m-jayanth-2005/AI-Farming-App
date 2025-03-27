import joblib
import numpy as np
from sklearn.ensemble import RandomForestClassifier
import os

# Create 'models' directory if it doesn't exist
os.makedirs("models", exist_ok=True)

# Example training data (replace with actual data)
X = np.array([[6.5, 50, 40, 30, 20], [5.5, 30, 20, 10, 15]])
y = [1, 0]  # 1: Healthy Soil, 0: Unhealthy Soil

# Train the model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X, y)

# Save the trained model
joblib.dump(model, "models/soil_analysis_model.pkl")

print("✅ Model trained and saved successfully at models/soil_analysis_model.pkl")
