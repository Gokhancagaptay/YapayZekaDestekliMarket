import { useState, useEffect } from 'react'
import { Box, Typography, List, ListItem, ListItemText, ListItemIcon, IconButton, CircularProgress } from '@mui/material'
import { Inventory as InventoryIcon, Add as AddIcon, Remove as RemoveIcon } from '@mui/icons-material'
import { useQuery } from 'react-query'
import axios from 'axios'

interface StockItem {
  id: string
  name: string
  quantity: number
  unit: string
  category: string
  expiryDate?: string
}

export default function StockOverview() {
  const [stockItems, setStockItems] = useState<StockItem[]>([])

  const { data, isLoading, error } = useQuery('stock', async () => {
    const response = await axios.get('/api/stock')
    return response.data
  })

  useEffect(() => {
    if (data) {
      setStockItems(data)
    }
  }, [data])

  const handleUpdateQuantity = async (itemId: string, change: number) => {
    try {
      await axios.patch(`/api/stock/${itemId}`, { change })
      setStockItems(prevItems =>
        prevItems.map(item =>
          item.id === itemId
            ? { ...item, quantity: Math.max(0, item.quantity + change) }
            : item
        )
      )
    } catch (error) {
      console.error('Error updating quantity:', error)
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
        <Typography color="error">Error loading stock data</Typography>
      </Box>
    )
  }

  return (
    <Box>
      <Typography variant="h6" gutterBottom>
        Current Stock
      </Typography>
      <List>
        {stockItems.map((item) => (
          <ListItem
            key={item.id}
            secondaryAction={
              <Box>
                <IconButton
                  edge="end"
                  aria-label="decrease"
                  onClick={() => handleUpdateQuantity(item.id, -1)}
                >
                  <RemoveIcon />
                </IconButton>
                <IconButton
                  edge="end"
                  aria-label="increase"
                  onClick={() => handleUpdateQuantity(item.id, 1)}
                >
                  <AddIcon />
                </IconButton>
              </Box>
            }
          >
            <ListItemIcon>
              <InventoryIcon />
            </ListItemIcon>
            <ListItemText
              primary={item.name}
              secondary={`${item.quantity} ${item.unit} - ${item.category}`}
            />
          </ListItem>
        ))}
      </List>
    </Box>
  )
} 