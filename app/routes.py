# app/routes.py
from flask import Blueprint, jsonify, request
import cv2
import numpy as np

from app.detector import Detector
from app.stock_manager import StockManager
from app.config import Config

api = Blueprint("api", __name__)

detector = Detector()
stock = StockManager(Config.SAVE_FILE)

# ── Helpers ──────────────────────────────────────
def _bad(msg: str, code: int = 400):
    return jsonify({"error": msg}), code

# ── Stock ─────────────────────────────────────────
@api.route("/stock", methods=["GET"])
def get_stock():
    return jsonify(stock.get_all())

@api.route("/stock/<name>", methods=["GET"])
def get_item(name: str):
    qty = stock.stock.get(name, 0)
    return jsonify({"name": name, "quantity": qty})

@api.route("/stock/add", methods=["POST"])
def add_item():
    data = request.get_json(silent=True) or {}
    name = data.get("name", "").strip()
    qty = int(data.get("quantity", 1))
    if not name:
        return _bad("Champ 'name' requis.")
    if qty < 1:
        return _bad("La quantité doit être ≥ 1.")
    try:
        result = stock.add(name, qty)
        return jsonify(result), 201
    except ValueError as e:
        return _bad(str(e))

@api.route("/stock/remove", methods=["POST"])
def remove_item():
    data = request.get_json(silent=True) or {}
    name = data.get("name", "").strip()
    qty = int(data.get("quantity", 1))
    if not name:
        return _bad("Champ 'name' requis.")
    try:
        result = stock.remove(name, qty)
        return jsonify(result)
    except ValueError as e:
        return _bad(str(e))

@api.route("/stock/reset", methods=["POST"])
def reset_stock():
    data = request.get_json(silent=True) or {}
    name = data.get("name")  # optionnel : reset d'un seul article
    stock.reset(name)
    return jsonify({"message": f"Stock {'de ' + name if name else 'complet'} remis à zéro."})

# ── Détection ─────────────────────────────────────
@api.route("/detect", methods=["POST"])
def detect_image():
    if "image" not in request.files:
        return _bad("Champ 'image' manquant.")

    file = request.files["image"]
    if file.filename == "":
        return _bad("Aucun fichier sélectionné.")

    allowed = {"image/jpeg", "image/png", "image/jpg"}
    if file.content_type not in allowed:
        return _bad(f"Type de fichier non supporté : {file.content_type}. Utilise JPEG ou PNG.")

    file_bytes = np.frombuffer(file.read(), np.uint8)
    frame = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)
    if frame is None:
        return _bad("Impossible de décoder l'image.")

    detections = detector.detect(frame)
    for d in detections:
        stock.add(d["name"])

    return jsonify({
        "detections": detections,
        "count": len(detections),
        "stock": stock.get_all(),
    })

@api.route("/classes", methods=["GET"])
def get_classes():
    """Retourne la liste des classes que le modèle peut détecter."""
    return jsonify({"classes": detector.get_classes()})

# ── Santé ─────────────────────────────────────────
@api.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "model": Config.MODEL_PATH_API})