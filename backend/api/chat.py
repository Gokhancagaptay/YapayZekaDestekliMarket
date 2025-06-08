from fastapi import APIRouter, Depends, HTTPException
from typing import List
from core.gemini_helper import _try_models
from models.user import User
from api.auth import get_current_user

router = APIRouter()

@router.post("/question")
async def chat_question(request: dict, current_user: User = Depends(get_current_user)):
    try:
        question = request.get("question")
        stock_items = request.get("stock_items", [])
        
        if not question:
            raise HTTPException(status_code=400, detail="Soru boş olamaz")
            
        prompt = f"""
Kullanıcının stoğundaki ürünler:
{', '.join(stock_items)}

Kullanıcının sorusu:
"{question}"

Sadece yukarıdaki stok ürünlerini kullanarak bu soruya anlamlı ve uygulanabilir bir yanıt ver.
Yeni ürün önerme. Gerekirse sade bir tarif ver ama kullanıcıyı yormayacak şekilde açıkla.
"""
        
        response = await _try_models(prompt)
        
        if not response:
            raise HTTPException(status_code=500, detail="Yanıt oluşturulamadı")
            
        return {"answer": response}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 