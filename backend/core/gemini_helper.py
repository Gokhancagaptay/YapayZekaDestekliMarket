# core/gemini_helper.py

import requests
from core.settings import GEMINI_API_KEY
import google.generativeai as genai
from typing import List
import logging

# Logging ayarları
logger = logging.getLogger(__name__)

# Gemini yapılandırması
genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel('gemini-pro')

MODELS = [
    "gemini-1.5-pro",
    "gemini-1.5-flash",
    "gemini-2.0-flash"
]


def _try_models(data):
    headers = {"Content-Type": "application/json"}
    params = {"key": GEMINI_API_KEY}
    print(f"Gemini API Key: {GEMINI_API_KEY[:10]}...")  # API key'in ilk 10 karakterini göster
    for model_id in MODELS:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_id}:generateContent"
        print(f"Denenen model: {model_id}")
        print(f"İstek URL: {url}")
        print(f"İstek verisi: {data}")
        response = requests.post(url, headers=headers, params=params, json=data)
        print(f"API Yanıt Kodu: {response.status_code}")
        print(f"API Yanıtı: {response.text}")
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
                "text": f"Lütfen {ingredients} ile yapılabilecek pratik bir yemek tarifi öner. Tarifi adım adım açıkla."
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


def suggest_breakfast_recipe(ingredients: str, recipe_type: str) -> str:
    """
    Kahvaltı tarifi önerir
    """
    prompt = ""
    if recipe_type == "quick":
        prompt = f"Bu ürünlerle pratik ve hızlı hazırlanabilecek bir kahvaltı öner: {ingredients}"
    elif recipe_type == "eggy":
        prompt = f"Bu ürünlerle yumurtalı bir kahvaltı tarifi öner: {ingredients}"
    elif recipe_type == "breadless":
        prompt = f"Bu ürünlerle ekmeksiz bir kahvaltı tarifi öner: {ingredients}"
    elif recipe_type == "sweet":
        prompt = f"Bu ürünlerle tatlı ağırlıklı bir kahvaltı tarifi öner: {ingredients}"
    elif recipe_type == "light":
        prompt = f"Bu ürünlerle hafif ve sade bir kahvaltı tarifi öner: {ingredients}"
    elif recipe_type == "cold":
        prompt = f"Bu ürünlerle pişirme gerektirmeyen, soğuk servis edilen bir kahvaltı öner: {ingredients}"
    
    prompt += """
    Kurallar:
    1. Sadece verilen ürünleri kullan (tuz, yağ, baharat serbest)
    2. Tüm ürünleri kullanmak zorunda değilsin
    3. Sadece 1 tarif ver
    4. Tarif sade, uygulanabilir ve ev ortamına uygun olsun
    5. Daha önce aynı stokla tarif verildiyse bu kez farklı bir öneri sun
    
    Tarif formatı şu şekilde olmalı:
    
    🍳 [TARİF ADI]
    
    📋 Malzemeler:
    - Malzeme 1
    - Malzeme 2
    ...
    
    👩‍🍳 Hazırlanışı:
    1. Adım 1
    2. Adım 2
    ...
    
    ⏱️ Hazırlama Süresi: XX dakika
    👥 Porsiyon: X kişilik
    
    💡 İpucu: [Varsa özel bir ipucu veya öneri]
    """
    
    data = {
        "contents": [{
            "parts": [{
                "text": prompt
            }]
        }]
    }
    return _try_models(data)


