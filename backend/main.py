

from fastapi import FastAPI, Request, UploadFile, File, Query, HTTPException, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import os
from dotenv import load_dotenv
import logging
from logging.handlers import RotatingFileHandler
import requests

import google.generativeai as genai
from PIL import Image
from io import BytesIO
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.preprocessing import image
from tensorflow.keras.applications.efficientnet import preprocess_input, decode_predictions
from functools import lru_cache
import time
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field
import json
from PIL import UnidentifiedImageError

# Load environment variables first
load_dotenv()

# Configure advanced logging
log_dir = "logs"
os.makedirs(log_dir, exist_ok=True)
file_handler = RotatingFileHandler(
    os.path.join(log_dir, "api.log"), 
    maxBytes=10485760,  # 10MB
    backupCount=5
)

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        file_handler,
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("ai_farming")

# Create Pydantic models for request/response validation
class SoilData(BaseModel):
    ph: float = Field(..., description="Soil pH level")
    nitrogen: float = Field(..., description="Nitrogen content in mg/kg")
    phosphorus: float = Field(..., description="Phosphorus content in mg/kg")
    potassium: float = Field(..., description="Potassium content in mg/kg")
    organic_matter: Optional[float] = Field(None, description="Organic matter percentage")
    moisture: Optional[float] = Field(None, description="Soil moisture percentage")
    
    class Config:
        schema_extra = {
            "example": {
                "ph": 6.8,
                "nitrogen": 240,
                "phosphorus": 45,
                "potassium": 210,
                "organic_matter": 3.5,
                "moisture": 35.0
            }
        }

class AnalysisResponse(BaseModel):
    status: str
    result: str
    execution_time: float

class WeatherResponse(BaseModel):
    status: str
    description: str
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    wind_speed: Optional[float] = None
    latitude: float
    longitude: float
    execution_time: float

class RecommendationResponse(BaseModel):
    status: str
    recommendation: str
    execution_time: float

# Initialize the FastAPI app with more metadata
app = FastAPI(
    title="AI Farming Backend",
    description="Advanced AI-powered farming analysis and recommendation system",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS middleware with more specific settings
origins = [
    "http://localhost",
    "http://localhost:8080",
    "http://localhost:3000",
    "http://localhost:5000",
    "http://10.0.2.2",  # For Android emulator
    "http://10.0.2.2:8001", 
    "https://yourfrontendapp.com"
]

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("uvicorn")

@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(f"Incoming request: {request.method} {request.url}")
    response = await call_next(request)
    logger.info(f"Outgoing response: {response.status_code}")
    return response

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins if os.getenv("ENVIRONMENT") == "production" else ["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"],  # Expose all headers in the response
)

# Cache to store AI responses for similar inputs (simple in-memory cache)
response_cache = {}

# Initialize Genai client
@lru_cache(maxsize=1)
def get_genai_client():
    gemini_api_key = os.getenv("GEMINI_API_KEY")
    if not gemini_api_key:
        logger.error("GEMINI_API_KEY not found in environment variables")
        raise ValueError("GEMINI_API_KEY not configured")
    return genai(api_key=gemini_api_key)

# Initialize TensorFlow model with caching
@lru_cache(maxsize=1)
def get_model():
    try:
        # Set memory growth to avoid OOM errors
        physical_devices = tf.config.list_physical_devices('GPU')
        if physical_devices:
            for device in physical_devices:
                tf.config.experimental.set_memory_growth(device, True)
        
        logger.info("Loading EfficientNetB0 model...")
        return EfficientNetB0(weights='imagenet')
    except Exception as e:
        logger.error(f"Error loading EfficientNetB0 model: {e}")
        return None

# Model loading happens when needed, not at startup
def get_model_for_request():
    model = get_model()
    if model is None:
        raise HTTPException(status_code=503, detail="ML model not available")
    return model

# Dependency for getting the OpenWeatherMap API key
def get_weather_api_key():
    api_key = os.getenv("OPENWEATHERMAP_API_KEY")
    if not api_key or api_key == "":
        raise HTTPException(status_code=500, detail="Weather API key not configured")
    return api_key

