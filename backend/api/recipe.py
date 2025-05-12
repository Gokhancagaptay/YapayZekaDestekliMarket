from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List
from core.gemini_helper import suggest_recipe, analyze_recipe

router = APIRouter()

class IngredientInput(BaseModel):
    ingredients: str

class AnalysisRequest(BaseModel):
    ingredients: List[str]

class PriceRequest(BaseModel):
    ingredients: List[str]

class CustomQuestionRequest(BaseModel):
    ingredients: List[str]
    question: str

@router.post("/suggest", summary="Tarif Öner", description="Mevcut malzemelerle tarif önerir.")
def get_recipe_suggestion(input_data: IngredientInput):
    suggestion = suggest_recipe(input_data.ingredients)
    return {"suggestion": suggestion}

@router.post("/analyze", summary="Besin Analizi", description="Mevcut malzemelerle yapılacak bir yemeğin besin analizi ve sağlık değerlendirmesi.")
async def analyze_ingredients(request: AnalysisRequest):
    try:
        ingredients_str = ", ".join(request.ingredients)
        analysis = analyze_recipe(ingredients_str)
        return {"analysis": analysis}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/price", summary="Fiyat Analizi", description="Mevcut malzemelerin toplam fiyatını ve fiyat analizi yapar.")
async def price_analysis(request: PriceRequest):
    try:
        # Burada örnek olarak Gemini'ye fiyat analizi sorusu soruluyor
        from core.gemini_helper import analyze_recipe
        ingredients_str = ", ".join(request.ingredients)
        price_prompt = f"Aşağıdaki malzemelerin ortalama piyasa fiyatını ve toplam maliyetini TL cinsinden tahmini olarak hesaplar mısın? Malzemeler: {ingredients_str}"
        result = analyze_recipe(price_prompt)
        return {"price_analysis": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/custom", summary="Özel Soru", description="Kullanıcının kendi yazdığı soruyu ve malzemeleri Gemini'ye iletir.")
async def custom_question(request: CustomQuestionRequest):
    try:
        from core.gemini_helper import analyze_recipe
        ingredients_str = ", ".join(request.ingredients)
        custom_prompt = f"Malzemeler: {ingredients_str}\nSoru: {request.question}"
        result = analyze_recipe(custom_prompt)
        return {"answer": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
