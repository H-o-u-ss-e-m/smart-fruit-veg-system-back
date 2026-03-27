# 🍎 AI Stock App

Système de gestion de stock intelligent basé sur la détection d'objets en temps réel avec **YOLOv8**. La caméra tourne localement et envoie les détections à une API Flask conteneurisée dans Docker.

---

## Architecture

```
[PC local]                          [Docker Container]
camera_service.py                   Flask API (port 5000)
  │                                       │
  ├─ Capture webcam (OpenCV)              │
  ├─ Détection YOLO locale          ──►  ├─ GET  /api/stock
  └─ Mise à jour stock.json         ──►  ├─ POST /api/detect
                                         ├─ POST /api/stock/add
                                         ├─ POST /api/stock/remove
                                         └─ GET  /api/health
```

---

## Prérequis

| Outil | Utilité | Lien |
|-------|---------|------|
| [Anaconda](https://www.anaconda.com/download) | Environnement Python local (caméra) | Obligatoire |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Lancer le backend Flask | Obligatoire |
| [VSCode](https://code.visualstudio.com/) + extension **Dev Containers** | Ouvrir le container | Obligatoire |
| [Postman](https://www.postman.com/downloads/) | Tester l'API | Optionnel |

---

## Installation — Première fois

### 1. Clone le projet

```bash
git clone <url-du-repo>
cd ai-stock-app
```

### 2. Installe l'environnement Python local

Double-clique sur **`setup.bat`**

> Ce script détecte automatiquement Anaconda et installe toutes les dépendances nécessaires (`opencv`, `ultralytics`, `numpy`, `requests`).

Si Anaconda est dans un chemin non standard, ouvre `setup.bat` avec Notepad et ajoute ta ligne :
```bat
if exist "X:\ton\chemin\anaconda3\Scripts\activate.bat" set CONDA_PATH=X:\ton\chemin\anaconda3
```

### 3. Ajoute les modèles YOLO

Place les fichiers `.pt` dans le dossier `models/` :
```
models/
├── best_fruits_legumes.pt   ← modèle principal

```

> Ces fichiers ne sont pas inclus dans le repo (trop lourds). Demande-les à l'équipe.

---

## Lancement — À chaque fois

### Étape 1 — Démarrer le backend (Docker)

1. Ouvre le projet dans **VSCode**
2. `Ctrl+Shift+P` → **Dev Containers: Reopen in Container**
3. Attends que le container soit prêt
4. Dans le terminal VSCode :

```bash
python run.py
```

Tu dois voir :
```
* Running on http://0.0.0.0:5000
* Debugger is active!
```

### Étape 2 — Démarrer la caméra (local)

Double-clique sur **`start_camera.bat`**

Tu dois voir :
```
✅ Modele charge : 35 classes detectables
Resolution : 1280x720
```

---

## API — Endpoints disponibles

Base URL : `http://localhost:5000`

### Santé

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/api/health` | Vérifie que l'API tourne |
| GET | `/api/classes` | Liste les classes détectables |

### Stock

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/api/stock` | Retourne le stock complet |
| GET | `/api/stock/<name>` | Quantité d'un article |
| POST | `/api/stock/add` | Ajoute manuellement |
| POST | `/api/stock/remove` | Retire du stock |
| POST | `/api/stock/reset` | Remet à zéro |

### Détection

| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/api/detect` | Envoie une image, retourne les détections |

#### Exemples

**Ajouter un article**
```bash
POST /api/stock/add
Content-Type: application/json

{ "name": "Apple", "quantity": 2 }
```

**Retirer un article**
```bash
POST /api/stock/remove
Content-Type: application/json

{ "name": "Apple", "quantity": 1 }
```

**Reset complet**
```bash
POST /api/stock/reset
Content-Type: application/json

{}
```

**Reset un seul article**
```bash
POST /api/stock/reset
Content-Type: application/json

{ "name": "Apple" }
```

**Détecter via image**
```
POST /api/detect
Body: form-data
  key: image (type: File)
  value: photo.jpg
```

---

## Structure du projet

```
ai-stock-app/
├── app/
│   ├── __init__.py          # Flask app + CORS + error handlers
│   ├── camera_service.py    # Boucle caméra + détection YOLO locale
│   ├── config.py            # Configuration centralisée (.env)
│   ├── detector.py          # Wrapper YOLO
│   ├── routes.py            # Endpoints Flask
│   └── stock_manager.py     # Gestion du stock (lecture/écriture JSON)
├── data/
│   └── stock.json           # Données du stock (auto-généré)
├── models/
│   └── best_fruits_legumes.pt  # Modèle YOLO (non inclus dans le repo)
├── .devcontainer/
│   └── devcontainer.json
├── .env                     # Variables d'environnement
├── Dockerfile
├── environment.yml          # Environnement conda local
├── requirements.txt         # Dépendances Docker
├── run.py                   # Point d'entrée Flask
├── setup.bat                # Installation automatique (Windows)
└── start_camera.bat         # Lancement caméra (Windows)
```

---

## Variables d'environnement

Crée un fichier `.env` à la racine (copie depuis `.env.example` si disponible) :

```env
MODEL_PATH=models/best_fruits_legumes.pt
MODEL_PATH_API=models/best_fruits_legumes.pt
CONFIDENCE=0.45
IOU=0.35
SAVE_FILE=data/stock.json
FLASK_DEBUG=true
FLASK_HOST=0.0.0.0
FLASK_PORT=5000
```

---

## Classes détectables

Le modèle `best_fruits_legumes.pt` détecte **35 classes** de fruits et légumes, dont :

`Apple` · `Banana` · `Strawberry` · `Orange` · `Peach` · `Cucumber` · `Tomato` · et plus...

---

## Dépannage

**`conda` non reconnu dans le .bat**
> Ouvre `start_camera.bat` avec Notepad et ajoute le chemin de ton Anaconda dans la liste des chemins.

**`EOFError` au lancement de Flask**
> Le fichier `.pt` est corrompu ou absent. Vérifie `ls -lh models/` dans le container. Remplace le fichier.

**Stock non mis à jour dans l'API**
> Vérifie que `data/stock.json` est accessible depuis le container. Le fichier doit être dans le volume monté.

**Camera non détectée**
> Vérifie que la webcam n'est pas utilisée par une autre application. Change `CAMERA_ID=1` dans `.env` si tu as plusieurs caméras.

---

## Contributeurs

| Nom | Rôle |
|-----|------|
| rezgu | Développeur principal |

---

## Licence

Usage interne — projet académique / professionnel.
