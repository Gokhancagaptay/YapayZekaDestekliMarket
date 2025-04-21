# core/nutrition_analysis.py

besin_tablosu = {
    "yumurta": {"protein": 6, "karbonhidrat": 1, "yağ": 5},
    "domates": {"protein": 1, "karbonhidrat": 3, "yağ": 0},
    "tavuk": {"protein": 27, "karbonhidrat": 0, "yağ": 3},
    "pirinç": {"protein": 2, "karbonhidrat": 28, "yağ": 0},
    "makarna": {"protein": 5, "karbonhidrat": 30, "yağ": 1},
    "zeytinyağı": {"protein": 0, "karbonhidrat": 0, "yağ": 14},
    "peynir": {"protein": 7, "karbonhidrat": 1, "yağ": 6},
    "ekmek": {"protein": 3, "karbonhidrat": 15, "yağ": 1},
    "yoğurt": {"protein": 4, "karbonhidrat": 4, "yağ": 3},
    "patates": {"protein": 2, "karbonhidrat": 17, "yağ": 0},
}

def analiz_yap(ingredients: list[str]) -> dict:
    toplam = {"protein": 0, "karbonhidrat": 0, "yağ": 0}
    for urun in ingredients:
        urun = urun.lower().strip()
        if urun in besin_tablosu:
            for bilesen in toplam:
                toplam[bilesen] += besin_tablosu[urun][bilesen]
    return toplam

def yorumla(toplam: dict) -> str:
    yorum = []
    if toplam["protein"] < 15:
        yorum.append("Protein miktarı düşük, yumurta veya tavuk gibi ürünler ekleyebilirsiniz.")
    if toplam["karbonhidrat"] > 40:
        yorum.append("Karbonhidrat oranı yüksek, daha dengeli bir öğün için sebze önerilir.")
    if toplam["yağ"] > 15:
        yorum.append("Yağ oranı fazla, zeytinyağı gibi yağ eklerini azaltabilirsiniz.")
    if not yorum:
        yorum.append("Besin dengesi iyi görünüyor, afiyet olsun!")
    return " ".join(yorum)

def analyze_nutrition(ingredients: str) -> dict:
    urunler = [i.strip().lower() for i in ingredients.split(",")]
    sonuc = analiz_yap(urunler)
    yorum = yorumla(sonuc)
    return {
        "analiz": sonuc,
        "yorum": yorum
    }