@app.post("/soil-analysis/", response_model=AnalysisResponse)
async def soil_analysis(soil_data: SoilData, background_tasks: BackgroundTasks):
    start_time = time.time()
    try:
        # Generate a cache key from the request data
        cache_key = f"soil_{hash(frozenset(soil_data.dict().items()))}"
        
        # Check cache first
        if cache_key in response_cache:
            cached_result = response_cache[cache_key]
            logger.info(f"Returning cached soil analysis result for {soil_data}")
            return {
                "status": "success", 
                "result": cached_result,
                "execution_time": time.time() - start_time
            }
        
        groq_client = get_groq_client()
        
        # Create a detailed prompt with structured data
        prompt = (
            f"Analyze the following soil data for farming in Vijayawada, Andhra Pradesh, India:\n"
            f"- pH: {soil_data.ph}\n"
            f"- Nitrogen: {soil_data.nitrogen} mg/kg\n"
            f"- Phosphorus: {soil_data.phosphorus} mg/kg\n"
            f"- Potassium: {soil_data.potassium} mg/kg\n"
        )
        
        if soil_data.organic_matter:
            prompt += f"- Organic Matter: {soil_data.organic_matter}%\n"
            
        if soil_data.moisture:
            prompt += f"- Moisture: {soil_data.moisture}%\n"
            
        prompt += (
            "\nProvide a detailed analysis including:\n"
            "1. Overall soil health assessment\n"
            "2. Nutrient balance evaluation\n"
            "3. Suitable crops for this soil composition\n"
            "4. Recommended amendments or treatments\n"
            "5. Best practices for soil management"
        )
        
        # Log the request, not the full prompt for security
        logger.info(f"Processing soil analysis request for soil data: {soil_data}")
        
        chat_completion = groq_client.chat.completions.create(
            model="mixtral-8x7b-32768",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3,  # Lower temperature for more consistent results
            max_tokens=1024,
        )
        
        recommendation = chat_completion.choices[0].message.content.strip()
        
        # Save to cache in the background to avoid blocking
        background_tasks.add_task(lambda: response_cache.update({cache_key: recommendation}))
        
        return {
            "status": "success", 
            "result": recommendation,
            "execution_time": time.time() - start_time
        }
    except Exception as e:
        logger.error(f"Soil analysis error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Soil analysis failed: {str(e)}")

@app.post("/disease-analysis/", response_model=AnalysisResponse)
async def disease_analysis(background_tasks: BackgroundTasks, file: UploadFile = File(...)):
    # ... (file type validation)

    try:
        model = get_model_for_request()

        image_bytes = await file.read()
        img_hash = hash(image_bytes)
        cache_key = f"disease_{img_hash}"

        # ... (cache check)

        img = Image.open(BytesIO(image_bytes))
        if img.mode != 'RGB':
            img = img.convert('RGB')
        img = img.resize((224, 224))
        img_array = image.img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0)
        img_array = preprocess_input(img_array)

        predictions = model.predict(img_array, verbose=0)
        decoded_predictions = decode_predictions(predictions, top=5)[0]

        # ... (result formatting)

        return {
            "status": "success",
            "result": recommendation,
            "execution_time": time.time() - start_time
        }

    except HTTPException as http_exc:
        raise http_exc
    except UnidentifiedImageError:
        logger.error(f"Error: Unable to identify image file: {file.filename}")
        raise HTTPException(status_code=400, detail="Invalid image file.")
    except tf.errors.InvalidArgumentError as tf_exc:
        logger.error(f"TensorFlow error: {tf_exc}")
        raise HTTPException(status_code=500, detail="TensorFlow prediction error.")
    except Exception as e:
        logger.error(f"Disease analysis error: {e}")
        raise HTTPException(status_code=500, detail="Internal server error.")
        
        # Add interpretation for agricultural context
        groq_client = get_groq_client()
        interpretation_prompt = (
            f"The image analysis detected the following: {recommendation}. "
            f"If any of these are plant diseases or pests, provide a brief explanation "
            f"of what they are and how they affect plants. If not plant-related, indicate "
            f"this is not a plant disease. Keep it concise (max 150 words)."
        )
        
        chat_completion = groq_client.chat.completions.create(
            model="mixtral-8x7b-32768",
            messages=[{"role": "user", "content": interpretation_prompt}],
            temperature=0.3,
            max_tokens=300,
        )
        
        interpretation = chat_completion.choices[0].message.content.strip()
        final_result = f"Detection results: {recommendation}\n\nInterpretation: {interpretation}"
        
        # Save to cache in the background
        background_tasks.add_task(lambda: response_cache.update({cache_key: final_result}))
        
        return {
            "status": "success", 
            "result": final_result,
            "execution_time": time.time() - start_time
        }
    except Exception as e:
        logger.error(f"Disease analysis error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Disease analysis failed: {str(e)}")
