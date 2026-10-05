# SERVICE - International Universal Commercial Communication Platform
## VS Code Setup & Local Execution Guide

This repository contains the complete enterprise codebase for **SERVICE**, featuring a **Metadata-Driven Dynamic Modular Engine**, **AES-256 Encrypted Private Storage**, **Anti-Double-Charge Contact Unlock Engine**, and a **Flutter + Riverpod Dynamic Form Renderer**.

---

## 📁 Project Architecture & Structure

```text
├── .vscode/
│   └── launch.json                      # VS Code Debug Configurations (F5)
├── app/                                 # FastAPI Python Backend
│   ├── main.py                          # FastAPI App Entrypoint & Middlewares
│   ├── core/                            # Database, Security (Argon2, JWT, AES-256, TOTP)
│   ├── middleware/                      # Country Resolver, Feature Flags, Founder Security, Audit Logger
│   └── modules/
│       ├── dynamic_engine/              # Metadata Engine, Dynamic Validator, Feed & Post APIs
│       ├── founder/                     # Founder Control Center (/founder/*)
│       ├── monetization/                # Unlock Engine & Gateways (bKash, Nagad, Stripe)
│       └── communication/               # Post-Unlock Real-time WebSocket Chat
├── lib/                                 # Flutter Client Application
│   ├── main.dart                        # Flutter Entrypoint
│   └── features/dynamic_form/           # Riverpod Dynamic Form Engine
│       ├── data/models/dynamic_field_model.dart
│       ├── provider/dynamic_form_provider.dart
│       └── presentation/widgets/dynamic_form_widget.dart
├── pubspec.yaml                         # Flutter Dependencies (Riverpod, Http, etc.)
├── requirements.txt                     # Python Backend Dependencies
├── seed_data.py                         # Foundational Database Seed Script
└── test_end_to_end.py                   # Automated Full-Flow Integration Test Suite
```

---

## 🛠 Recommended VS Code Extensions

Before running the project, install the following extensions in VS Code:
1. **Flutter** (`Dart-Code.flutter`)
2. **Dart** (`Dart-Code.dart-code`)
3. **Python** (`ms-python.python`)
4. **Pylance** (`ms-python.vscode-pylance`)

---

## 🚀 Part 1: Backend Setup (FastAPI + PostgreSQL + Redis)

### 1. Prerequisites
- Python 3.10+
- PostgreSQL 15+ (Local or Docker)
- Redis 6+ (Local or Docker)

*(Optional) Start PostgreSQL and Redis via Docker:*
```bash
docker run -d --name service_postgres -p 5432:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=service_db postgres:15
docker run -d --name service_redis -p 6379:6379 redis:7-alpine
```

### 2. Create Virtual Environment & Install Dependencies
Open your terminal in the workspace root:

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# On macOS / Linux:
source venv/bin/activate
# On Windows:
.\venv\Scripts\activate

# Install requirements
pip install -r requirements.txt
```

### 3. Run Database Migrations & Seed Data
```bash
python3 seed_data.py
```
*This populates `service_marketplace`, `vehicle_rental`, 10 dynamic fields (with public/private partitions), and country feature flags.*

### 4. Run the Full Integration Test Suite
Verify that the entire post publication, privacy masking, payment unlock, AES-256 decryption, and WebSocket chat lifecycle works:
```bash
python3 test_end_to_end.py
```

### 5. Start the FastAPI Development Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
- Interactive Swagger API Documentation: [http://localhost:8000/docs](http://localhost:8000/docs)
- Health Check: [http://localhost:8000/health](http://localhost:8000/health)

---

## 📱 Part 2: Flutter App Setup (Riverpod Dynamic Form)

### 1. Prerequisites
- Flutter SDK (3.10+) installed (`flutter doctor`)

### 2. Install Flutter Packages
```bash
flutter pub get
```

### 3. Run Flutter Application
```bash
# Run on Chrome Web browser
flutter run -d chrome

# Or run on connected Android / iOS device / Emulator:
flutter run
```

---

## ⚡ Part 3: VS Code One-Click F5 Debugging

Open the **Run & Debug** tab in VS Code (`Ctrl+Shift+D` or `Cmd+Shift+D`):

Select any of the configured tasks from the dropdown:
1. **`FastAPI: Run Backend (Uvicorn Reload)`**: Launches the backend on port `8000` with debugger attached.
2. **`Flutter: Run & Debug (Web / Mobile)`**: Launches the Flutter app with Hot Reload.
3. **`Python: Run End-to-End Test Suite`**: Executes the 5-step integration test suite in the integrated terminal.

---

## 🔒 Security & Core Principles Checklist
- **No Direct Contact Leakage:** Mobile numbers and exact GPS coordinates are stored AES-256 encrypted and masked as `*** Unlock Required ***` until verified fee payment.
- **Country Resolvers & Feature Flags:** System features automatically fall back from country codes (`BD`, `IN`, `US`) to global default (`*`).
- **Immutable Audit Trail:** All administrative operations are intercepted and recorded in `audit_logs` with automatic masking of sensitive credentials.
