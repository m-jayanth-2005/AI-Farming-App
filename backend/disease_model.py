import tensorflow as tf
import numpy as np
from PIL import Image

# Load trained CNN model
model = tf.keras.models.load_model("models/plant_disease_model.h5")

# Function to detect plant disease
def detect_disease(image_path):
    img = Image.open(image_path).resize((224, 224))  # Resize for CNN
    img_array = np.array(img) / 255.0  # Normalize
    img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension

    prediction = model.predict(img_array)
    class_index = np.argmax(prediction)

    classes = ["Healthy", "Bacterial Blight", "Rust", "Leaf Spot"]
    return f"Detected Disease: {classes[class_index]}"