@app.post("/chat")
async def chat(request: Request):
    try:
        data = await request.json()
        message = data.get("message")

        if not message:
            return {"error": "Missing message in request body"}, 400

        groq_client = get_groq_client()

        chat_completion = groq_client.chat.completions.create(
            model="mixtral-8x7b-32768",
            messages=[{"role": "user", "content": message}],
            temperature=0.3,
            max_tokens=1500,
        )

        response_message = chat_completion.choices[0].message.content.strip()

        return {"response": response_message}

    except json.JSONDecodeError:
        print("Error: Invalid JSON")
        return {"error": "Invalid JSON in request body"}, 400
    except Exception as e:
        print(f"Chat error: {e}") # Log the error
        return {"error": f"Internal Server Error: {e}"}, 500

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": "1.0.0"}


@app.get("/weather/", response_model=WeatherResponse)
async def get_weather(
    background_tasks: BackgroundTasks,
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude"),
    location: str = Query(None, description="Location (e.g., city, country)"),
    api_key: str = Depends(get_weather_api_key),
    
    ):
    start_time = time.time()
    try:
        # Cache key based on coordinates (rounded to 2 decimal places to reduce cache size)
        rounded_lat = round(lat, 2)
        rounded_lon = round(lon, 2)
        cache_key = f"weather_{rounded_lat}_{rounded_lon}"
        
        # Check cache - weather data should expire more quickly
        # Only use cache if it's less than 1 hour old
        current_time = time.time()
        if cache_key in response_cache and current_time - response_cache.get(f"{cache_key}_time", 0) < 3600:
            logger.info(f"Returning cached weather data for coordinates: {rounded_lat}, {rounded_lon}")
            cached_result = response_cache[cache_key]
            cached_result["execution_time"] = time.time() - start_time
            return cached_result
        
        # Set up timeout for external API call
        url = f"http://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_key}&units=metric"
        response = requests.get(url, timeout=5)
        response.raise_for_status()
        weather_data = response.json()
        
        # Extract more detailed weather information
        result = {
            "status": "success",
            "description": weather_data['weather'][0]['description'],
            "temperature": weather_data['main']['temp'],
            "humidity": weather_data['main'].get('humidity'),
            "wind_speed": weather_data['wind'].get('speed'),
            "latitude": lat,
            "longitude": lon,
            "execution_time": time.time() - start_time
        }
        
        # Update cache in background with timestamp
        background_tasks.add_task(lambda: response_cache.update({
            cache_key: result,
            f"{cache_key}_time": current_time
        }))
        
        return result
    except requests.exceptions.Timeout:
        logger.error(f"Weather API timeout for coordinates: {lat}, {lon}")
        raise HTTPException(status_code=504, detail="Weather API request timed out")
    except requests.exceptions.RequestException as e:
        logger.error(f"Weather API error: {e}", exc_info=True)
        raise HTTPException(status_code=502, detail=f"Weather data fetch failed: {str(e)}")

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": "1.0.0"}

# Manage large cache to prevent memory issues
@app.get("/admin/clear-cache", include_in_schema=False)
async def clear_cache(api_key: str = Query(...)):
    # Simple admin authentication
    if api_key != os.getenv("ADMIN_API_KEY"):
        raise HTTPException(status_code=403, detail="Unauthorized")
    
    response_cache.clear()
    return {"status": "success", "message": "Cache cleared"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=os.getenv("ENVIRONMENT") != "production")
