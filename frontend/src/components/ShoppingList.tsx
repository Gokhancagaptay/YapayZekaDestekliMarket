import { useState } from 'react'
import {
  Box,
  Typography,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  TextField,
  Button,
  Checkbox,
  Paper,
} from '@mui/material'
import { Add as AddIcon, Delete as DeleteIcon } from '@mui/icons-material'
import { useQuery, useMutation, useQueryClient } from 'react-query'
import axios from 'axios'

interface ShoppingItem {
  id: string
  name: string
  quantity: number
  unit: string
  category: string
  completed: boolean
}

export default function ShoppingList() {
  const [newItem, setNewItem] = useState('')
  const [newQuantity, setNewQuantity] = useState('')
  const [newUnit, setNewUnit] = useState('')
  const queryClient = useQueryClient()

  const { data: items, isLoading } = useQuery('shoppingList', async () => {
    const response = await axios.get('/api/shopping-list')
    return response.data
  })

  const addMutation = useMutation(
    (newItem: Omit<ShoppingItem, 'id' | 'completed'>) =>
      axios.post('/api/shopping-list', newItem),
    {
      onSuccess: () => {
        queryClient.invalidateQueries('shoppingList')
        setNewItem('')
        setNewQuantity('')
        setNewUnit('')
      },
    }
  )

  const deleteMutation = useMutation(
    (id: string) => axios.delete(`/api/shopping-list/${id}`),
    {
      onSuccess: () => {
        queryClient.invalidateQueries('shoppingList')
      },
    }
  )

  const toggleMutation = useMutation(
    ({ id, completed }: { id: string; completed: boolean }) =>
      axios.patch(`/api/shopping-list/${id}`, { completed }),
    {
      onSuccess: () => {
        queryClient.invalidateQueries('shoppingList')
      },
    }
  )

  const handleAddItem = () => {
    if (newItem && newQuantity && newUnit) {
      addMutation.mutate({
        name: newItem,
        quantity: Number(newQuantity),
        unit: newUnit,
        category: 'uncategorized',
      })
    }
  }

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
        <Typography>Loading shopping list...</Typography>
      </Box>
    )
  }

  return (
    <Box>
      <Typography variant="h6" gutterBottom>
        Shopping List
      </Typography>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
          <TextField
            label="Item"
            value={newItem}
            onChange={(e) => setNewItem(e.target.value)}
            size="small"
          />
          <TextField
            label="Quantity"
            type="number"
            value={newQuantity}
            onChange={(e) => setNewQuantity(e.target.value)}
            size="small"
            sx={{ width: 100 }}
          />
          <TextField
            label="Unit"
            value={newUnit}
            onChange={(e) => setNewUnit(e.target.value)}
            size="small"
            sx={{ width: 100 }}
          />
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={handleAddItem}
          >
            Add
          </Button>
        </Box>
      </Paper>

      <List>
        {items?.map((item: ShoppingItem) => (
          <ListItem
            key={item.id}
            divider
            sx={{
              textDecoration: item.completed ? 'line-through' : 'none',
              opacity: item.completed ? 0.7 : 1,
            }}
          >
            <Checkbox
              edge="start"
              checked={item.completed}
              onChange={() =>
                toggleMutation.mutate({
                  id: item.id,
                  completed: !item.completed,
                })
              }
            />
            <ListItemText
              primary={item.name}
              secondary={`${item.quantity} ${item.unit}`}
            />
            <ListItemSecondaryAction>
              <IconButton
                edge="end"
                aria-label="delete"
                onClick={() => deleteMutation.mutate(item.id)}
              >
                <DeleteIcon />
              </IconButton>
            </ListItemSecondaryAction>
          </ListItem>
        ))}
      </List>
    </Box>
  )
} 