# app/config.py
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

class Config:
    # Modèles
    MODEL_PATH = os.getenv("MODEL_PATH", str(BASE_DIR / "models" / "best_fruits_legumes.pt"))
    MODEL_PATH_API = os.getenv("MODEL_PATH_API", str(BASE_DIR / "models" / "best.pt"))

    # Détection
    CONFIDENCE = float(os.getenv("CONFIDENCE", "0.45"))
    IOU = float(os.getenv("IOU", "0.35"))
    MAX_DET = int(os.getenv("MAX_DET", "100"))

    # Caméra
    CAMERA_ID = int(os.getenv("CAMERA_ID", "0"))
    FRAME_W = int(os.getenv("FRAME_W", "1280"))
    FRAME_H = int(os.getenv("FRAME_H", "720"))

    # Stock
    SAVE_FILE = os.getenv("SAVE_FILE", str(BASE_DIR / "data" / "stock.json"))
    RECOUNT_DELAY = float(os.getenv("RECOUNT_DELAY", "2.0"))

    # Flask
    DEBUG = os.getenv("FLASK_DEBUG", "true").lower() == "true"
    HOST = os.getenv("FLASK_HOST", "0.0.0.0")
    PORT = int(os.getenv("FLASK_PORT", "5000"))