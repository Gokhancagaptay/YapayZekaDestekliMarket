import { Box, Typography, Card, CardContent, Grid, CircularProgress, Alert } from '@mui/material'
import { useQuery } from 'react-query'
import axios from 'axios'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js'
import { Bar } from 'react-chartjs-2'

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
)

interface NutritionData {
  nutrientIntake: {
    [key: string]: number
  }
  nutrientPercentages: {
    [key: string]: number
  }
  potentialDeficiencies: {
    [key: string]: boolean
  }
  recommendations: string[]
}

export default function NutritionAnalysis() {
  const { data, isLoading, error } = useQuery('nutrition', async () => {
    const response = await axios.get('/api/nutrition/analysis')
    return response.data
  })

  const nutritionData: NutritionData = data

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
        <Typography color="error">Error loading nutrition data</Typography>
      </Box>
    )
  }

  const chartData = {
    labels: Object.keys(nutritionData?.nutrientPercentages || {}),
    datasets: [
      {
        label: 'Daily Intake (%)',
        data: Object.values(nutritionData?.nutrientPercentages || {}),
        backgroundColor: 'rgba(25, 118, 210, 0.5)',
        borderColor: 'rgb(25, 118, 210)',
        borderWidth: 1,
      },
    ],
  }

  const chartOptions = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top' as const,
      },
      title: {
        display: true,
        text: 'Daily Nutrient Intake',
      },
    },
    scales: {
      y: {
        beginAtZero: true,
        max: 200,
      },
    },
  }

  return (
    <Box>
      <Typography variant="h6" gutterBottom>
        Nutrition Analysis
      </Typography>
      
      <Grid container spacing={2}>
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Bar data={chartData} options={chartOptions} />
            </CardContent>
          </Card>
        </Grid>

        {nutritionData?.recommendations.map((recommendation, index) => (
          <Grid item xs={12} key={index}>
            <Alert severity="info">{recommendation}</Alert>
          </Grid>
        ))}

        {Object.entries(nutritionData?.potentialDeficiencies || {}).map(([nutrient, isDeficient]) => (
          isDeficient && (
            <Grid item xs={12} key={nutrient}>
              <Alert severity="warning">
                {`Low ${nutrient.replace('_', ' ')} intake: ${nutritionData.nutrientPercentages[nutrient].toFixed(1)}% of daily recommended value`}
              </Alert>
            </Grid>
          )
        ))}
      </Grid>
    </Box>
  )
} 