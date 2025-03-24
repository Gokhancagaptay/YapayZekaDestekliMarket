from settings import MONGO_URL, FIREBASE_CREDENTIALS, FIREBASE_API_KEY
from fastapi import FastAPI
from user import router as user_router
from product import router as product_router



app = FastAPI()

# 📌 Kullanıcı ve ürün API'lerini buraya ekliyoruz
app.include_router(user_router, prefix="/users", tags=["Kullanıcı İşlemleri"])
app.include_router(product_router, prefix="/products", tags=["Ürün İşlemleri"])

@app.get("/")
def home():
    return {"message": "FastAPI çalışıyor! 🎉"}
