"""
Voice -> text using Whisper (faster-whisper, runs on CPU).

task="translate" makes Whisper output ENGLISH text whatever language the
tourist speaks (German, French, Chinese, Sinhala, Tamil ...), so the same
English NLP model in severity_model.py can assess it.

The Whisper model is downloaded automatically the first time (internet needed
once). Size is set with WHISPER_MODEL in .env:
    tiny (~75 MB, fastest) | base (~145 MB, default) | small (~480 MB, better)
"""
import logging
import os
import threading

log = logging.getLogger("speech")

WHISPER_MODEL = os.getenv("WHISPER_MODEL", "base")
_model = None
_lock = threading.Lock()

LANGUAGE_NAMES = {
    "en": "English", "si": "Sinhala", "ta": "Tamil", "de": "German",
    "fr": "French", "es": "Spanish", "it": "Italian", "nl": "Dutch",
    "ru": "Russian", "zh": "Chinese", "ja": "Japanese", "ko": "Korean",
    "hi": "Hindi", "ar": "Arabic", "pt": "Portuguese", "pl": "Polish",
    "sv": "Swedish", "uk": "Ukrainian", "he": "Hebrew", "tr": "Turkish",
}


class SpeechUnavailable(RuntimeError):
    pass


def _get_model():
    global _model
    if _model is None:
        with _lock:
            if _model is None:
                try:
                    from faster_whisper import WhisperModel
                except ImportError as e:
                    raise SpeechUnavailable(
                        "faster-whisper is not installed: pip install faster-whisper") from e
                log.warning("Loading Whisper '%s' (first time downloads it)...", WHISPER_MODEL)
                _model = WhisperModel(WHISPER_MODEL, device="cpu", compute_type="int8")
    return _model


def transcribe(audio_path: str) -> dict:
    """Returns {text, original_text, language, language_name,
                language_probability, duration}"""
    model = _get_model()

    # 1) English translation (fed to the NLP model)
    segments, info = model.transcribe(
        audio_path, task="translate", beam_size=5, vad_filter=True)
    english = " ".join(s.text.strip() for s in segments).strip()

    # 2) original-language transcript (shown to admins), only if not English
    original = english
    if info.language != "en":
        segs, _ = model.transcribe(
            audio_path, task="transcribe", language=info.language,
            beam_size=5, vad_filter=True)
        original = " ".join(s.text.strip() for s in segs).strip()

    return {
        "text": english,
        "original_text": original,
        "language": info.language,
        "language_name": LANGUAGE_NAMES.get(info.language, info.language),
        "language_probability": round(float(info.language_probability), 2),
        "duration": round(float(info.duration), 1),
    }


def warm_up():
    """Load the model in the background when the server starts."""
    def _run():
        try:
            _get_model()
            log.warning("Whisper ready")
        except Exception as e:  # noqa: BLE001
            log.error("Whisper not available: %s", e)
    threading.Thread(target=_run, daemon=True).start()
