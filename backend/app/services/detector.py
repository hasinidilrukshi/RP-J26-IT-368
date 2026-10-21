"""YOLOv8 food detector wrapping the trained `best.pt` model."""
import io
import logging
import threading
from typing import Dict, List

from PIL import Image, ImageOps

from .. import config

log = logging.getLogger(__name__)


class FoodDetector:
    def __init__(self, model_path=config.MODEL_PATH):
        self.model_path = model_path
        self._model = None
        self._lock = threading.Lock()

    def load(self):
        if self._model is None:
            with self._lock:
                if self._model is None:
                    from ultralytics import YOLO  # heavy import, done lazily

                    log.info("Loading YOLO model from %s", self.model_path)
                    self._model = YOLO(str(self.model_path))
        return self._model

    @property
    def class_names(self) -> List[str]:
        names = self.load().names
        return [names[i] for i in sorted(names)]

    def predict(self, image_bytes: bytes) -> Dict:
        """Run detection and return the best food plus alternatives.

        Returns {detected, label, confidence, bbox, alternatives:[{label, confidence}]}.
        """
        model = self.load()
        image = Image.open(io.BytesIO(image_bytes))
        image = ImageOps.exif_transpose(image).convert("RGB")  # fix phone rotation

        results = model.predict(
            image, conf=config.DETECTION_CONFIDENCE, imgsz=config.IMAGE_SIZE, verbose=False
        )
        best_per_class: Dict[str, Dict] = {}
        for res in results:
            if res.boxes is None:
                continue
            for box in res.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                label = res.names[cls]
                if label not in best_per_class or conf > best_per_class[label]["confidence"]:
                    best_per_class[label] = {
                        "label": label,
                        "confidence": round(conf, 4),
                        "bbox": [round(float(v), 1) for v in box.xyxy[0].tolist()],
                    }

        ranked = sorted(best_per_class.values(), key=lambda d: d["confidence"], reverse=True)
        if not ranked:
            return {"detected": False, "label": None, "confidence": 0.0, "bbox": None,
                    "alternatives": [], "image_size": list(image.size)}
        top = ranked[0]
        return {
            "detected": True,
            "label": top["label"],
            "confidence": top["confidence"],
            "bbox": top["bbox"],
            "alternatives": [{"label": d["label"], "confidence": d["confidence"]} for d in ranked[1:5]],
            "image_size": list(image.size),
        }


detector = FoodDetector()
