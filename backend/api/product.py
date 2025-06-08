from fastapi import APIRouter, HTTPException, Depends, Query, Path, Body
from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any
from pymongo import MongoClient
from bson import ObjectId
from fastapi.security import HTTPBearer
from core.settings import MONGO_URL
from api.user import verify_token

router = APIRouter()
security = HTTPBearer()

# 📌 MongoDB Bağlantısı
client = MongoClient(MONGO_URL)
db = client["online_market"]
products_collection = db["products"]
products_collection.create_index([("name", 1)], unique=True)

# 📌 Ürün ID'sinin geçerli bir ObjectId olup olmadığını kontrol etmek için yardımcı fonksiyon
def validate_object_id(id_string: str) -> ObjectId:
    try:
        return ObjectId(id_string)
    except Exception:
        raise HTTPException(status_code=400, detail="Geçersiz Ürün ID formatı")

# 📌 Ürün Modeli
class ProductBase(BaseModel):
    name: str = Field(..., min_length=1)
    price: float = Field(..., gt=0)
    stock: int = Field(..., ge=0)
    image_url: str
    category: str = Field(..., min_length=1)

class ProductCreate(ProductBase):
    pass

class ProductUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1)
    price: Optional[float] = Field(None, gt=0)
    stock: Optional[int] = Field(None, ge=0)
    image_url: Optional[str] = None
    category: Optional[str] = Field(None, min_length=1)

class ProductResponse(ProductBase):
    id: str = Field(alias="_id")

    class Config:
        populate_by_name = True
        json_encoders = {
            ObjectId: str
        }

    @validator('id', pre=True, allow_reuse=True)
    def convert_objectid_to_str(cls, value):
        if isinstance(value, ObjectId):
            return str(value)
        return value

# Yardımcı fonksiyon: MongoDB dökümanını ProductResponse modeline çevir
def map_product_to_response(product: Dict[str, Any]) -> Dict[str, Any]:
    product["_id"] = str(product["_id"])
    return product

# 🔹 Ürün ekleme (JWT doğrulama ile)
@router.post("/", summary="Yeni Ürün Ekle (Admin Yetkili)", response_model=ProductResponse)
async def create_product(product_data: ProductCreate, current_user: dict = Depends(verify_token)):
    user_info, role = current_user
    if role != "admin":
        raise HTTPException(status_code=403, detail="Yetkisiz işlem: Sadece adminler ürün ekleyebilir.")
    
    product_dict = product_data.model_dump()
    
    if products_collection.find_one({"name": product_dict["name"]}):
        raise HTTPException(status_code=400, detail=f"'{product_dict['name']}' isimli ürün zaten mevcut.")
    
    try:
        result = products_collection.insert_one(product_dict)
        created_product = products_collection.find_one({"_id": result.inserted_id})
        if created_product:
            return ProductResponse(**created_product)
        raise HTTPException(status_code=500, detail="Ürün oluşturuldu ancak getirilemedi.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ürün eklenirken bir hata oluştu: {str(e)}")

# 🔹 Tüm ürünleri listeleme
@router.get("/", summary="Tüm Ürünleri Listele (Arama ve Filtre ile)", response_model=List[ProductResponse])
async def list_products(
    search: Optional[str] = Query(None, description="Ürün adında arama yap"),
    category: Optional[str] = Query(None, description="Kategoriye göre filtrele")
):
    query = {}
    if search:
        query["name"] = {"$regex": search, "$options": "i"}
    if category:
        query["category"] = category
    
    try:
        products_cursor = products_collection.find(query)
        products_list = [ProductResponse(**p) for p in products_cursor]
        return products_list
    except Exception as e:
        print(f"HATA DETAYI (list_products): {e}")
        from pydantic import ValidationError
        if isinstance(e, ValidationError):
            print(f"Pydantic Validation Error details: {e.errors()}")
        raise HTTPException(status_code=500, detail=f"Ürünler listelenirken bir hata oluştu: {str(e)}")

@router.get("/categories", summary="Tüm Ürün Kategorilerini Listele", response_model=List[str])
async def get_categories():
    try:
        categories = products_collection.distinct("category")
        return categories
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Kategoriler alınırken bir hata oluştu: {str(e)}")

# 🔹 Belirli bir ürünü getirme
@router.get("/{product_id}", summary="Belirli Bir Ürünü Getir", response_model=ProductResponse)
async def get_product_by_id(product_id: str = Path(..., description="Getirilecek ürünün ID'si")):
    db_id = validate_object_id(product_id)
    product = products_collection.find_one({"_id": db_id})
    if product:
        return ProductResponse(**product)
    raise HTTPException(status_code=404, detail=f"'{product_id}' ID'li ürün bulunamadı.")

# 🔹 Ürün güncelleme
@router.put("/{product_id}", summary="Ürünü Güncelle (Admin Yetkili)", response_model=ProductResponse)
async def update_product(
    product_id: str = Path(..., description="Güncellenecek ürünün ID'si"), 
    product_update: ProductUpdate = Body(...),
    current_user: dict = Depends(verify_token)
):
    user_info, role = current_user
    if role != "admin":
        raise HTTPException(status_code=403, detail="Yetkisiz işlem: Sadece adminler ürün güncelleyebilir.")
    
    db_id = validate_object_id(product_id)
    update_data = product_update.model_dump(exclude_unset=True)

    if not update_data:
        raise HTTPException(status_code=400, detail="Güncellenecek veri bulunmuyor.")
    
    if "name" in update_data:
        existing_product_with_name = products_collection.find_one({"name": update_data["name"], "_id": {"$ne": db_id}})
        if existing_product_with_name:
            raise HTTPException(status_code=400, detail=f"'{update_data['name']}' isimli başka bir ürün zaten mevcut.")

    result = products_collection.update_one({"_id": db_id}, {"$set": update_data})
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail=f"'{product_id}' ID'li ürün bulunamadı.")
    
    updated_product = products_collection.find_one({"_id": db_id})
    if updated_product:
        return ProductResponse(**updated_product)
    raise HTTPException(status_code=500, detail="Ürün güncellendi ancak getirilemedi.")

# 🔹 Ürün silme
@router.delete("/{product_id}", summary="Ürünü Sil (Admin Yetkili)")
async def delete_product(
    product_id: str = Path(..., description="Silinecek ürünün ID'si"), 
    current_user: dict = Depends(verify_token)
):
    user_info, role = current_user
    if role != "admin":
        raise HTTPException(status_code=403, detail="Yetkisiz işlem: Sadece adminler ürün silebilir.")
    
    db_id = validate_object_id(product_id)
    result = products_collection.delete_one({"_id": db_id})
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail=f"'{product_id}' ID'li ürün bulunamadı.")
    
    return {"message": f"'{product_id}' ID'li ürün başarıyla silindi."}

# 🔹 MongoDB Bağlantı Testi
@router.get("/test-connection", summary="MongoDB Bağlantı Testi")
async def test_connection_endpoint():
    try:
        db.command('ping')
        count = products_collection.count_documents({})
        return {
            "status": "success",
            "message": "MongoDB bağlantısı başarılı",
            "product_count": count
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"MongoDB bağlantı hatası: {str(e)}")
