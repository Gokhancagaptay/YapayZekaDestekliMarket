from fastapi import APIRouter, Depends, HTTPException, Body
from pydantic import BaseModel
from typing import List, Literal
from core.gemini_helper import suggest_snack, analyze_nutrition, suggest_shopping, answer_custom_question
from database import get_stock_items
from api.user import verify_token

router = APIRouter()

print("🔧 Snack router oluşturuldu")

class SnackRequest(BaseModel):
    snack_type: Literal["sweet", "salty", "no_cooking", "movie_night", "diet_friendly", "quick"]

class NutritionRequest(BaseModel):
    analysis_type: Literal["balance", "carb_protein", "veggie_recipe", "low_calorie", "immune_boost", 
                         "post_workout", "calorie_specific", "vitamin_rich"]

class ShoppingRequest(BaseModel):
    list_type: Literal["basic_needs", "three_day_plan", "breakfast_essentials", "essential_items", 
                      "protein_focused", "clean_eating"]

class CustomQuestionRequest(BaseModel):
    question: str

@router.post("/suggest", summary="Atıştırmalık Önerisi", description="Kullanıcının stoğuna göre atıştırmalık tarifi önerir.")
async def snack_suggestion(
    request: SnackRequest = Body(...),
    user_data: tuple = Depends(verify_token)
):
    try:
        print("🔍 Atıştırmalık önerisi isteği alındı")
        print(f"📦 Gelen veri: {request}")
        
        # Tuple'dan user ve role bilgisini al
        if not user_data or len(user_data) != 2:
            print("❌ Geçersiz kullanıcı verisi")
            raise HTTPException(
                status_code=401,
                detail="Geçersiz kullanıcı verisi"
            )
            
        user, role = user_data
        
        # User nesnesinden uid kontrolü
        if not user or not isinstance(user, dict) or 'uid' not in user:
            print("❌ Kullanıcı uid'si bulunamadı")
            raise HTTPException(
                status_code=400,
                detail="Kullanıcı bilgileri eksik"
            )
            
        uid = user['uid']
        print(f"👤 İşlem yapılan kullanıcı uid: {uid}")
        
        # Stok verilerini getir
        stock_items = await get_stock_items(uid, by_uid=True)
        
        if not stock_items:
            print("❌ Kullanıcının stoğunda ürün bulunamadı")
            raise HTTPException(
                status_code=400,
                detail="Stokta ürün bulunamadı. Lütfen önce stok ekleyiniz."
            )
            
        print(f"📦 Stok verileri başarıyla getirildi: {stock_items}")
        
        # Stock items'ı işle
        stock_names = []
        if isinstance(stock_items, dict):
            for item in stock_items.values():
                if isinstance(item, dict) and 'name' in item:
                    stock_names.append(item['name'])
        
        if not stock_names:
            print("❌ Stok verilerinden ürün isimleri çıkarılamadı")
            raise HTTPException(
                status_code=400,
                detail="Stok verilerinde geçerli ürün bulunamadı"
            )
            
        print(f"📝 İşlenmiş ürün isimleri: {stock_names}")
        
        # Gemini API'ye gönder
        suggestion = suggest_snack(stock_names, request.snack_type)
        
        if not suggestion:
            raise HTTPException(
                status_code=500,
                detail="Öneri oluşturulamadı"
            )
        
        print(f"✅ Atıştırmalık önerisi başarıyla oluşturuldu")
        return {"suggestion": suggestion}
        
    except HTTPException as he:
        print(f"⚠️ HTTP Hatası: {str(he)}")
        raise he
    except Exception as e:
        print(f"❌ Beklenmeyen hata: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Bir hata oluştu: {str(e)}"
        )

@router.post("/analyze", summary="Beslenme Analizi", description="Kullanıcının stoğuna göre beslenme analizi yapar.")
async def nutrition_analysis(
    request: NutritionRequest = Body(...),
    user_data: tuple = Depends(verify_token)
):
    try:
        print("🔍 Beslenme analizi isteği alındı")
        print(f"📦 Gelen veri: {request}")
        
        # Tuple'dan user ve role bilgisini al
        if not user_data or len(user_data) != 2:
            print("❌ Geçersiz kullanıcı verisi")
            raise HTTPException(
                status_code=401,
                detail="Geçersiz kullanıcı verisi"
            )
            
        user, role = user_data
        
        # User nesnesinden uid kontrolü
        if not user or not isinstance(user, dict) or 'uid' not in user:
            print("❌ Kullanıcı uid'si bulunamadı")
            raise HTTPException(
                status_code=400,
                detail="Kullanıcı bilgileri eksik"
            )
            
        uid = user['uid']
        print(f"👤 İşlem yapılan kullanıcı uid: {uid}")
        
        # Stok verilerini getir
        stock_items = await get_stock_items(uid, by_uid=True)
        
        if not stock_items:
            print("❌ Kullanıcının stoğunda ürün bulunamadı")
            raise HTTPException(
                status_code=400,
                detail="Stokta ürün bulunamadı. Lütfen önce stok ekleyiniz."
            )
            
        print(f"📦 Stok verileri başarıyla getirildi: {stock_items}")
        
        # Stock items'ı işle
        stock_names = []
        if isinstance(stock_items, dict):
            for item in stock_items.values():
                if isinstance(item, dict) and 'name' in item:
                    stock_names.append(item['name'])
        
        if not stock_names:
            print("❌ Stok verilerinden ürün isimleri çıkarılamadı")
            raise HTTPException(
                status_code=400,
                detail="Stok verilerinde geçerli ürün bulunamadı"
            )
            
        print(f"📝 İşlenmiş ürün isimleri: {stock_names}")
        
        # Gemini API'ye gönder
        analysis = analyze_nutrition(stock_names, request.analysis_type)
        
        if not analysis:
            raise HTTPException(
                status_code=500,
                detail="Analiz oluşturulamadı"
            )
        
        print(f"✅ Beslenme analizi başarıyla oluşturuldu")
        return {"analysis": analysis}
        
    except HTTPException as he:
        print(f"⚠️ HTTP Hatası: {str(he)}")
        raise he
    except Exception as e:
        print(f"❌ Beklenmeyen hata: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Bir hata oluştu: {str(e)}"
        )

