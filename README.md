# Online Market AI Assistant

An AI-powered online market assistant that helps users manage their shopping, track consumption habits, and receive personalized recommendations.

## Features

- 🛒 Smart stock management
- 📝 AI-powered recipe suggestions based on available ingredients
- 🥗 Nutrition analysis and vitamin deficiency warnings
- 🔄 Real-time synchronization across devices
- 📱 Cross-platform support (Web & Mobile)
- 🤖 AI-driven shopping recommendations
- 🏥 Health tracking integration (Google Fit)

## Project Structure

```
.
├── backend/           # FastAPI backend service
├── frontend/         # Next.js web application
├── market_mobile/    # React Native mobile application
├── ai_modules/       # AI and ML models
├── database_scripts/ # Database setup and migrations
└── docs/            # Project documentation
```

## Technical Stack

### Backend
- FastAPI (Python)
- Firebase Authentication
- MongoDB (Main Database)
- Firebase Firestore (Real-time sync)
- AWS EC2 (Hosting)

### Frontend
- Next.js
- React
- Firebase Hosting

### Mobile
- React Native
- Firebase Cloud Messaging

### AI/ML
- TensorFlow/PyTorch
- Scikit-learn
- TensorFlow Lite (Mobile)

## Getting Started

### Prerequisitesy
- Node.js (v16+)
- Python (v3.8+)
- MongoDB
- Firebase account
- AWS account

### Installation

1. Clone the repository:
```bash
git clone [repository-url]
```

2. Install backend dependencies:
```bash
cd backend
pip install -r requirements.txt
```

3. Install frontend dependencies:
```bash
cd frontend
npm install
```

4. Install mobile app dependencies:
```bash
cd market_mobile
npm install
```

### Environment Setup

1. Create `.env` files in each directory with appropriate credentials
2. Set up Firebase project and add configuration
3. Configure MongoDB connection
4. Set up AWS credentials

## Development

### Running the Backend
```bash
cd backend
uvicorn main:app --reload
```

### Running the Frontend
```bash
cd frontend
npm run dev
```

### Running the Mobile App
```bash
cd market_mobile
npm run android  # or npm run ios
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

[Your Name] - [Your Email]

Project Link: [https://github.com/yourusername/online-market-ai](https://github.com/yourusername/online-market-ai) 