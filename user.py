import requests
from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth
from pydantic import BaseModel
from settings import MONGO_URL, FIREBASE_CREDENTIALS, FIREBASE_API_KEY


router = APIRouter()
security = HTTPBearer()

# 📌 Firebase Web API Key (Gerçek API anahtarını buraya ekle!)

# 📌 Kullanıcı Modeli
class UserRegister(BaseModel):
    email: str
    password: str
    role: str = "user"

class UserLogin(BaseModel):
    email: str
    password: str

class UserUpdate(BaseModel):
    display_name: str = None
    phone_number: str = None
    role: str = None

# 🔹 Kullanıcı kayıt işlemi
@router.post("/register")
def register(user: UserRegister):
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={FIREBASE_API_KEY}"
    payload = {"email": user.email, "password": user.password, "returnSecureToken": True,"role": user.role}
    response = requests.post(url, json=payload)
    data = response.json()

    if "idToken" in data:
        user_id = data["localId"]
        auth.set_custom_user_claims(user_id, {"role": user.role})  # Kullanıcıya rol ekliyoruz
        return {"message": "Kullanıcı başarıyla kaydedildi!", "idToken": data["idToken"]}
    else:
        raise HTTPException(status_code=400, detail=data.get("error", {}).get("message", "Bilinmeyen hata!"))


# 🔹 Kullanıcı giriş işlemi
@router.post("/login")
def login(user: UserLogin):
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
    payload = {"email": user.email, "password": user.password, "returnSecureToken": True}
    response = requests.post(url, json=payload)
    data = response.json()

    if "idToken" in data:
        return {"message": "Giriş başarılı!", "idToken": data["idToken"]}
    else:
        raise HTTPException(status_code=400, detail=data.get("error", {}).get("message", "Bilinmeyen hata!"))

# 🔹 Token doğrulama (export edilecek)
def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        user_role = decoded_token.get('role', 'user')  # Rolü al
        return decoded_token, user_role
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Yetkilendirme başarısız: {str(e)}")

# 🔹 Kullanıcı bilgilerini getirme
@router.get("/me")
def get_user_info(user: dict = Depends(verify_token)):
    return {"email": user["email"], "uid": user["uid"]}


# 🔹 Şifre sıfırlama işlemi
@router.post("/forgot-password")
def forgot_password(email: str):
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key={FIREBASE_API_KEY}"
    payload = {"requestType": "PASSWORD_RESET", "email": email}
    response = requests.post(url, json=payload)
    data = response.json()

    if "email" in data:
        return {"message": "Şifre sıfırlama bağlantısı başarıyla gönderildi!"}
    else:
        raise HTTPException(status_code=400, detail=data.get("error", {}).get("message", "Bilinmeyen hata!"))
    

# 🔹 Kullanıcı bilgilerini güncelleme
@router.put("/update")
def update_user_info(user_update: UserUpdate, user: dict = Depends(verify_token)):
    # Güncelleme için Firebase Admin SDK'yı kullanma
    try:
        if user_update.email:
            auth.update_user(user["uid"], email=user_update.email)
        if user_update.password:
            auth.update_user(user["uid"], password=user_update.password)

        return {"message": "Kullanıcı bilgileri başarıyla güncellendi."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Güncelleme hatası: {str(e)}")
    

@router.post("/refresh-token")
def refresh_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        # Yeni token almak için Firebase Auth kullanmak
        decoded_token = auth.verify_id_token(token, check_revoked=True)
        new_token = auth.create_custom_token(decoded_token['uid'])
        return {"new_idToken": new_token.decode('utf-8')}
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token yenileme hatası: {str(e)}")
    
def verify_admin(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        if decoded_token.get("role") != "admin":
            raise HTTPException(status_code=403, detail="Bu işlem için yetkiniz yok!")
        return decoded_token
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Yetkilendirme başarısız: {str(e)}")


