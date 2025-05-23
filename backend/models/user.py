from pydantic import BaseModel
from typing import List, Optional

class Address(BaseModel):
    title: str
    mahalle: str
    sokak: str
    binaNo: str
    kat: str
    daireNo: str
    tarif: str
    isDefault: bool = False

class StockItem(BaseModel):
    product_id: str
    name: str
    image_url: str
    quantity: float
    unit: str
    category: str = "belirsiz"
    expiry_date: Optional[str] = None
    notes: Optional[str] = None

class User(BaseModel):
    email: str
    name: str
    surname: str
    phone: str
    role: str = "user"
    addresses: List[Address] = []
    stock_items: List[StockItem] = [] 