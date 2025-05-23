import { useState } from 'react'
import { Box, Typography, Card, CardContent, CardActions, Button, Grid, CircularProgress, Select, MenuItem, FormControl, InputLabel } from '@mui/material'
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
  const [breakfastType, setBreakfastType] = useState<string>('quick')
  const [dinnerType, setDinnerType] = useState<string>('quick')
  const [breakfastSuggestion, setBreakfastSuggestion] = useState<string>('')
  const [dinnerSuggestion, setDinnerSuggestion] = useState<string>('')
  const [loading, setLoading] = useState<boolean>(false)

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

  const handleBreakfastSuggestion = async () => {
    try {
      setLoading(true)
      const response = await axios.post('/api/recipes/breakfast-suggest', {
        recipe_type: breakfastType
      })
      setBreakfastSuggestion(response.data.suggestion)
    } catch (error) {
      console.error('Error getting breakfast suggestion:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleDinnerSuggestion = async () => {
    try {
      setLoading(true)
      const response = await axios.post('/api/recipes/dinner-suggest', {
        suggestion_type: dinnerType
      })
      setDinnerSuggestion(response.data.suggestion)
    } catch (error) {
      console.error('Error getting dinner suggestion:', error)
    } finally {
      setLoading(false)
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
        Tarif Önerileri
      </Typography>

      {/* Kahvaltı Önerisi */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h6" gutterBottom>
          Kahvaltı Önerisi
        </Typography>
        <FormControl sx={{ minWidth: 200, mb: 2 }}>
          <InputLabel>Kahvaltı Tipi</InputLabel>
          <Select
            value={breakfastType}
            label="Kahvaltı Tipi"
            onChange={(e) => setBreakfastType(e.target.value)}
          >
            <MenuItem value="quick">Hızlı</MenuItem>
            <MenuItem value="eggy">Yumurtalı</MenuItem>
            <MenuItem value="breadless">Ekmeksiz</MenuItem>
            <MenuItem value="sweet">Tatlı</MenuItem>
            <MenuItem value="light">Hafif</MenuItem>
            <MenuItem value="cold">Soğuk</MenuItem>
          </Select>
        </FormControl>
        <Button 
          variant="contained" 
          onClick={handleBreakfastSuggestion}
          disabled={loading}
          sx={{ ml: 2 }}
        >
          Kahvaltı Önerisi Al
        </Button>
        {breakfastSuggestion && (
          <Typography sx={{ mt: 2, whiteSpace: 'pre-line' }}>
            {breakfastSuggestion}
          </Typography>
        )}
      </Box>

      {/* Akşam Yemeği Önerisi */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h6" gutterBottom>
          Akşam Yemeği Önerisi
        </Typography>
        <FormControl sx={{ minWidth: 200, mb: 2 }}>
          <InputLabel>Yemek Tipi</InputLabel>
          <Select
            value={dinnerType}
            label="Yemek Tipi"
            onChange={(e) => setDinnerType(e.target.value)}
          >
            <MenuItem value="quick">Hızlı</MenuItem>
            <MenuItem value="medium">Orta Süreli</MenuItem>
            <MenuItem value="long">Uzun Süreli</MenuItem>
            <MenuItem value="meatless">Etsiz</MenuItem>
            <MenuItem value="soupy">Çorbalı</MenuItem>
            <MenuItem value="onepan">Tek Tencere</MenuItem>
          </Select>
        </FormControl>
        <Button 
          variant="contained" 
          onClick={handleDinnerSuggestion}
          disabled={loading}
          sx={{ ml: 2 }}
        >
          Akşam Yemeği Önerisi Al
        </Button>
        {dinnerSuggestion && (
          <Typography sx={{ mt: 2, whiteSpace: 'pre-line' }}>
            {dinnerSuggestion}
          </Typography>
        )}
      </Box>

      {/* Mevcut tarif önerileri */}
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