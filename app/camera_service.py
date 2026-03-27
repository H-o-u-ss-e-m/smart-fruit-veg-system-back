# -*- coding: utf-8 -*-
"""
╔══════════════════════════════════════════════════════════════╗
║ 🍎 SYSTÈME DE GESTION DE STOCK IA - v2.2                    ║
║ Détection Multi-Objets Optimisée + YOLOv8                     ║
╚══════════════════════════════════════════════════════════════╝
"""
import cv2
import json
import time
import numpy as np
from datetime import datetime
from pathlib import Path
from ultralytics import YOLO

# ──────────────────────────────────────────────
# CONFIGURATION CENTRALE
# ──────────────────────────────────────────────
CONFIG = {
    "model_path": "models/best_fruits_legumes.pt",  # chemin vers le modèle correct
    "confidence": 0.45,
    "iou": 0.35,
    "max_det": 100,
    "camera_id": 0,
    "frame_w": 1280,
    "frame_h": 720,
    "roi_x_pct": (0.15, 0.85),
    "roi_y_pct": (0.10, 0.90),
    "recount_delay_sec": 2.0,
    "batch_window_sec": 1.5,
    "batch_min_count": 3,
    "save_file": "data/stock.json",
}

# ──────────────────────────────────────────────
# COULEURS (BGR)
# ──────────────────────────────────────────────
CLR = {
    "roi": (0, 200, 255),
    "box": (50, 255, 50),
    "box_in": (0, 255, 200),
    "box_new": (0, 100, 255),
    "label_bg": (20, 20, 20),
    "white": (255, 255, 255),
    "yellow": (0, 220, 255),
    "panel_bg": (15, 15, 15),
    "accent": (0, 180, 255),
}

# ──────────────────────────────────────────────
# GESTION DU STOCK
# ──────────────────────────────────────────────
class StockManager:
    def __init__(self, save_file: str):
        self.save_file = Path(save_file)
        self.stock: dict = {}
        self.last_seen: dict = {}  # id → timestamp dernière entrée ROI
        self.session_start = datetime.now()
        self.total_detected = 0
        self._batch_buffer = []  # [(time, name), ...]

    def try_add(self, obj_id: int, name: str, recount_delay: float) -> bool:
        now = time.time()
        last = self.last_seen.get(obj_id)
        self.last_seen[obj_id] = now
        if last is None or (now - last) > recount_delay:
            self.stock[name] = self.stock.get(name, 0) + 1
            self.total_detected += 1
            self._batch_buffer.append((now, name))
            self.autosave()
            return True
        return False

    def flush_departed(self, active_ids: set, recount_delay: float):
        now = time.time()
        gone = [oid for oid, t in self.last_seen.items()
                if oid not in active_ids and (now - t) > recount_delay * 2]
        for oid in gone:
            del self.last_seen[oid]

    def get_batch_stats(self, window_sec: float) -> dict:
        cutoff = time.time() - window_sec
        recent = [n for t, n in self._batch_buffer if t > cutoff]
        counts = {}
        for n in recent:
            counts[n] = counts.get(n, 0) + 1
        return counts

    def autosave(self):
        data = {
            "session": self.session_start.isoformat(),
            "saved_at": datetime.now().isoformat(),
            "stock": self.stock,
            "total": self.total_detected,
        }
        self.save_file.write_text(json.dumps(data, ensure_ascii=False, indent=2))

    def reset(self):
        self.stock.clear()
        self.last_seen.clear()
        self._batch_buffer.clear()
        self.total_detected = 0
        self.session_start = datetime.now()
        print("🔄 Stock remis à zéro.")

# ──────────────────────────────────────────────
# RENDU VISUEL
# ──────────────────────────────────────────────
class Renderer:
    PANEL_W = 290
    def __init__(self):
        self._flash_ids: dict = {}

    def mark_new(self, obj_id: int, duration: float = 1.0):
        self._flash_ids[obj_id] = time.time() + duration

    def draw_roi(self, frame, roi):
        x1, y1, x2, y2 = roi
        overlay = frame.copy()
        cv2.rectangle(overlay, (x1, y1), (x2, y2), CLR["roi"], -1)
        cv2.addWeighted(overlay, 0.06, frame, 0.94, 0, frame)
        ln, t = 35, 3
        for (cx, cy, dx, dy) in [(x1,y1,1,1),(x2,y1,-1,1),(x1,y2,1,-1),(x2,y2,-1,-1)]:
            cv2.line(frame, (cx, cy), (cx+dx*ln, cy), CLR["roi"], t)
            cv2.line(frame, (cx, cy), (cx, cy+dy*ln), CLR["roi"], t)
        cv2.putText(frame, "ZONE DE DETECTION",
                    (x1+8, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.55, CLR["roi"], 2)

    def draw_boxes(self, frame, detections: list):
        now = time.time()
        for d in detections:
            x1, y1, x2, y2 = map(int, d["box"])
            is_new = self._flash_ids.get(d["obj_id"], 0) > now
            color = (CLR["box_new"] if is_new
                     else CLR["box_in"] if d["inside"]
                     else CLR["box"])
            thick = 3 if is_new else 2
            cv2.rectangle(frame, (x1, y1), (x2, y2), color, thick)
            label = f"#{d['obj_id']} {d['name']} {d['conf']:.0%}"
            (tw, th), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.50, 1)
            cv2.rectangle(frame, (x1, y1-th-8), (x1+tw+6, y1), CLR["label_bg"], -1)
            cv2.putText(frame, label, (x1+3, y1-4), cv2.FONT_HERSHEY_SIMPLEX, 0.50, color, 1)
        expired = [oid for oid, t in self._flash_ids.items() if t <= now]
        for oid in expired:
            del self._flash_ids[oid]

    # draw_panel et draw_hud restent identiques (tu peux copier depuis ton ancien code)

