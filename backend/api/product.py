from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from pymongo import MongoClient
from fastapi.security import HTTPBearer
from core.settings import MONGO_URL
from api.user import verify_token

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
    image_url: str
    category: str  

# 🔹 Ürün ekleme (JWT doğrulama ile)
@router.post("/add", summary="Ürün Ekle", description="Kullanıcıların yeni bir ürün eklemesine olanak tanır.")
def add_product(product: Product):
    user, _ = user_data  # Artık role kontrol etmiyoruz
    print(f"Ürün ekleyen kullanıcı: {user.get('email')}")  # Sadece bilgilendirme için
    product_dict = product.dict()
    collection.insert_one(product_dict)
    return {"message": f"Ürün başarıyla eklendi! Ekleyen kullanıcı: {user.get('email')}"}

# 🔹 Tüm ürünleri listeleme
@router.get("/", summary="Tüm Ürünleri Listele")
def get_all_products():
    try:
        products = list(collection.find({}, {"_id": 0}))
        return {"products": products}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ürünler listelenirken bir hata oluştu: {str(e)}")

# 🔹 Kategoriye göre ürünleri listeleme
@router.get("/by-category/{category}", summary="Kategoriye Göre Ürünleri Listele")
def get_products_by_category(category: str):
    try:
        products = list(collection.find({"category": category}, {"_id": 0}))
        if not products:
            return {"message": f"{category} kategorisinde ürün bulunamadı!", "products": []}
        return {"products": products}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Kategori listelenirken bir hata oluştu: {str(e)}")

# 🔹 Belirli bir ürünü getirme
@router.get("/by-name/{name}", summary="Belli bir ürün getirme", description="Belli bir ürün sorgusu için")
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
        raise HTTPException(status_code=400, detail="Güncellenecek veri girilmedi.")

    result = collection.update_one({"name": name}, {"$set": update_data})
    if result.matched_count:
        return {"message": f"{name} güncellendi! Güncelleyen: {user.get('email')}"}
    return {"error": "Ürün bulunamadı"}

# 🔹 Ürün silme
@router.delete("/{name}", summary="Ürün Sil", description="Admin kullanıcıların mevcut bir ürünü silmesine olanak tanır.")
def delete_product(name: str, user_data=Depends(verify_token)):
    user, role = user_data
    if role != "admin":
        raise HTTPException(status_code=403, detail="Erişim reddedildi: Yalnızca adminler ürün silebilir.")
    
    result = collection.delete_one({"name": name})
    if result.deleted_count:
        return {"message": f"{name} silindi! Silen: {user.get('email')}"}
    return {"error": "Ürün bulunamadı"}

# 🔹 MongoDB Bağlantı Testi
@router.get("/test-connection")
def test_connection():
    try:
        # Veritabanı bağlantısını test et
        db.command('ping')
        # Koleksiyondaki ürün sayısını al
        count = collection.count_documents({})
        return {
            "status": "success",
            "message": "MongoDB bağlantısı başarılı",
            "product_count": count
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"MongoDB bağlantı hatası: {str(e)}")
