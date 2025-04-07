from fastapi import APIRouter
from pydantic import BaseModel
from core.gemini_helper import suggest_recipe

router = APIRouter()

class IngredientInput(BaseModel):
    ingredients: str

@router.post("/suggest", summary="Tarif Öner", description="Mevcut malzemelerle tarif önerir.")
def get_recipe_suggestion(input_data: IngredientInput):
    suggestion = suggest_recipe(input_data.ingredients)
    return {"suggestion": suggestion}