@router.post("/shopping", summary="Alışveriş Önerisi", description="Kullanıcının stoğuna göre alışveriş önerileri sunar.")
async def shopping_suggestion(
    request: ShoppingRequest = Body(...),
    user_data: tuple = Depends(verify_token)
):
    try:
        print("🔍 Alışveriş önerisi isteği alındı")
        print(f"📦 Gelen veri: {request}")
        
        # Tuple'dan user ve role bilgisini al
        if not user_data or len(user_data) != 2:
            print("❌ Geçersiz kullanıcı verisi")
            raise HTTPException(
                status_code=401,
                detail="Geçersiz kullanıcı verisi"
            )
            
        user, role = user_data
        
        # User nesnesinden uid kontrolü
        if not user or not isinstance(user, dict) or 'uid' not in user:
            print("❌ Kullanıcı uid'si bulunamadı")
            raise HTTPException(
                status_code=400,
                detail="Kullanıcı bilgileri eksik"
            )
            
        uid = user['uid']
        print(f"👤 İşlem yapılan kullanıcı uid: {uid}")
        
        # Stok verilerini getir
        stock_items = await get_stock_items(uid, by_uid=True)
        
        if not stock_items:
            print("❌ Kullanıcının stoğunda ürün bulunamadı")
            raise HTTPException(
                status_code=400,
                detail="Stokta ürün bulunamadı. Lütfen önce stok ekleyiniz."
            )
            
        print(f"📦 Stok verileri başarıyla getirildi: {stock_items}")
        
        # Stock items'ı işle
        stock_names = []
        if isinstance(stock_items, dict):
            for item in stock_items.values():
                if isinstance(item, dict) and 'name' in item:
                    stock_names.append(item['name'])
        
        if not stock_names:
            print("❌ Stok verilerinden ürün isimleri çıkarılamadı")
            raise HTTPException(
                status_code=400,
                detail="Stok verilerinde geçerli ürün bulunamadı"
            )
            
        print(f"📝 İşlenmiş ürün isimleri: {stock_names}")
        
        # Gemini API'ye gönder
        suggestion = suggest_shopping(stock_names, request.list_type)
        
        if not suggestion:
            raise HTTPException(
                status_code=500,
                detail="Öneri oluşturulamadı"
            )
        
        print(f"✅ Alışveriş önerisi başarıyla oluşturuldu")
        return {"suggestion": suggestion}
        
    except HTTPException as he:
        print(f"⚠️ HTTP Hatası: {str(he)}")
        raise he
    except Exception as e:
        print(f"❌ Beklenmeyen hata: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Bir hata oluştu: {str(e)}"
        )

@router.post("/custom", summary="Özel Soru", description="Kullanıcının özel sorusunu yanıtlar.")
async def custom_question(
    request: CustomQuestionRequest = Body(...),
    user_data: tuple = Depends(verify_token)
):
    try:
        print("🔍 Özel soru isteği alındı")
        print(f"📦 Gelen veri: {request}")
        
        # Tuple'dan user ve role bilgisini al
        if not user_data or len(user_data) != 2:
            print("❌ Geçersiz kullanıcı verisi")
            raise HTTPException(
                status_code=401,
                detail="Geçersiz kullanıcı verisi"
            )
            
        user, role = user_data
        
        # User nesnesinden uid kontrolü
        if not user or not isinstance(user, dict) or 'uid' not in user:
            print("❌ Kullanıcı uid'si bulunamadı")
            raise HTTPException(
                status_code=400,
                detail="Kullanıcı bilgileri eksik"
            )
            
        uid = user['uid']
        print(f"👤 İşlem yapılan kullanıcı uid: {uid}")
        
        # Stok verilerini getir
        stock_items = await get_stock_items(uid, by_uid=True)
        
        if not stock_items:
            print("❌ Kullanıcının stoğunda ürün bulunamadı")
            raise HTTPException(
                status_code=400,
                detail="Stokta ürün bulunamadı. Lütfen önce stok ekleyiniz."
            )
            
        print(f"📦 Stok verileri başarıyla getirildi: {stock_items}")
        
        # Stock items'ı işle
        stock_names = []
        if isinstance(stock_items, dict):
            for item in stock_items.values():
                if isinstance(item, dict) and 'name' in item:
                    stock_names.append(item['name'])
        
        if not stock_names:
            print("❌ Stok verilerinden ürün isimleri çıkarılamadı")
            raise HTTPException(
                status_code=400,
                detail="Stok verilerinde geçerli ürün bulunamadı"
            )
            
        print(f"📝 İşlenmiş ürün isimleri: {stock_names}")
        
        # Gemini API'ye gönder
        answer = answer_custom_question(stock_names, request.question)
        
        if not answer:
            raise HTTPException(
                status_code=500,
                detail="Yanıt oluşturulamadı"
            )
        
        print(f"✅ Özel soru yanıtı başarıyla oluşturuldu")
        return {"answer": answer}
        
    except HTTPException as he:
        print(f"⚠️ HTTP Hatası: {str(he)}")
        raise he
    except Exception as e:
        print(f"❌ Beklenmeyen hata: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Bir hata oluştu: {str(e)}"
        ) 