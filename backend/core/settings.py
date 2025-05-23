import os
from dotenv import load_dotenv

# .env dosyasını yükle
load_dotenv()

# Çevresel değişkenleri yükle
MONGO_URL = os.getenv("MONGO_URL")
FIREBASE_CREDENTIALS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "firebase.json")
FIREBASE_API_KEY = os.getenv("FIREBASE_API_KEY")
EMAIL = os.getenv("email")
PASSWORD = os.getenv("password")
GEMINI_API_KEY = "AIzaSyCqMqAcS8i-xoGD2_KsJeut0qMLfYngrSA"

# Gerekli değişkenlerin kontrolü
required_vars = {
    "MONGO_URL": MONGO_URL,
    "FIREBASE_API_KEY": FIREBASE_API_KEY,
    "EMAIL": EMAIL,
    "PASSWORD": PASSWORD
}

# Eksik değişkenleri kontrol et
missing_vars = [var for var, value in required_vars.items() if not value]
if missing_vars:
    print(f"⚠️ Eksik çevresel değişkenler: {', '.join(missing_vars)}")
else:
    print("✅ Tüm gerekli çevresel değişkenler mevcut")

print(f"✅ MONGO_URL: {MONGO_URL}")
print(f"✅ FIREBASE_CREDENTIALS: {FIREBASE_CREDENTIALS}")
print(f"✅ FIREBASE_API_KEY: {FIREBASE_API_KEY}")
print(f"✅ GEMINI_API_KEY: {GEMINI_API_KEY}")
