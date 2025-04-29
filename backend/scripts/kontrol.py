from core.settings import MONGO_URL, FIREBASE_CREDENTIALS, FIREBASE_API_KEY
from fastapi import FastAPI
from api.user import router as user_router
from api.product import router as product_router
from core.firebase_login import *
from api.recipe import router as recipe_router
from fastapi.middleware.cors import CORSMiddleware



app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Her yerden istek kabul et (geliştirme aşaması için)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# 📌 Kullanıcı ve ürün API'lerini buraya ekliyoruz
app.include_router(user_router, prefix="/users", tags=["Kullanıcı İşlemleri"])
app.include_router(product_router, prefix="/products", tags=["Ürün İşlemleri"])
app.include_router(recipe_router, prefix="/recipes", tags=["Tarif Önerisi"])


@app.get("/")
def home():
    return {"message": "FastAPI çalışıyor! 🎉"}
