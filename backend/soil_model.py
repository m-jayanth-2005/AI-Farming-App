import joblib
import numpy as np

# Load trained RandomForest model
model = joblib.load("models/soil_analysis_model.pkl")

# Function to analyze soil
def analyze_soil(image_path):
    # Example feature extraction (replace with actual logic)
    features = np.random.rand(1, 5)  # Placeholder features
    prediction = model.predict(features)
    
    return f"Soil quality: {'Good' if prediction[0] == 1 else 'Poor'}"
