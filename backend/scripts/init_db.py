import requests
import json

# FastAPI endpoint URL'si
BASE_URL = "http://localhost:8000/products"

# Örnek ürünler
sample_products = [
    {
        "name": "Elma",
        "price": 15.99,
        "stock": 100,
        "image_url": "https://images.pexels.com/photos/102104/pexels-photo-102104.jpeg",
        "category": "meyve_sebze"
    },
    {
        "name": "Muz",
        "price": 12.99,
        "stock": 150,
        "image_url": "https://images.pexels.com/photos/1093038/pexels-photo-1093038.jpeg",
        "category": "meyve_sebze"
    },
    {
        "name": "Domates",
        "price": 8.99,
        "stock": 200,
        "image_url": "https://images.pexels.com/photos/1327838/pexels-photo-1327838.jpeg",
        "category": "meyve_sebze"
    },
    {
        "name": "Tavuk Göğsü",
        "price": 45.99,
        "stock": 50,
        "image_url": "https://images.pexels.com/photos/616354/pexels-photo-616354.jpeg",
        "category": "et_tavuk"
    }
]

def add_products():
    print("Ürünler ekleniyor...")
    for product in sample_products:
        try:
            response = requests.post(
                f"{BASE_URL}/add",
                json=product,
                headers={"Content-Type": "application/json"}
            )
            if response.status_code == 200:
                print(f"✓ {product['name']} başarıyla eklendi")
            else:
                print(f"✗ {product['name']} eklenirken hata oluştu: {response.text}")
        except Exception as e:
            print(f"✗ {product['name']} eklenirken hata oluştu: {str(e)}")

def check_products():
    print("\nEklenen ürünler kontrol ediliyor...")
    try:
        response = requests.get(f"{BASE_URL}/")
        if response.status_code == 200:
            products = response.json()["products"]
            print("\nMevcut ürünler:")
            for product in products:
                print(f"- {product['name']} ({product['category']})")
        else:
            print(f"Ürünler alınırken hata oluştu: {response.text}")
    except Exception as e:
        print(f"Ürünler alınırken hata oluştu: {str(e)}")

if __name__ == "__main__":
    add_products()
    check_products() 