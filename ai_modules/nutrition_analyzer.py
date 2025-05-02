import pandas as pd
import numpy as np
from typing import List, Dict, Optional
from datetime import datetime, timedelta

class NutritionAnalyzer:
    def __init__(self):
        # Daily recommended values for various nutrients (in mg unless specified)
        self.daily_recommendations = {
            'vitamin_a': 900,  # mcg
            'vitamin_c': 90,
            'vitamin_d': 15,   # mcg
            'vitamin_e': 15,
            'vitamin_k': 120,  # mcg
            'thiamin': 1.2,
            'riboflavin': 1.3,
            'niacin': 16,
            'vitamin_b6': 1.7,
            'folate': 400,     # mcg
            'vitamin_b12': 2.4, # mcg
            'calcium': 1000,
            'iron': 18,
            'magnesium': 400,
            'phosphorus': 700,
            'potassium': 4700,
            'sodium': 2300,
            'zinc': 11
        }
        
        # Food database with nutritional information
        self.food_database = pd.DataFrame()
        
    def load_food_database(self, food_data: List[Dict]):
        """Load and preprocess food nutritional data"""
        self.food_database = pd.DataFrame(food_data)
        
    def analyze_consumption(self, 
                          consumed_foods: List[Dict], 
                          time_period: str = 'week') -> Dict:
        """Analyze nutritional intake over a specified time period"""
        if self.food_database.empty:
            raise ValueError("Food database not loaded. Please load food data first.")
            
        # Convert consumed foods to DataFrame
        consumption_df = pd.DataFrame(consumed_foods)
        
        # Merge with food database to get nutritional information
        merged_df = pd.merge(consumption_df, self.food_database, on='food_id')
        
        # Calculate total nutrient intake
        nutrient_intake = {}
        for nutrient in self.daily_recommendations.keys():
            if nutrient in merged_df.columns:
                nutrient_intake[nutrient] = merged_df[nutrient].sum()
                
        # Calculate percentage of daily recommendations
        nutrient_percentages = {
            nutrient: (intake / self.daily_recommendations[nutrient]) * 100
            for nutrient, intake in nutrient_intake.items()
        }
        
        # Identify potential deficiencies
        deficiencies = {
            nutrient: percentage < 80  # Less than 80% of recommended intake
            for nutrient, percentage in nutrient_percentages.items()
        }
        
        return {
            'nutrient_intake': nutrient_intake,
            'nutrient_percentages': nutrient_percentages,
            'potential_deficiencies': deficiencies
        }
    
    def generate_recommendations(self, 
                               analysis_results: Dict,
                               user_preferences: Optional[Dict] = None) -> List[str]:
        """Generate personalized nutrition recommendations"""
        recommendations = []
        
        # Check for deficiencies
        for nutrient, is_deficient in analysis_results['potential_deficiencies'].items():
            if is_deficient:
                recommendations.append(
                    f"Consider increasing intake of {nutrient.replace('_', ' ').title()}. "
                    f"Current intake is {analysis_results['nutrient_percentages'][nutrient]:.1f}% "
                    "of recommended daily value."
                )
        
        # Add general recommendations based on analysis
        if analysis_results['nutrient_percentages'].get('sodium', 0) > 100:
            recommendations.append(
                "Your sodium intake is above recommended levels. "
                "Consider reducing processed food consumption."
            )
            
        if analysis_results['nutrient_percentages'].get('fiber', 0) < 80:
            recommendations.append(
                "Consider adding more whole grains, fruits, and vegetables "
                "to increase fiber intake."
            )
            
        return recommendations
    
    def predict_future_deficiencies(self,
                                  consumption_history: List[Dict],
                                  forecast_days: int = 30) -> Dict:
        """Predict potential nutrient deficiencies based on consumption patterns"""
        # Convert history to time series
        history_df = pd.DataFrame(consumption_history)
        history_df['date'] = pd.to_datetime(history_df['date'])
        
        # Calculate daily averages
        daily_averages = history_df.groupby('date').mean()
        
        # Simple linear projection (can be replaced with more sophisticated models)
        projected_deficiencies = {}
        for nutrient in self.daily_recommendations.keys():
            if nutrient in daily_averages.columns:
                current_level = daily_averages[nutrient].mean()
                projected_level = current_level * forecast_days
                projected_deficiencies[nutrient] = projected_level < self.daily_recommendations[nutrient]
                
        return projected_deficiencies 