# 1️⃣ Python 3.11 sürümünü temel al
FROM python:3.11

# 2️⃣ Çalışma dizinini belirle
WORKDIR /app

# 3️⃣ Gerekli bağımlılıkları yükle
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4️⃣ Uygulama dosyalarını kopyala
COPY . .

# 5️⃣ Çevresel değişkenleri ayarla
ENV MONGO_URL=mongodb+srv://GokhanCagaptay:0102030h.H@onlinemarket.emtxzjn.mongodb.net/?retryWrites=true&w=majority&appName=onlineMarket
ENV FIREBASE_CREDENTIALS=/app/firebase.json

# 6️⃣ Başlangıç komutu (FastAPI başlat)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]