def suggest_dinner_recipe(ingredients, suggestion_type):
    prompt = ""
    if suggestion_type == "quick":
        prompt = f"Bu ürünlerle pratik ve hızlı hazırlanabilecek bir akşam yemeği öner: {ingredients}"
    elif suggestion_type == "medium":
        prompt = f"Bu ürünlerle orta zorlukta bir akşam yemeği tarifi öner: {ingredients}"
    elif suggestion_type == "long":
        prompt = f"Bu ürünlerle daha detaylı ve özel bir akşam yemeği tarifi öner: {ingredients}"
    elif suggestion_type == "meatless":
        prompt = f"Bu ürünlerle etsiz bir akşam yemeği tarifi öner: {ingredients}"
    elif suggestion_type == "soupy":
        prompt = f"Bu ürünlerle çorba ağırlıklı bir akşam yemeği öner: {ingredients}"
    elif suggestion_type == "onepan":
        prompt = f"Bu ürünlerle tek kapta hazırlanabilecek bir akşam yemeği öner: {ingredients}"
    
    prompt += """
    Kurallar:
    1. Sadece verilen ürünleri kullan (tuz, yağ, baharat serbest)
    2. Tüm ürünleri kullanmak zorunda değilsin
    3. Sadece 1 tarif ver
    4. Tarif sade, uygulanabilir ve ev ortamına uygun olsun
    5. Daha önce aynı stokla tarif verildiyse bu kez farklı bir öneri sun
    
    Tarif formatı şu şekilde olmalı:
    
    🍳 [TARİF ADI]
    
    📋 Malzemeler:
    - Malzeme 1
    - Malzeme 2
    ...
    
    👩‍🍳 Hazırlanışı:
    1. Adım 1
    2. Adım 2
    ...
    
    ⏱️ Hazırlama Süresi: XX dakika
    👥 Porsiyon: X kişilik
    
    💡 İpucu: [Varsa özel bir ipucu veya öneri]
    """
    
    data = {
        "contents": [{
            "parts": [{
                "text": prompt
            }]
        }]
    }
    return _try_models(data)


def suggest_snack(stock_items: List[str], snack_type: str) -> str:
    """
    Stok listesine göre atıştırmalık önerir
    """
    try:
        stock_text = ", ".join(stock_items)
        
        prompts = {
            "sweet": f"Bu malzemelerle tatlı bir atıştırmalık tarifi öner: {stock_text}",
            "salty": f"Bu malzemelerle tuzlu bir atıştırmalık tarifi öner: {stock_text}",
            "no_cooking": f"Bu malzemelerle fırın veya ocak gerektirmeyen bir atıştırmalık tarifi öner: {stock_text}",
            "movie_night": f"Bu malzemelerle film izlerken yenilebilecek bir atıştırmalık tarifi öner: {stock_text}",
            "diet_friendly": f"Bu malzemelerle sağlıklı ve düşük kalorili bir atıştırmalık tarifi öner: {stock_text}",
            "quick": f"Bu malzemelerle 5 dakikada hazırlanabilecek bir atıştırmalık tarifi öner: {stock_text}"
        }
        
        prompt = prompts.get(snack_type)
        if not prompt:
            return "Geçersiz atıştırmalık tipi"
            
        data = {
            "contents": [{
                "parts": [{
                    "text": prompt
                }]
            }]
        }
        return _try_models(data)
        
    except Exception as e:
        logger.error(f"Atıştırmalık önerisi hatası: {str(e)}")
        return "Öneri oluşturulamadı"


def analyze_nutrition(stock_items: List[str], analysis_type: str) -> str:
    """
    Stok listesine göre beslenme analizi yapar
    """
    try:
        stock_text = ", ".join(stock_items)
        
        prompts = {
            "balance": f"Bu stok listesine göre protein, karbonhidrat, yağ, lif ve vitamin açısından genel bir beslenme dengesi analizi yap: {stock_text}",
            "carb_protein": f"Bu stoktaki ürünlere göre karbonhidrat ve protein dengesi analizini yap: {stock_text}",
            "veggie_recipe": f"Bu malzemelerle sebze temelli, sağlıklı bir tarif öner: {stock_text}",
            "low_calorie": f"Bu malzemelerle düşük kalorili, hafif ve sağlıklı bir yemek öner: {stock_text}",
            "immune_boost": f"Bu malzemelerle bağışıklık sistemini destekleyecek bir tarif öner: {stock_text}",
            "post_workout": f"Bu malzemelerle egzersiz sonrası tüketilebilecek, toparlayıcı bir tarif öner: {stock_text}",
            "calorie_specific": f"Bu malzemelerle 1300-1500 kaloriye uygun bir öğün öner (porsiyon ve malzeme miktarını belirt): {stock_text}",
            "vitamin_rich": f"Bu malzemelerle A, B, C veya D vitamini açısından zengin bir tarif öner: {stock_text}"
        }
        
        prompt = prompts.get(analysis_type)
        if not prompt:
            return "Geçersiz analiz tipi"
            
        data = {
            "contents": [{
                "parts": [{
                    "text": prompt
                }]
            }]
        }
        return _try_models(data)
        
    except Exception as e:
        logger.error(f"Beslenme analizi hatası: {str(e)}")
        return "Analiz oluşturulamadı"


