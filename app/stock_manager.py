# app/stock_manager.py
import json
from pathlib import Path
from datetime import datetime

class StockManager:
    def __init__(self, file_path: str):
        self.file_path = Path(file_path)
        self.file_path.parent.mkdir(parents=True, exist_ok=True)
        self.stock: dict = {}
        self.total_detected: int = 0
        self.session_start: str = datetime.now().isoformat()
        self.history: list = []
        self._load()

    def _load(self):
        """Charge les données depuis le fichier."""
        if self.file_path.exists():
            try:
                data = json.loads(self.file_path.read_text(encoding="utf-8"))
                self.stock = data.get("stock", {})
                self.total_detected = data.get("total", 0)
                self.history = data.get("history", [])
            except (json.JSONDecodeError, OSError):
                pass

    def _load_fresh(self) -> dict:
        """Relit le fichier depuis le disque — toujours à jour."""
        if self.file_path.exists():
            try:
                return json.loads(self.file_path.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                pass
        return {"stock": {}, "total": 0, "history": []}

    def _save(self):
        data = {
            "session": self.session_start,
            "saved_at": datetime.now().isoformat(),
            "stock": self.stock,
            "total": self.total_detected,
            "history": self.history[-100:],
        }
        self.file_path.write_text(json.dumps(data, ensure_ascii=False, indent=2))

    def add(self, name: str, quantity: int = 1) -> dict:
        """Relit le fichier avant d'ajouter pour ne pas écraser."""
        self._load()
        name = name.strip()
        if not name:
            raise ValueError("Le nom de l'article ne peut pas être vide.")
        self.stock[name] = self.stock.get(name, 0) + quantity
        self.total_detected += quantity
        self._log("add", name, quantity)
        self._save()
        return {"name": name, "quantity": self.stock[name]}

    def remove(self, name: str, quantity: int = 1) -> dict:
        """Relit le fichier avant de retirer."""
        self._load()
        name = name.strip()
        current = self.stock.get(name, 0)
        if current < quantity:
            raise ValueError(f"Stock insuffisant pour '{name}' : {current} disponible(s).")
        self.stock[name] -= quantity
        if self.stock[name] == 0:
            del self.stock[name]
        self._log("remove", name, quantity)
        self._save()
        return {"name": name, "quantity": self.stock.get(name, 0)}

    def reset(self, name: str = None):
        self._load()
        if name:
            removed = self.stock.pop(name.strip(), 0)
            self._log("reset_item", name, removed)
        else:
            self._log("reset_all", "*", self.total_detected)
            self.stock.clear()
            self.total_detected = 0
        self._save()

    def get_all(self) -> dict:
        """Relit toujours depuis le disque — retourne le stock le plus récent."""
        return self._load_fresh()

    def _log(self, action: str, name: str, qty: int):
        self.history.append({
            "action": action,
            "name": name,
            "quantity": qty,
            "at": datetime.now().isoformat(),
        })