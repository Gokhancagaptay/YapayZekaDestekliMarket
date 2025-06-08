import requests
from fastapi import APIRouter, HTTPException, Depends, Body
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth, credentials, firestore, initialize_app
from pydantic import BaseModel
from core.settings import FIREBASE_API_KEY
from firebase_admin import db
from models.user import Address, StockItem, User
from database import (
    get_user_by_email, add_address, get_addresses,
    add_stock_item, get_stock_items, update_stock_item,
    delete_stock_item, create_user,
    get_user_by_uid, create_user_from_firebase
)

router = APIRouter(tags=["auth"])
security = HTTPBearer()

class UserRegister(BaseModel):
    email: str
    password: str
    name: str
    surname: str
    phone: str
    role: str = "user"

class UserLogin(BaseModel):
    email: str
    password: str

class AddressModel(BaseModel):
    title: str
    mahalle: str
    sokak: str
    binaNo: str
    kat: str
    daireNo: str
    tarif: str
    isDefault: bool = False

class UserUpdate(BaseModel):
    name: str
    surname: str
    phone: str
    email: str
    new_password: str = None
    current_password: str = None

# 🔹 Kullanıcı kayıt işlemi
@router.post("/register", summary="Kullanıcı Kaydı", description="Yeni bir kullanıcı kaydı oluşturur.")
def register(user: UserRegister):
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={FIREBASE_API_KEY}"
    payload = {
        "email": user.email,
        "password": user.password,
        "returnSecureToken": True
    }
    response = requests.post(url, json=payload)
    data = response.json()

    if "idToken" in data:
        user_id = data["localId"]

        # Firebase yetki rolü atama
        try:
            auth.set_custom_user_claims(user_id, {"role": user.role})
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Rol ataması hatası: {str(e)}")

        # Ek kullanıcı bilgilerini realtime database'e yazma
        try:
            db.reference(f"users/{user_id}").set({
                "name": user.name,
                "surname": user.surname,
                "phone": user.phone,
                "email": user.email,
                "role": user.role
            })
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Veritabanı yazım hatası: {str(e)}")

        return {"message": "Kullanıcı başarıyla kaydedildi!", "idToken": data["idToken"]}
    else:
        raise HTTPException(
            status_code=400,
            detail=data.get("error", {}).get("message", "Bilinmeyen hata!")
        )

# 🔹 Kullanıcı giriş işlemi
@router.post("/login", summary="Kullanıcı Girişi", description="Mevcut bir kullanıcı için giriş yapar.")
async def login(user: UserLogin):
    try:
        url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
        payload = {"email": user.email, "password": user.password, "returnSecureToken": True}
        
        print(f"🔑 Giriş denemesi - Email: {user.email}")
        response = requests.post(url, json=payload)
        data = response.json()
        
        if "idToken" in data:
            print(f"✅ Giriş başarılı - Email: {user.email}")
            user_id = data["localId"]
            
            # Firebase Realtime Database'den kullanıcı rolünü oku
            user_role = "user" # Varsayılan rol
            try:
                role_snapshot = db.reference(f"users/{user_id}/role").get()
                if role_snapshot:
                    user_role = role_snapshot
                print(f"👤 Kullanıcı rolü Firebase'den okundu: {user_role} (UID: {user_id})")
            except Exception as e:
                print(f"⚠️ Firebase'den rol okuma hatası: {str(e)} - Varsayılan rol \'user\' kullanılacak.")
                # Hata durumunda logla ama devam et, varsayılan rol kullanılsın.

            return {
                "message": "Giriş başarılı!",
                "idToken": data["idToken"],
                "uid": user_id,
                "role": user_role # Okunan rolü yanıta ekle
            }
        else:
            error_message = data.get("error", {}).get("message", "Bilinmeyen giriş hatası!")
            print(f"❌ Giriş başarısız - Email: {user.email}, Hata: {error_message}")
            raise HTTPException(
                status_code=400,
                detail=error_message
            )
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Ağ hatası (Firebase Authentication): {str(e)}")
        raise HTTPException(status_code=503, detail=f"Kimlik doğrulama servisine ulaşılamıyor: {str(e)}")
    except Exception as e:
        print(f"❌ Beklenmeyen giriş hatası: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Giriş sırasında beklenmeyen bir hata oluştu: {str(e)}")

