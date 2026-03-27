# AI Stock App

## Prérequis
- [Anaconda](https://www.anaconda.com/download)
- [VSCode](https://code.visualstudio.com/) + extension Dev Containers
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

## Première installation
Double-clique sur `setup.bat`

## Lancement à chaque fois

### 1 — Backend (Docker)
1. Ouvre VSCode dans le dossier du projet
2. `Ctrl+Shift+P` → Dev Containers: Reopen in Container
3. Dans le terminal : `python run.py`

### 2 — Caméra (local)
Double-clique sur `start_camera.bat`

## Tester
GET http://localhost:5000/api/health
```

---

## Structure finale — vérifie que c'est bien placé
```
ai-stock-app/
├── environment.yml       ← nouveau ✅
├── setup.bat             ← nouveau ✅
├── start_camera.bat      ← nouveau ✅
├── README.md             ← nouveau ✅
├── .env
├── run.py
├── Dockerfile
├── requirements.txt
└── app/
```

---

## Ce que tes collègues font
```
1. git clone / copie du projet
2. Double-clic  setup.bat          (une seule fois ~5 min)
3. VSCode → Reopen in Container
4. python run.py                   (dans le container)
5. Double-clic  start_camera.bat   (local)