import numpy as np
import pandas as pd
from typing import List, Dict
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

class RecipeSuggestor:
    def __init__(self):
        self.recipes = []
        self.vectorizer = TfidfVectorizer()
        self.recipe_vectors = None
        
    def load_recipes(self, recipes_data: List[Dict]):
        """Load and preprocess recipe data"""
        self.recipes = recipes_data
        # Create a text representation of each recipe (ingredients + instructions)
        recipe_texts = [
            ' '.join(recipe['ingredients']) + ' ' + ' '.join(recipe['instructions'])
            for recipe in recipes_data
        ]
        self.recipe_vectors = self.vectorizer.fit_transform(recipe_texts)
    
    def suggest_recipes(self, available_ingredients: List[str], num_suggestions: int = 5) -> List[Dict]:
        """Suggest recipes based on available ingredients"""
        if not self.recipes or self.recipe_vectors is None:
            raise ValueError("No recipes loaded. Please load recipes first.")
            
        # Create a query vector from available ingredients
        query_text = ' '.join(available_ingredients)
        query_vector = self.vectorizer.transform([query_text])
        
        # Calculate similarity scores
        similarity_scores = cosine_similarity(query_vector, self.recipe_vectors).flatten()
        
        # Get top N suggestions
        top_indices = np.argsort(similarity_scores)[-num_suggestions:][::-1]
        
        return [self.recipes[i] for i in top_indices]
    
    def adjust_recipe_servings(self, recipe: Dict, target_servings: int) -> Dict:
        """Adjust recipe quantities based on target number of servings"""
        original_servings = recipe.get('servings', 1)
        scaling_factor = target_servings / original_servings
        
        adjusted_recipe = recipe.copy()
        adjusted_recipe['ingredients'] = [
            {
                **ingredient,
                'quantity': ingredient['quantity'] * scaling_factor
            }
            for ingredient in recipe['ingredients']
        ]
        adjusted_recipe['servings'] = target_servings
        
        return adjusted_recipe 