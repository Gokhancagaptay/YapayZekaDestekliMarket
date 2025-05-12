from pymongo import MongoClient
from core.settings import MONGO_URL

client = MongoClient(MONGO_URL)
db = client["online_market"]
collection = db["products"]
