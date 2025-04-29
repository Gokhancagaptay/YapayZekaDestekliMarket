from fastapi import APIRouter
from pydantic import BaseModel
from core.gemini_helper import suggest_recipe, analyze_recipe

router = APIRouter()

class IngredientInput(BaseModel):
    ingredients: str

@router.post("/suggest", summary="Tarif Öner", description="Mevcut malzemelerle tarif önerir.")
def get_recipe_suggestion(input_data: IngredientInput):
    suggestion = suggest_recipe(input_data.ingredients)
    return {"suggestion": suggestion}

@router.post("/analyze", summary="Besin Analizi", description="Mevcut malzemelerle yapılacak bir yemeğin besin analizi ve sağlık değerlendirmesi.")
def get_nutrition_analysis(input_data: IngredientInput):
    analysis = analyze_recipe(input_data.ingredients)
    return {"analysis": analysis}
from fastapi import APIRouter
from pydantic import BaseModel
from core.gemini_helper import suggest_recipe, analyze_recipe

router = APIRouter()

class IngredientInput(BaseModel):
    ingredients: str

@router.post("/suggest", summary="Tarif Öner", description="Mevcut malzemelerle tarif önerir.")
def get_recipe_suggestion(input_data: IngredientInput):
    suggestion = suggest_recipe(input_data.ingredients)
    return {"suggestion": suggestion}

@router.post("/analyze", summary="Besin Analizi", description="Mevcut malzemelerle yapılacak bir yemeğin besin analizi ve sağlık değerlendirmesi.")
def get_nutrition_analysis(input_data: IngredientInput):
    analysis = analyze_recipe(input_data.ingredients)
    return {"analysis": analysis}
