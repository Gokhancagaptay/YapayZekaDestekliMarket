from fastapi import APIRouter
from pydantic import BaseModel
from core.gemini_helper import suggest_recipe
from core.nutrition_analysis import analyze_nutrition  # ✅ Besin analizi fonksiyonu

router = APIRouter()

class IngredientInput(BaseModel):
    ingredients: str

@router.post("/suggest", summary="Tarif Öner", description="Mevcut malzemelerle tarif önerir.")
def get_recipe_suggestion(input_data: IngredientInput):
    suggestion = suggest_recipe(input_data.ingredients)
    return {"suggestion": suggestion}

@router.post("/analyze", summary="Besin Analizi", description="Malzeme listesine göre besin analizi yapar.")
def get_nutrition_analysis(input_data: IngredientInput):
    result = analyze_nutrition(input_data.ingredients)
    return {"analysis": result}
