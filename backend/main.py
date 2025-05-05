from fastapi import FastAPI, Depends, HTTPException, status
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

from api.user import router as user_router


# Load environment variables
load_dotenv()


# Initialize Firebase Admin
cred = credentials.Certificate(os.getenv("FIREBASE_CREDENTIALS_PATH"))
firebase_admin.initialize_app(cred, {
    "databaseURL": os.getenv("FIREBASE_DB_URL")
})


app = FastAPI(
    title="Online Market AI Assistant",
    description="AI-powered online market assistant API",
    version="1.0.0"
)
app.include_router(user_router)


# CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Models
class User(BaseModel):
    id: str
    email: str
    display_name: Optional[str] = None

class Product(BaseModel):
    id: str
    name: str
    category: str
    quantity: int
    unit: str
    expiry_date: Optional[str] = None

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
    return {"status": "healthy", "message": "Online Market AI Assistant API is running"}

# Protected route example
@app.get("/user/profile", response_model=User)
async def read_user_profile(current_user: User = Depends(get_current_user)):
    return current_user

# Product management endpoints
@app.post("/products/")
async def add_product(product: Product, current_user: User = Depends(get_current_user)):
    # TODO: Implement product addition logic
    return {"message": "Product added successfully", "product": product}

@app.get("/products/", response_model=List[Product])
async def get_products(current_user: User = Depends(get_current_user)):
    # TODO: Implement product retrieval logic
    return []

# Recipe endpoints
@app.get("/recipes/", response_model=List[Recipe])
async def get_recipes(current_user: User = Depends(get_current_user)):
    # TODO: Implement recipe retrieval logic
    return []

@app.post("/recipes/suggest")
async def suggest_recipes(current_user: User = Depends(get_current_user)):
    # TODO: Implement AI-based recipe suggestion logic
    return {"message": "Recipe suggestions will be implemented"}

# Nutrition analysis endpoint
@app.get("/nutrition/analysis")
async def get_nutrition_analysis(current_user: User = Depends(get_current_user)):
    # TODO: Implement nutrition analysis logic
    return {"message": "Nutrition analysis will be implemented"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 