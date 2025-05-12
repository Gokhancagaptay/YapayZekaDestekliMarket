import requests
from fastapi import APIRouter, HTTPException, Depends, Body
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth, credentials, firestore, initialize_app
from pydantic import BaseModel
from core.settings import FIREBASE_API_KEY
from firebase_admin import db

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
def login(user: UserLogin):
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
    payload = {"email": user.email, "password": user.password, "returnSecureToken": True}
    response = requests.post(url, json=payload)
    data = response.json()

    if "idToken" in data:
        return {"message": "Giriş başarılı!", "idToken": data["idToken"]}
    else:
        raise HTTPException(status_code=400, detail=data.get("error", {}).get("message", "Bilinmeyen hata!"))

# 🔹 Token doğrulama
def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    print(f"Gelen token: {token[:20]}...")  # Token'ın ilk 20 karakterini göster
    
    try:
        # Token'ı doğrula
        decoded_token = auth.verify_id_token(token)
        print(f"Token doğrulandı. User ID: {decoded_token.get('uid')}")
        
        user_id = decoded_token["uid"]
        
        # Realtime Database'den kullanıcı bilgilerini al
        user_data = db.reference(f"users/{user_id}").get()
        print(f"Kullanıcı verileri: {user_data}")
        
        if user_data:
            role = user_data.get("role", "user")
            return user_data, role
        else:
            print(f"Kullanıcı bulunamadı: {user_id}")
            raise HTTPException(status_code=401, detail="Kullanıcı bulunamadı")
    except Exception as e:
        print(f"Token doğrulama hatası: {str(e)}")
        if "Token expired" in str(e):
            raise HTTPException(status_code=401, detail="Token süresi dolmuş")
        elif "Invalid token" in str(e):
            raise HTTPException(status_code=401, detail="Geçersiz token")
        else:
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