import requests

API_KEY = "8ba53915fee10bd9cf54e896183b1021"  # Replace with your API key
CITY = "YourCity"

def get_weather():
    url = f"http://api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric"
    response = requests.get(url)
    data = response.json()

    if response.status_code == 200:
        temp = data["main"]["temp"]
        weather = data["weather"][0]["description"]
        return f"Weather: {weather}, Temperature: {temp}°C"
    else:
        return "Error fetching weather data."
