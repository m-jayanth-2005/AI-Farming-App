from fastapi import FastAPI, UploadFile, File
import uvicorn
from soil_model import analyze_soil
from disease_model import detect_disease
from weather_api import get_weather
import shutil
import os

app = FastAPI()

# Create upload directory
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.get("/")
def home():
    return {"message": "Welcome to AI Farming App Backend!"}

# Soil Analysis API
@app.post("/analyze_soil")
async def analyze_soil_api(file: UploadFile = File(...)):
    file_path = f"{UPLOAD_FOLDER}/{file.filename}"
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    result = analyze_soil(file_path)
    return {"soil_analysis_result": result}

# Plant Disease Detection API
@app.post("/detect_disease")
async def detect_disease_api(file: UploadFile = File(...)):
    file_path = f"{UPLOAD_FOLDER}/{file.filename}"
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    result = detect_disease(file_path)
    return {"disease_detection_result": result}

# Weather API
@app.get("/weather")
def weather_api():
    return get_weather()

# Run the FastAPI server
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