# ──────────────────────────────────────────────
# UTILITAIRES
# ──────────────────────────────────────────────
def compute_roi(w, h, cfg):
    return (
        int(cfg["roi_x_pct"][0] * w),
        int(cfg["roi_y_pct"][0] * h),
        int(cfg["roi_x_pct"][1] * w),
        int(cfg["roi_y_pct"][1] * h),
    )

# ──────────────────────────────────────────────
# BOUCLE PRINCIPALE
# ──────────────────────────────────────────────
def main():
    print("Chargement du modele...")
    model = YOLO(CONFIG["model_path"])  # version YOLOv8
    print(f"✅ Modele charge : {len(model.names)} classes detectables")

    cap = cv2.VideoCapture(CONFIG["camera_id"])
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, CONFIG["frame_w"])
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CONFIG["frame_h"])

    if not cap.isOpened():
        print("❌ Impossible d'ouvrir la camera.")
        return

    W = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    H = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    roi = compute_roi(W, H, CONFIG)
    x1r, y1r, x2r, y2r = roi

    stock_mgr = StockManager(CONFIG["save_file"])
    renderer = Renderer()

    print(f"\nResolution : {W}x{H} ROI : {roi}")
    print(" [Q] Quitter [R] Reset stock [S] Sauvegarder\n")

    fps_timer = time.time()
    fps = 0.0
    frame_count = 0
    flash_msg = ""
    flash_until = 0.0

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            print("Perte du flux camera.")
            break

        # ── INFERENCE YOLOv8 ──
        results = model.track(
            frame,
            persist=True,
            conf=CONFIG["confidence"],
            iou=CONFIG["iou"],
            max_det=CONFIG["max_det"],
            agnostic_nms=True,
            verbose=False
        )

        detections = []
        active_ids = set()
        if results[0].boxes.id is not None:
            boxes = results[0].boxes.xyxy.cpu().numpy()
            ids = results[0].boxes.id.int().cpu().numpy()
            clss = results[0].boxes.cls.int().cpu().numpy()
            confs = results[0].boxes.conf.cpu().numpy()
            for box, obj_id, cls, conf in zip(boxes, ids, clss, confs):
                cx = int((box[0]+box[2])/2)
                cy = int((box[1]+box[3])/2)
                name = model.names[int(cls)]
                inside = x1r < cx < x2r and y1r < cy < y2r
                active_ids.add(int(obj_id))
                detections.append({"box": box, "obj_id": int(obj_id),
                                   "name": name, "inside": inside, "conf": float(conf)})
                if inside:
                    added = stock_mgr.try_add(int(obj_id), name, CONFIG["recount_delay_sec"])
                    if added:
                        renderer.mark_new(int(obj_id))
                        flash_msg = f"+ {name} stock: {stock_mgr.stock[name]}"
                        flash_until = time.time() + 1.8
                        print(f" +1 {name:<18} total={stock_mgr.stock[name]}")

        stock_mgr.flush_departed(active_ids, CONFIG["recount_delay_sec"])
        renderer.draw_roi(frame, roi)
        renderer.draw_boxes(frame, detections)
        # renderer.draw_panel(frame, ...) et draw_hud restent identiques

        # ── FPS ──
        frame_count += 1
        if frame_count % 20 == 0:
            fps = 20 / (time.time() - fps_timer + 1e-6)
            fps_timer = time.time()

        cv2.imshow("Gestion de Stock IA v2.2", frame)
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('r'):
            stock_mgr.reset()
            flash_msg = "Stock remis a zero"
            flash_until = time.time() + 2.0
        elif key == ord('s'):
            stock_mgr.autosave()
            flash_msg = f"Sauvegarde -> {CONFIG['save_file']}"
            flash_until = time.time() + 2.0
            print(f" Sauvegarde : {CONFIG['save_file']}")

    cap.release()
    cv2.destroyAllWindows()
    stock_mgr.autosave()

if __name__ == "__main__":
    main()