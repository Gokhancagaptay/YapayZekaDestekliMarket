'use client'

import { Container, Typography, Box, Grid, Paper } from '@mui/material'
import { useAuth } from '@/hooks/useAuth'
import StockOverview from '@/components/StockOverview'
import RecipeSuggestions from '@/components/RecipeSuggestions'
import NutritionAnalysis from '@/components/NutritionAnalysis'
import ShoppingList from '@/components/ShoppingList'

export default function Home() {
  const { user, loading } = useAuth()

  if (loading) {
    return (
      <Container>
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh' }}>
          <Typography>Loading...</Typography>
        </Box>
      </Container>
    )
  }

  if (!user) {
    return (
      <Container>
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh' }}>
          <Typography variant="h4">Please sign in to access your dashboard</Typography>
        </Box>
      </Container>
    )
  }

  return (
    <Container maxWidth="xl">
      <Box sx={{ my: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Welcome back, {user.displayName || 'User'}!
        </Typography>
        
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <Paper sx={{ p: 3, height: '100%' }}>
              <StockOverview />
            </Paper>
          </Grid>
          
          <Grid item xs={12} md={6}>
            <Paper sx={{ p: 3, height: '100%' }}>
              <RecipeSuggestions />
            </Paper>
          </Grid>
          
          <Grid item xs={12} md={6}>
            <Paper sx={{ p: 3, height: '100%' }}>
              <NutritionAnalysis />
            </Paper>
          </Grid>
          
          <Grid item xs={12} md={6}>
            <Paper sx={{ p: 3, height: '100%' }}>
              <ShoppingList />
            </Paper>
          </Grid>
        </Grid>
      </Box>
    </Container>
  )
} 