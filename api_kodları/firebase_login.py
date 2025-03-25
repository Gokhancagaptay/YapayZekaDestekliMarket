import requests
from settings import MONGO_URL, FIREBASE_CREDENTIALS, FIREBASE_API_KEY,email,password

# Firebase REST API ile giriş yap ve ID Token al
url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
payload = {
    "email": email,
    "password": password,
    "returnSecureToken": True
}
response = requests.post(url, json=payload)
data = response.json()

if "idToken" in data:
    print("✅ ID Token Alındı:")
    print(data["idToken"])
else:
    print("❌ Hata:", data)
