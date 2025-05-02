import requests
from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth, credentials, firestore, initialize_app
from pydantic import BaseModel
from core.settings import FIREBASE_API_KEY
from firebase_admin import db




router = APIRouter(prefix="/auth", tags=["auth"])
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
    try:
        decoded_token = auth.verify_id_token(token)
        user_role = decoded_token.get('role', 'user')
        return decoded_token, user_role
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Yetkilendirme başarısız: {str(e)}")

# 🔹 Kullanıcı bilgilerini getirme
@router.get("/me", summary="Kullanıcı Bilgilerini Getir", description="Giriş yapmış kullanıcının bilgilerini getirir.")
def get_user_info(user_data=Depends(verify_token)):
    user, _ = user_data
    return {"email": user["email"], "uid": user["uid"]}

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

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        user_email = decoded_token.get("email")

        db = firestore.client()
        user_ref = db.collection("users").where("email", "==", user_email).limit(1).get()

        if user_ref:
            user_data = user_ref[0].to_dict()
            role = user_data.get("role", "user")
            return user_data, role
        else:
            raise HTTPException(status_code=401, detail="Kullanıcı bulunamadı.")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Yetkilendirme başarısız: {e}")