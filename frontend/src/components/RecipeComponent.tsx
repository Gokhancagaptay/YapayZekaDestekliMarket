import React, { useState } from 'react';
import axios from 'axios';
import './Recipe.css';

interface RecipeComponentProps {
  token: string;
  API_URL: string;
}

const RecipeComponent: React.FC<RecipeComponentProps> = ({ token, API_URL }) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<string | null>(null);

  // Kahvaltı önerileri
  const handleBreakfastSuggestion = async (type: string) => {
    try {
      setLoading(true);
      setError(null);
      const response = await axios.post(
        `${API_URL}/api/recipes/breakfast`,
        { recipe_type: type },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setResult(response.data.recipe);
    } catch (error: any) {
      setError(error.response?.data?.detail || "Bir hata oluştu");
    } finally {
      setLoading(false);
    }
  };

  // Akşam yemeği önerileri
  const handleDinnerSuggestion = async (type: string) => {
    try {
      setLoading(true);
      setError(null);
      const response = await axios.post(
        `${API_URL}/api/recipes/dinner`,
        { recipe_type: type },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setResult(response.data.recipe);
    } catch (error: any) {
      setError(error.response?.data?.detail || "Bir hata oluştu");
    } finally {
      setLoading(false);
    }
  };

  // Atıştırmalık önerileri
  const handleSnackSuggestion = async (type: string) => {
    try {
      setLoading(true);
      setError(null);
      const response = await axios.post(
        `${API_URL}/api/snacks/suggest`,
        { snack_type: type },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setResult(response.data.suggestion);
    } catch (error: any) {
      setError(error.response?.data?.detail || "Bir hata oluştu");
    } finally {
      setLoading(false);
    }
  };

  // Beslenme analizi
  const handleNutritionAnalysis = async (type: string) => {
    try {
      setLoading(true);
      setError(null);
      const response = await axios.post(
        `${API_URL}/api/snacks/analyze`,
        { analysis_type: type },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setResult(response.data.analysis);
    } catch (error: any) {
      setError(error.response?.data?.detail || "Bir hata oluştu");
    } finally {
      setLoading(false);
    }
  };

  // Alışveriş önerileri
  const handleShoppingSuggestion = async (type: string) => {
    try {
      setLoading(true);
      setError(null);
      const response = await axios.post(
        `${API_URL}/api/snacks/shopping`,
        { list_type: type },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setResult(response.data.suggestion);
    } catch (error: any) {
      setError(error.response?.data?.detail || "Bir hata oluştu");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="recipe-container">
      {/* Kahvaltı Bölümü */}
      <div className="recipe-section">
        <h2>🍳 Kahvaltı Önerileri</h2>
        <div className="button-grid">
          <button onClick={() => handleBreakfastSuggestion("quick")}>
            Pratik Kahvaltı
          </button>
          <button onClick={() => handleBreakfastSuggestion("eggy")}>
            Yumurtalı Kahvaltı
          </button>
          <button onClick={() => handleBreakfastSuggestion("breadless")}>
            Ekmeksiz Kahvaltı
          </button>
          <button onClick={() => handleBreakfastSuggestion("sweet")}>
            Tatlı Kahvaltı
          </button>
          <button onClick={() => handleBreakfastSuggestion("light")}>
            Hafif Kahvaltı
          </button>
          <button onClick={() => handleBreakfastSuggestion("cold")}>
            Soğuk Kahvaltı
          </button>
        </div>
      </div>

      {/* Akşam Yemeği Bölümü */}
      <div className="recipe-section">
        <h2>🍽️ Akşam Yemeği Önerileri</h2>
        <div className="button-grid">
          <button onClick={() => handleDinnerSuggestion("quick")}>
            Pratik Akşam Yemeği
          </button>
          <button onClick={() => handleDinnerSuggestion("medium")}>
            Orta Zorlukta Yemek
          </button>
          <button onClick={() => handleDinnerSuggestion("long")}>
            Özel Tarif
          </button>
          <button onClick={() => handleDinnerSuggestion("meatless")}>
            Etsiz Yemek
          </button>
          <button onClick={() => handleDinnerSuggestion("soupy")}>
            Çorba Ağırlıklı
          </button>
          <button onClick={() => handleDinnerSuggestion("onepan")}>
            Tek Kap Yemek
          </button>
        </div>
      </div>

      {/* Atıştırmalık Bölümü */}
      <div className="recipe-section">
        <h2>🍿 Atıştırmalık Fikirleri</h2>
        <div className="button-grid">
          <button onClick={() => handleSnackSuggestion("sweet")}>
            Tatlı Atıştırmalık
          </button>
          <button onClick={() => handleSnackSuggestion("salty")}>
            Tuzlu Atıştırmalık
          </button>
          <button onClick={() => handleSnackSuggestion("no_cooking")}>
            Fırın/Ocaksız Tarif
          </button>
          <button onClick={() => handleSnackSuggestion("movie_night")}>
            Film/Gece Atıştırması
          </button>
          <button onClick={() => handleSnackSuggestion("diet_friendly")}>
            Diyet Dostu Atıştırmalık
          </button>
          <button onClick={() => handleSnackSuggestion("quick")}>
            5 Dakikada Hazırlanabilen
          </button>
        </div>
      </div>

      {/* Alışveriş Önerileri Bölümü */}
      <div className="recipe-section">
        <h2>🛒 Alışveriş Listesi Tavsiyesi</h2>
        <div className="button-grid">
          <button onClick={() => handleShoppingSuggestion("basic_needs")}>
            Stoğuma Göre Eksikler
          </button>
          <button onClick={() => handleShoppingSuggestion("three_day_plan")}>
            3 Gün Yetecek Plan
          </button>
          <button onClick={() => handleShoppingSuggestion("breakfast_essentials")}>
            Kahvaltılık Eksikler
          </button>
          <button onClick={() => handleShoppingSuggestion("essential_items")}>
            Temel İhtiyaç Listesi
          </button>
          <button onClick={() => handleShoppingSuggestion("protein_focused")}>
            Protein Ağırlıklı Alışveriş
          </button>
          <button onClick={() => handleShoppingSuggestion("clean_eating")}>
            Haftalık "Temiz Beslenme" Listesi
          </button>
        </div>
      </div>

      {/* Sağlık Önerileri Bölümü */}
      <div className="recipe-section">
        <h2>🩺 Stoğuma Göre Kişisel Sağlık</h2>
        <div className="button-grid">
          <button onClick={() => handleNutritionAnalysis("balance")}>
            Stoğumun Besin Dengesi
          </button>
          <button onClick={() => handleNutritionAnalysis("carb_protein")}>
            Karbonhidrat/Protein Oranı
          </button>
          <button onClick={() => handleNutritionAnalysis("veggie_recipe")}>
            Sebze Ağırlıklı Tarif
          </button>
          <button onClick={() => handleNutritionAnalysis("low_calorie")}>
            Düşük Kalorili Tarif
          </button>
          <button onClick={() => handleNutritionAnalysis("immune_boost")}>
            Bağışıklık Güçlendirici
          </button>
          <button onClick={() => handleNutritionAnalysis("post_workout")}>
            Egzersiz Sonrası Yemek
          </button>
          <button onClick={() => handleNutritionAnalysis("calorie_specific")}>
            Günlük Kaloriye Uygun
          </button>
          <button onClick={() => handleNutritionAnalysis("vitamin_rich")}>
            Vitamin Açısından Zengin
          </button>
        </div>
      </div>

      {/* Sonuç ve Hata Gösterimi */}
      {loading && (
        <div className="loading">
          <div className="loading-spinner"></div>
          <p>Yanıt bekleniyor...</p>
        </div>
      )}

      {error && (
        <div className="error-message">
          {error}
        </div>
      )}

      {result && !loading && (
        <div className="result-container">
          {result}
        </div>
      )}
    </div>
  );
};

export default RecipeComponent; 