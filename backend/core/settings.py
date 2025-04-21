import os
from dotenv import load_dotenv

# .env dosyasını yükle
load_dotenv()

# Çevresel değişkenleri yükle
MONGO_URL = os.getenv("MONGO_URL")
FIREBASE_CREDENTIALS = os.getenv("FIREBASE_CREDENTIALS")
FIREBASE_API_KEY = os.getenv("FIREBASE_API_KEY")
EMAIL = os.getenv("email")
PASSWORD = os.getenv("password")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")


print(f"✅ MONGO_URL: {MONGO_URL}")
print(f"✅ FIREBASE_CREDENTIALS: {FIREBASE_CREDENTIALS}")
print(f"✅ FIREBASE_API_KEY: {FIREBASE_API_KEY}")
print(f"✅ GEMINI_API_KEY: {GEMINI_API_KEY}")
