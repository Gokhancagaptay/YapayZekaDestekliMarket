# core/gemini_helper.py

import requests
from core.settings import GEMINI_API_KEY

MODELS = [
    "gemini-1.5-pro",
    "gemini-1.5-flash",
    "gemini-2.0-flash"
]


def _try_models(data):
    headers = {"Content-Type": "application/json"}
    params = {"key": GEMINI_API_KEY}
    for model_id in MODELS:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_id}:generateContent"
        response = requests.post(url, headers=headers, params=params, json=data)
        if response.status_code == 200:
            result = response.json()
            return result["candidates"][0]["content"]["parts"][0]["text"]
        elif response.status_code not in [404, 429]:
            # Diğer hatalarda döngüyü kır
            return f"Hata: {response.status_code} - {response.text}"
    # Eğer tüm modellerde 404 veya 429 dönerse son hatayı döndür
    return f"Hata: {response.status_code} - {response.text}"


def suggest_recipe(ingredients):
    data = {
        "contents": [{
            "parts": [{
                "text": f"{ingredients} ile yapılabilecek pratik bir yemek tarifi öner."
            }]
        }]
    }
    return _try_models(data)


def analyze_recipe(ingredients):
    data = {
        "contents": [{
            "parts": [{
                "text": f"Aşağıdaki malzemelerle hazırlanacak bir yemeğin yaklaşık besin değerlerini (kalori, protein, karbonhidrat, yağ) ve sağlıklı olup olmadığına dair kısa bir analiz raporu hazırlar mısın?\nMalzemeler: {ingredients}"
            }]
        }]
    }
    return _try_models(data)