# 🔹 Token doğrulama
def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    print(f"🔑 Token doğrulama başladı - Token: {token[:20]}...")  # Token'ın ilk 20 karakterini göster
    
    try:
        # Token'ı doğrula
        decoded_token = auth.verify_id_token(token)
        user_id = decoded_token.get("uid")
        
        if not user_id:
            print("❌ Token'dan uid alınamadı")
            raise HTTPException(status_code=401, detail="Geçersiz token: uid bulunamadı")
            
        print(f"✅ Token doğrulandı - User ID: {user_id}")
        
        # Realtime Database'den kullanıcı bilgilerini al
        user_data = db.reference(f"users/{user_id}").get()
        print(f"📦 Firebase'den gelen kullanıcı verileri: {user_data}")
        
        if not user_data:
            print(f"❌ Kullanıcı bulunamadı: {user_id}")
            raise HTTPException(status_code=401, detail="Kullanıcı bulunamadı")
            
        # uid'yi user_data içine ekle
        user_data["uid"] = user_id
        role = user_data.get("role", "user")
        
        print(f"✅ Kullanıcı bilgileri hazırlandı - Role: {role}")
        return user_data, role
        
    except auth.InvalidIdTokenError:
        print("❌ Geçersiz token hatası")
        raise HTTPException(status_code=401, detail="Geçersiz token")
    except auth.ExpiredIdTokenError:
        print("❌ Token süresi dolmuş")
        raise HTTPException(status_code=401, detail="Token süresi dolmuş")
    except auth.RevokedIdTokenError:
        print("❌ Token iptal edilmiş")
        raise HTTPException(status_code=401, detail="Token iptal edilmiş")
    except Exception as e:
        print(f"❌ Beklenmeyen hata: {str(e)}")
        raise HTTPException(status_code=401, detail=f"Yetkilendirme başarısız: {str(e)}")

# 🔹 Kullanıcı bilgilerini getirme
@router.get("/me", summary="Kullanıcı Bilgilerini Getir")
def get_user_info(user_data=Depends(verify_token)):
    try:
        user, role = user_data
        return {
            "email": user.get("email"),
            "name": user.get("name"),
            "surname": user.get("surname"),
            "phone": user.get("phone"),
            "role": role
        }
    except Exception as e:
        print(f"Kullanıcı bilgileri alma hatası: {str(e)}")  # Debug için
        raise HTTPException(status_code=500, detail=f"Kullanıcı bilgileri alınamadı: {str(e)}")

