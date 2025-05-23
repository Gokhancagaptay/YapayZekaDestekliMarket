from fastapi import FastAPI, Depends, HTTPException, status, Path
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
from typing import List, Optional
import firebase_admin
from firebase_admin import credentials, auth
import os
from dotenv import load_dotenv
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from database import products_collection
from api.user import router as user_router
from api.recipe import router as recipe_router
from api.product import router as product_router
from api.snack import router as snack_router

# Load environment variables
load_dotenv()

# Firebase kimlik bilgilerini yükle
cred_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "firebase.json")
if not os.path.exists(cred_path):
    raise FileNotFoundError(f"Firebase kimlik bilgileri dosyası bulunamadı: {cred_path}")

# Initialize Firebase Admin
cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred, {
    "databaseURL": "https://marketonline44-default-rtdb.firebaseio.com"
})

print("\n>>> FASTAPI MAIN.PY BAŞLANGIÇ <<<\n")
app = FastAPI(
    title="Online Market API",
    description="Online Market Projesi için FastAPI backend",
    version="1.0.0"
)

# CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Debug için tüm rotaları yazdır
print("🔍 Mevcut rotalar:")
for route in app.routes:
    print(f"Path: {route.path}, Methods: {route.methods}")

# Router'ları ekle
app.include_router(user_router, prefix="/api/auth", tags=["auth"])
app.include_router(product_router, prefix="/api/products", tags=["products"])
app.include_router(recipe_router, prefix="/api/recipes", tags=["recipes"])
app.include_router(snack_router, prefix="/api/snacks", tags=["snacks"])

# Debug için router eklendikten sonra tüm rotaları yazdır
print("\n🔍 Router'lar eklendikten sonraki rotalar:")
for route in app.routes:
    print(f"Path: {route.path}, Methods: {route.methods}")

# Tüm rotaları listelemek için endpoint
@app.get("/routes")
async def list_routes():
    routes = [{"path": route.path, "methods": list(route.methods)} for route in app.routes]
    return {"routes": routes}

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Models
class User(BaseModel):
    id: str
    email: str
    display_name: Optional[str] = None

class Product(BaseModel):
    name: str
    price: float
    stock: int
    image_url: str
    category: str

class Recipe(BaseModel):
    id: str
    name: str
    ingredients: List[dict]
    instructions: List[str]
    nutrition_info: dict

# Dependency to get current user
async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        decoded_token = auth.verify_id_token(token)
        return User(
            id=decoded_token["uid"],
            email=decoded_token["email"],
            display_name=decoded_token.get("name")
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

# Health check endpoint
@app.get("/")
async def root():
    return {"message": "Online Market API'ye Hoş Geldiniz!"}

# Protected route example
@app.get("/user/profile", response_model=User)
async def read_user_profile(current_user: User = Depends(get_current_user)):
    return current_user

# Product management endpoints
@app.post("/products/")
async def add_product(product: Product, current_user: User = Depends(get_current_user)):
    # TODO: Implement product addition logic
    return {"message": "Product added successfully", "product": product}

@app.get("/products/")
async def get_products(token: Optional[str] = Depends(oauth2_scheme)):
    try:
        if token:
            auth.verify_id_token(token)
    except:
        pass

    products = list(products_collection.find({}, {"_id": 0}))
    return {"products": products}

@app.get("/products/categories")
async def get_categories():
    try:
        categories = await products_collection.distinct("category")
        print(f"Veritabanındaki kategoriler: {categories}")
        return {"categories": categories}
    except Exception as e:
        print(f"Kategori getirme hatası: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/products/by-category/{category}")
async def get_products_by_category(category: str):
    try:
        print(f"Gelen kategori parametresi: {category}")
        categories = await products_collection.distinct("category")
        print(f"Veritabanındaki kategoriler: {categories}")
        products = await products_collection.find({"category": category}).to_list(length=None)
        print(f"Bulunan ürünler: {products}")
        for product in products:
            product["_id"] = str(product["_id"])
        print(f"Bulunan ürün sayısı: {len(products)}")
        return {"products": products}
    except Exception as e:
        print(f"Ürün getirme hatası: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Ürünler getirilirken bir hata oluştu: {str(e)}"
        )

# Nutrition analysis endpoint
@app.get("/nutrition/analysis")
async def get_nutrition_analysis(current_user: User = Depends(get_current_user)):
    # TODO: Implement nutrition analysis logic
    return {"message": "Nutrition analysis will be implemented"}

@app.post("/products/test-data")
async def add_test_products():
    try:
        test_products = [
            {
                "name": "Elma",
                "price": 5.99,
                "stock": 100,
                "image_url": "https://example.com/elma.jpg",
                "category": "meyve_sebze"
            },
            {
                "name": "Muz",
                "price": 4.99,
                "stock": 150,
                "image_url": "https://example.com/muz.jpg",
                "category": "meyve_sebze"
            }
        ]
        
        result = await products_collection.insert_many(test_products)
        return {"message": f"{len(result.inserted_ids)} test ürünü eklendi"}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Test ürünleri eklenirken bir hata oluştu: {str(e)}"
        )

print("\n>>> FASTAPI MAIN.PY SONU <<<\n")
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000,debug=True)