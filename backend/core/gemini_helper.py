# core/gemini_helper.py

import requests
from core.settings import GEMINI_API_KEY

def suggest_recipe(ingredients):
    model_id = "gemini-1.5-pro"
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_id}:generateContent"
    headers = {"Content-Type": "application/json"}
    params = {"key": GEMINI_API_KEY}
    data = {
        "contents": [{
            "parts": [{
                "text": f"{ingredients} ile yapılabilecek pratik bir yemek tarifi öner."
            }]
        }]
    }
    response = requests.post(url, headers=headers, params=params, json=data)

    if response.status_code == 200:
        result = response.json()
        return result["candidates"][0]["content"]["parts"][0]["text"]
    else:
        return f"Hata: {response.status_code} - {response.text}"