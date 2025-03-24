import requests

API_KEY = "AIzaSyA7Cenb2uv7CCQL0rPIHkLxmJQ3vvmUAGE"  # Firebase'deki Web API Key'ini buraya ekle!
email = "cagaptay09@gmail.com"  # Kullanıcı e-postanı buraya yaz
password = "123456"  # Kullanıcı şifreni buraya yaz

# Firebase REST API ile giriş yap ve ID Token al
url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
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
