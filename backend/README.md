# Pronunciation Backend

This folder contains the local FastAPI pronunciation-analysis backend copied
from the verified `speech-mvp` prototype.

## Layout

- `app/main.py`: FastAPI entrypoint.
- `app/routers/attempts.py`: attempt lifecycle API.
- `app/routers/catalog.py`: lesson and utterance catalog API.
- `app/services/analysis_service.py`: `run_full_analysis_from_metadata`.
- `app/services/metadata_loader.py`: metadata CSV loader.
- `data/metadata/utterance_metadata_v1.csv`: canonical utterance metadata.
- `data/tts.py`: local utility for generating temporary reference audio.
- `data/clips/`: local source clip workspace.
- `data/audio/reference/`: canonical reference audio directory.
- `data/audio/test/`: local test audio workspace.
- `data/audio/attempts/`: local uploaded attempt audio and generated results.
- `data/legacy/data1/`: isolated prototype-only data copied from `speech-mvp`.

## Run Locally

Use Python 3.9.

```sh
cd backend
python3.9 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

The Flutter app defaults to `http://localhost:8000`.

For local TTS reference generation, install the optional dev dependencies:

```sh
python -m pip install -r requirements-dev.txt
python data/tts.py
```
