from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from pymongo import MongoClient
from firebase_admin import auth
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from settings import MONGO_URL, FIREBASE_CREDENTIALS, FIREBASE_API_KEY

from user import verify_token  # 📌 user.py içindeki doğrulama fonksiyonunu kullanıyoruz


router = APIRouter()
security = HTTPBearer()

# 📌 MongoDB Bağlantısı
client = MongoClient(MONGO_URL)
db = client["online_market"]
collection = db["products"]
collection.create_index([("name", 1)], unique=True)

# 📌 Ürün Modeli
class Product(BaseModel):
    name: str
    price: float
    stock: int

# 🔹 Ürün ekleme (JWT doğrulama ile)
@router.post("/add", summary="Ürün Ekle", description="Admin kullanıcıların yeni bir ürün eklemesine olanak tanır.")
def add_product(product: Product, user_data=Depends(verify_token)):
    user, role = user_data
    if role != "admin":
        raise HTTPException(status_code=403, detail="Erişim reddedildi: Yalnızca adminler ürün ekleyebilir.")
    
    product_dict = product.dict()
    collection.insert_one(product_dict)
    return {"message": f"Ürün eklendi, ekleyen: {user.get('email')}"}

# 🔹 Tüm ürünleri listeleme
@router.get("/", summary="Tüm Ürünleri Listele", description="Tüm ürünleri listelemek için kullanılır.")
def get_products():
    products = list(collection.find({}, {"_id": 0}))
    return {"products": products}

# 🔹 Belirli bir ürünü getirme
@router.get("/{name}",summary="Belli bir ürün getirme",description="Belli bir ürün sorgusu için")
def get_product(name: str):
    product = collection.find_one({"name": name}, {"_id": 0})
    if product:
        return product
    return {"error": "Ürün bulunamadı!"}

# 🔹 Ürün güncelleme
@router.put("/{name}", summary="Ürün Güncelle", description="Admin kullanıcıların mevcut bir ürünü güncellemesine olanak tanır.")
def update_product(name: str, price: float = None, stock: int = None, user_data=Depends(verify_token)):
    user, role = user_data
    if role != "admin":
        raise HTTPException(status_code=403, detail="Erişim reddedildi: Yalnızca adminler ürün güncelleyebilir.")
    update_data = {}
    if price is not None:
        update_data["price"] = price
    if stock is not None:
        update_data["stock"] = stock

    if not update_data:
        return {"error": "Güncellenecek veri girilmedi"}

    result = collection.update_one({"name": name}, {"$set": update_data})
    if result.matched_count:
        return {"message": f"{name} güncellendi! Güncelleyen: {user.get('email')}"}
    return {"error": "Ürün bulunamadı"}

# 🔹 Ürün silme
@router.delete("/{name}", summary="Ürün Sil", description="Admin kullanıcıların mevcut bir ürünü silmesine olanak tanır.")
def delete_product(name: str, user=Depends(verify_token), user_data=Depends(verify_token)):
    user, role = user_data
    if role != "admin":
        raise HTTPException(status_code=403, detail="Erişim reddedildi: Yalnızca adminler ürün silebilir.")
    # Ürün silme işlemi
    result = collection.delete_one({"name": name})
    if result.deleted_count:
        return {"message": f"{name} silindi! Silen: {user.get('email')}"}
    return {"error": "Ürün bulunamadı"}
