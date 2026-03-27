# app/detector.py
from ultralytics import YOLO
from app.config import Config

class Detector:
    def __init__(self, model_path: str = None, confidence: float = None):
        path = model_path or Config.MODEL_PATH_API
        self.model = YOLO(path)
        self.confidence = confidence or Config.CONFIDENCE

    def detect(self, frame) -> list[dict]:
        results = self.model(frame, conf=self.confidence, verbose=False)
        detections = []
        for r in results:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())
                detections.append({
                    "name": self.model.names[cls],
                    "confidence": round(conf, 3),
                    "bbox": {"x1": x1, "y1": y1, "x2": x2, "y2": y2}
                })
        return detections

    def get_classes(self) -> list[str]:
        """Retourne la liste des classes détectables."""
        return list(self.model.names.values())