# 🔹 Kullanıcı profil güncelleme
@router.put("/update", summary="Kullanıcı Profilini Güncelle")
async def update_profile(user_data: UserUpdate, credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        token = credentials.credentials
        decoded_token = auth.verify_id_token(token)
        user_id = decoded_token.get("uid")
        
        if not user_id:
            raise HTTPException(status_code=401, detail="Kullanıcı kimliği bulunamadı")
            
        print(f"👤 Profil güncelleme - User ID: {user_id}")
        
        # Firebase'de kullanıcı verileri güncelleme
        user_ref = db.reference(f"users/{user_id}")
        
        # Güncelleme verilerini hazırla
        update_data = {
            "name": user_data.name,
            "surname": user_data.surname,
            "phone": user_data.phone,
            "email": user_data.email
        }
        
        # Firebase Authentication'da e-posta güncelleme (eğer değiştiyse)
        current_user_data = db.reference(f"users/{user_id}").get() or {}
        if user_data.email != current_user_data.get("email"):
            try:
                auth.update_user(user_id, email=user_data.email)
                print(f"✅ Firebase Auth email güncellendi: {user_data.email}")
            except Exception as e:
                print(f"❌ Firebase Auth email güncelleme hatası: {str(e)}")
                raise HTTPException(status_code=400, detail=f"E-posta güncellenemedi: {str(e)}")
        
        # Şifre güncellemesi istendiyse
        if user_data.current_password and user_data.new_password:
            try:
                # Email/password ile yeniden kimlik doğrulama yapmak gerekir
                # Bu örnek basitleştirilmiş, gerçek uygulamada daha güvenli yöntem kullanılmalı
                url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
                payload = {
                    "email": user_data.email, 
                    "password": user_data.current_password, 
                    "returnSecureToken": True
                }
                response = requests.post(url, json=payload)
                
                if response.status_code != 200:
                    raise HTTPException(status_code=400, detail="Mevcut şifre yanlış")
                
                # Şifre güncelleme
                auth.update_user(user_id, password=user_data.new_password)
                print("✅ Şifre başarıyla güncellendi")
            except Exception as e:
                print(f"❌ Şifre güncelleme hatası: {str(e)}")
                raise HTTPException(status_code=400, detail=f"Şifre güncellenemedi: {str(e)}")
        
        # Realtime Database'de kullanıcı bilgilerini güncelleme
        user_ref.update(update_data)
        print(f"✅ Firebase kullanıcı bilgileri güncellendi: {update_data}")
        
        return {"message": "Profil başarıyla güncellendi", "user": update_data}
    except Exception as e:
        print(f"❌ Profil güncelleme hatası: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Profil güncellenemedi: {str(e)}")

# 🔹 Şifre sıfırlama işlemi
@router.post("/forgot-password", summary="Şifre Sıfırlama", description="Kullanıcının şifresini sıfırlamak için e-posta gönderir.")
def forgot_password(email: str):
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key={FIREBASE_API_KEY}"
    payload = {"requestType": "PASSWORD_RESET", "email": email}
    response = requests.post(url, json=payload)
    data = response.json()

    if "email" in data:
        return {"message": "Şifre sıfırlama bağlantısı başarıyla gönderildi!"}
    else:
        raise HTTPException(status_code=400, detail=data.get("error", {}).get("message", "Bilinmeyen hata!"))

# 🔹 Admin yetkisini kontrol etme
def verify_admin(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        claims = auth.get_user(decoded_token["uid"]).custom_claims
        if not claims or claims.get("role") != "admin":
            raise HTTPException(status_code=403, detail="Bu işlem için yetkiniz yok!")
        return decoded_token
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Yetkilendirme başarısız: {str(e)}")

@router.post("/users/{user_id}/addresses", summary="Adres Ekle")
def add_address(user_id: str, address: AddressModel):
    try:
        ref = db.reference(f"users/{user_id}/addresses").push()
        ref.set(address.dict())
        return {"success": True, "id": ref.key}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Adres eklenemedi: {str(e)}")

@router.get("/users/{user_id}/addresses", summary="Adresleri Listele")
def list_addresses(user_id: str):
    try:
        ref = db.reference(f"users/{user_id}/addresses")
        data = ref.get()
        if not data:
            return []
        return [{"id": k, **v} for k, v in data.items()]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Adresler alınamadı: {str(e)}")

@router.delete("/users/{user_id}/addresses/{address_id}", summary="Adresi Sil")
def delete_address(user_id: str, address_id: str):
    try:
        ref = db.reference(f"users/{user_id}/addresses/{address_id}")
        ref.delete()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Adres silinemedi: {str(e)}")

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        token = credentials.credentials
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(status_code=401, detail="Geçersiz token")

@router.post("/users/register")
async def register_user(user: User):
    try:
        # Önce kullanıcının var olup olmadığını kontrol et
        existing_user = await get_user_by_email(user.email)
        if existing_user:
            raise HTTPException(status_code=400, detail="Bu email zaten kayıtlı")
        
        # Kullanıcıyı MongoDB'ye kaydet
        user_id = await create_user(user.dict())
        return {"message": "Kullanıcı başarıyla oluşturuldu", "user_id": str(user_id)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Kullanıcı kaydı başarısız: {str(e)}")

@router.post("/users/{email}/addresses")
async def create_address(email: str, address: Address, current_user: dict = Depends(get_current_user)):
    try:
        # Kullanıcı kontrolü
        if current_user["email"] != email:
            raise HTTPException(status_code=403, detail="Bu işlem için yetkiniz yok")
        
        # Kullanıcının MongoDB'de var olup olmadığını kontrol et
        user = await get_user_by_email(email)
        if not user:
            # Kullanıcı yoksa otomatik oluştur
            new_user = User(
                email=email,
                name=current_user.get("name", ""),
                surname=current_user.get("surname", ""),
                phone=current_user.get("phone", ""),
                role="user"
            )
            await create_user(new_user.dict())
        
        # Adresi ekle
        success = await add_address(email, address)
        if not success:
            raise HTTPException(status_code=500, detail="Adres eklenemedi")
        return {"message": "Adres başarıyla eklendi"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"İşlem başarısız: {str(e)}")

@router.get("/users/{email}/addresses")
async def list_addresses(email: str, current_user: dict = Depends(get_current_user)):
    try:
        # Kullanıcı kontrolü
        if current_user["email"] != email:
            raise HTTPException(status_code=403, detail="Bu işlem için yetkiniz yok")
        
        # Kullanıcının MongoDB'de var olup olmadığını kontrol et
        user = await get_user_by_email(email)
        if not user:
            return []  # Kullanıcı yoksa boş liste dön
        
        addresses = await get_addresses(email)
        return addresses
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"İşlem başarısız: {str(e)}")

@router.post("/users/{user_id}/stock")
def add_stock(user_id: str, stock_item: StockItem, current_user: dict = Depends(get_current_user)):
    if current_user["uid"] != user_id:
        raise HTTPException(status_code=403, detail="Bu işlem için yetkiniz yok")
    try:
        # Firebase Realtime Database'e ekle
        ref = db.reference(f"users/{user_id}/stock_items")
        # Ürün ID'si ile kaydet (aynı ürün tekrar eklenirse üzerine yazar)
        ref.child(stock_item.product_id).set(stock_item.dict())
        return {"message": "Stok başarıyla eklendi (Firebase)"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stok eklenemedi: {str(e)}")

@router.get("/users/{user_id}/stock")
def list_stock(user_id: str, current_user: dict = Depends(get_current_user)):
    print(f"Stok isteği - User ID: {user_id}") # Debug için
    print(f"Current User: {current_user}") # Debug için
    
    if current_user["uid"] != user_id:
        print("Yetki hatası - Kullanıcı ID'leri eşleşmiyor") # Debug için
        raise HTTPException(status_code=403, detail="Bu işlem için yetkiniz yok")
    try:
        ref = db.reference(f"users/{user_id}/stock_items")
        data = ref.get()
        print(f"Firebase'den gelen veri: {data}") # Debug için
        
        if not data:
            print("Firebase'den veri gelmedi") # Debug için
            return []
        return [{"product_id": k, **v} for k, v in data.items()]
    except Exception as e:
        print(f"Stok getirme hatası: {str(e)}") # Debug için
        raise HTTPException(status_code=500, detail=f"Stoklar alınamadı: {str(e)}")

@router.put("/users/{user_id}/stock/{product_id}")
def update_stock(user_id: str, product_id: str, quantity: int, current_user: dict = Depends(get_current_user)):
    if current_user["uid"] != user_id:
        raise HTTPException(status_code=403, detail="Bu işlem için yetkiniz yok")
    try:
        ref = db.reference(f"users/{user_id}/stock_items/{product_id}")
        ref.update({"quantity": quantity})
        return {"message": "Stok başarıyla güncellendi (Firebase)"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stok güncellenemedi: {str(e)}")

@router.delete("/users/{user_id}/stock/{product_id}")
def delete_stock(user_id: str, product_id: str, current_user: dict = Depends(get_current_user)):
    if current_user["uid"] != user_id:
        raise HTTPException(status_code=403, detail="Bu işlem için yetkiniz yok")
    try:
        # Firebase Realtime Database'den sil
        ref = db.reference(f"users/{user_id}/stock_items/{product_id}")
        ref.delete()
        return {"message": "Stok başarıyla silindi (Firebase)"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stok silinemedi: {str(e)}")

# Duplicate the endpoint to handle both old and new paths
@router.put("/auth/update", summary="Kullanıcı Profilini Güncelle (Eski Yol)")
async def update_profile_old_path(user_data: UserUpdate, credentials: HTTPAuthorizationCredentials = Depends(security)):
    return await update_profile(user_data, credentials)