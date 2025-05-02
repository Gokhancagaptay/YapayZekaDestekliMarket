import { useState } from 'react'
import { Box, Typography, Card, CardContent, CardActions, Button, Grid, CircularProgress } from '@mui/material'
import { useQuery } from 'react-query'
import axios from 'axios'

interface Recipe {
  id: string
  name: string
  ingredients: Array<{
    name: string
    quantity: number
    unit: string
  }>
  instructions: string[]
  cookingTime: number
  servings: number
  nutritionInfo: {
    calories: number
    protein: number
    carbs: number
    fat: number
  }
}

export default function RecipeSuggestions() {
  const [selectedRecipe, setSelectedRecipe] = useState<Recipe | null>(null)

  const { data: recipes, isLoading, error } = useQuery('recipes', async () => {
    const response = await axios.get('/api/recipes/suggest')
    return response.data
  })

  const handleAdjustServings = async (recipeId: string, servings: number) => {
    try {
      const response = await axios.post(`/api/recipes/${recipeId}/adjust`, { servings })
      setSelectedRecipe(response.data)
    } catch (error) {
      console.error('Error adjusting servings:', error)
    }
  }

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
        <CircularProgress />
      </Box>
    )
  }

  if (error) {
    return (
      <Box sx={{ p: 3 }}>
        <Typography color="error">Error loading recipe suggestions</Typography>
      </Box>
    )
  }

  return (
    <Box>
      <Typography variant="h6" gutterBottom>
        Suggested Recipes
      </Typography>
      <Grid container spacing={2}>
        {recipes?.map((recipe: Recipe) => (
          <Grid item xs={12} sm={6} key={recipe.id}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  {recipe.name}
                </Typography>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Cooking Time: {recipe.cookingTime} minutes
                </Typography>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Servings: {recipe.servings}
                </Typography>
                <Typography variant="body2" gutterBottom>
                  Calories: {recipe.nutritionInfo.calories} kcal
                </Typography>
              </CardContent>
              <CardActions>
                <Button size="small" onClick={() => setSelectedRecipe(recipe)}>
                  View Details
                </Button>
                <Button
                  size="small"
                  onClick={() => handleAdjustServings(recipe.id, recipe.servings + 1)}
                >
                  Increase Servings
                </Button>
                {recipe.servings > 1 && (
                  <Button
                    size="small"
                    onClick={() => handleAdjustServings(recipe.id, recipe.servings - 1)}
                  >
                    Decrease Servings
                  </Button>
                )}
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      {selectedRecipe && (
        <Box sx={{ mt: 3 }}>
          <Typography variant="h6" gutterBottom>
            {selectedRecipe.name} - Details
          </Typography>
          <Typography variant="subtitle1" gutterBottom>
            Ingredients:
          </Typography>
          <ul>
            {selectedRecipe.ingredients.map((ingredient, index) => (
              <li key={index}>
                {ingredient.quantity} {ingredient.unit} {ingredient.name}
              </li>
            ))}
          </ul>
          <Typography variant="subtitle1" gutterBottom>
            Instructions:
          </Typography>
          <ol>
            {selectedRecipe.instructions.map((instruction, index) => (
              <li key={index}>{instruction}</li>
            ))}
          </ol>
        </Box>
      )}
    </Box>
  )
} 