def suggest_shopping(stock_items: List[str], list_type: str) -> str:
    """
    Stok listesine göre alışveriş önerileri sunar
    """
    try:
        stock_text = ", ".join(stock_items)
        
        prompts = {
            "basic_needs": f"Bu stok listesine göre temel mutfak ve kahvaltılık eksikler neler? Kategorilere göre analiz yap: {stock_text}",
            "three_day_plan": f"Bu stokla 3 gün boyunca yemek yapabilmek için eksik olan temel ürünleri listele: {stock_text}",
            "breakfast_essentials": f"Kahvaltı hazırlamak için eksik olan temel ürünleri listele (yumurta, peynir, ekmek, zeytin gibi): {stock_text}",
            "essential_items": f"Mutfakta sürekli bulunması gereken ürünlerden eksik olanları listele: {stock_text}",
            "protein_focused": f"Protein bakımından yetersiz olan stoğa göre takviye alışveriş listesi oluştur: {stock_text}",
            "clean_eating": f"Haftalık temiz beslenme için eksik olan ürünleri listele (sebze, baklagil, tam tahıl ağırlıklı): {stock_text}"
        }
        
        prompt = prompts.get(list_type)
        if not prompt:
            return "Geçersiz liste tipi"
            
        data = {
            "contents": [{
                "parts": [{
                    "text": prompt
                }]
            }]
        }
        return _try_models(data)
        
    except Exception as e:
        logger.error(f"Alışveriş önerisi hatası: {str(e)}")
        return "Öneri oluşturulamadı"


def answer_custom_question(stock_items: List[str], question: str) -> str:
    """
    Kullanıcının özel sorusunu yanıtlar
    """
    try:
        stock_text = ", ".join(stock_items)
        prompt = f"Stok listesi: {stock_text}\n\nSoru: {question}\n\nSadece stok ürünlerini kullanarak yanıt ver."
        
        data = {
            "contents": [{
                "parts": [{
                    "text": prompt
                }]
            }]
        }
        return _try_models(data)
        
    except Exception as e:
        logger.error(f"Özel soru yanıtlama hatası: {str(e)}")
        return "Yanıt oluşturulamadı"


def suggest_lunch_recipe(ingredients: str, recipe_type: str) -> str:
    """
    Öğle yemeği tarifi önerir
    """
    prompt = ""
    if recipe_type == "quick":
        prompt = f"Bu ürünlerle pratik ve hızlı hazırlanabilecek bir öğle yemeği öner: {ingredients}"
    elif recipe_type == "eggy":
        prompt = f"Bu ürünlerle yumurtalı bir öğle yemeği tarifi öner: {ingredients}"
    elif recipe_type == "breadless":
        prompt = f"Bu ürünlerle ekmeksiz bir öğle yemeği tarifi öner: {ingredients}"
    elif recipe_type == "sweet":
        prompt = f"Bu ürünlerle tatlı ağırlıklı bir öğle yemeği tarifi öner: {ingredients}"
    elif recipe_type == "light":
        prompt = f"Bu ürünlerle hafif ve sade bir öğle yemeği tarifi öner: {ingredients}"
    elif recipe_type == "cold":
        prompt = f"Bu ürünlerle pişirme gerektirmeyen, soğuk servis edilen bir öğle yemeği öner: {ingredients}"
    
    prompt += """
    Kurallar:
    1. Sadece verilen ürünleri kullan (tuz, yağ, baharat serbest)
    2. Tüm ürünleri kullanmak zorunda değilsin
    3. Sadece 1 tarif ver
    4. Tarif sade, uygulanabilir ve ev ortamına uygun olsun
    5. Daha önce aynı stokla tarif verildiyse bu kez farklı bir öneri sun
    
    Tarif formatı şu şekilde olmalı:
    
    🍳 [TARİF ADI]
    
    📋 Malzemeler:
    - Malzeme 1
    - Malzeme 2
    ...
    
    👩‍🍳 Hazırlanışı:
    1. Adım 1
    2. Adım 2
    ...
    
    ⏱️ Hazırlama Süresi: XX dakika
    👥 Porsiyon: X kişilik
    
    💡 İpucu: [Varsa özel bir ipucu veya öneri]
    """
    
    data = {
        "contents": [{
            "parts": [{
                "text": prompt
            }]
        }]
    }
    return _try_models(data)