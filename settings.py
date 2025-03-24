from dotenv import load_dotenv
import os

# .env dosyasını yükle
load_dotenv()

# Çevresel değişkenleri al
MONGO_URL = os.getenv("MONGO_URL")
FIREBASE_CREDENTIALS = os.getenv("FIREBASE_CREDENTIALS")
FIREBASE_API_KEY = os.getenv("FIREBASE_API_KEY")

# Kontrol için ekrana yazdır
print("✅ MONGO_URL:", MONGO_URL)
print("✅ FIREBASE_CREDENTIALS:", FIREBASE_CREDENTIALS)
print("✅ FIREBASE_API_KEY:", FIREBASE_API_KEY)

# Debugging: Değişkenlerin durumu
if MONGO_URL is None or FIREBASE_CREDENTIALS is None or FIREBASE_API_KEY is None:
    print("❌ Bir veya daha fazla çevresel değişken ayarlanmamış. Lütfen .env dosyasını kontrol edin.")