# 🏆 Shiksha Saathi - Implementation Plan (Final)

> **Hackathon Deadline:** January 23, 2026 (5 days from now)  
> **Status:** APPROVED - Building Now! 🚀

---

## 📦 Final Tech Stack

| Component | Technology | Notes |
|-----------|------------|-------|
| **Frontend** | Flutter 3.38.2 | Android priority, Web support |
| **Backend** | **Django REST Framework** | Changed from FastAPI |
| **Database** | SQLite (dev) / PostgreSQL (prod) | Django ORM |
| **LLM (Online)** | Gemini API | API key to be added |
| **LLM (Offline)** | Pre-cached responses | 200+ scenarios |
| **RAG Vector DB** | ChromaDB | Embedded in Django |
| **Embeddings** | Gemini Embeddings | For RAG search |
| **PDF Processing** | PyMuPDF + LangChain | NCF document |
| **Offline Storage** | ObjectBox | Flutter local DB |
| **Python Env** | Conda `prajatantra` | Existing environment |

---

## 📁 Project Structure

```
sikhsa_sathi/
│
├── 📱 flutter_app/                    # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/                      # Theme, constants, routing
│   │   ├── services/                  # API, voice, storage
│   │   ├── models/                    # Data models
│   │   ├── features/                  # Feature modules
│   │   └── shared/                    # Shared widgets
│   └── pubspec.yaml
│
├── 🐍 backend/                        # Django Backend
│   ├── manage.py
│   ├── config/                        # Django settings
│   │   ├── __init__.py
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── api/                           # DRF API app
│   │   ├── __init__.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   └── models.py
│   ├── rag/                           # RAG pipeline
│   │   ├── __init__.py
│   │   ├── indexer.py
│   │   ├── retriever.py
│   │   └── gemini_client.py
│   ├── requirements.txt
│   └── .env                           # API keys here
│
├── 📄 NCF-FS_2022EN.pdf               # Source PDF
├── 📄 project_overview.txt            # Requirements
└── 📁 .gemini/                        # Plans & docs
    └── implementation_plan.md
```

---

## 🔑 Environment Configuration

### Backend (.env file)

```env
# Django
DEBUG=True
SECRET_KEY=your-django-secret-key
ALLOWED_HOSTS=localhost,127.0.0.1

# Gemini AI - ADD YOUR KEY HERE
GEMINI_API_KEY=your-gemini-api-key-here

# Database (SQLite for dev)
DATABASE_URL=sqlite:///db.sqlite3
```

### Flutter (lib/core/constants/env.dart)

```dart
class Env {
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
  // Will be configured for production
}
```

---

## 🌐 DRF API Endpoints

### Base URL: `http://localhost:8000/api/v1/`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health/` | Health check |
| POST | `/sos/` | Get AI strategies |
| POST | `/feedback/` | Submit strategy feedback |
| GET | `/strategies/` | Browse cached strategies |
| GET | `/strategies/{id}/` | Strategy details |

### SOS Request/Response

```json
// POST /api/v1/sos/
// Request
{
  "query": "बच्चे भिन्न समझ नहीं रहे",
  "context": {
    "grade": "4",
    "subject": "गणित",
    "class_size": 35,
    "time_left_minutes": 10,
    "language": "hi"
  }
}

// Response
{
  "success": true,
  "strategies": [
    {
      "id": 1,
      "title": "रोटी Division Method",
      "time_minutes": 2,
      "steps": ["Draw roti...", "Divide...", "Ask..."],
      "materials": ["blackboard", "chalk"],
      "ncf_alignment": "Concrete to abstract"
    },
    // ... 2 more strategies
  ],
  "offline_available": true
}
```

---

## 📅 Development Schedule

### Day 1 (Today - Jan 18) ✅ IN PROGRESS

- [x] Create implementation plan
- [ ] Set up Flutter project with design system
- [ ] Set up Django project with DRF
- [ ] Create .env with API key placeholder
- [ ] Index NCF PDF into ChromaDB

### Day 2 (Jan 19)

- [ ] Complete RAG pipeline
- [ ] Implement /sos/ endpoint
- [ ] Flutter: Home screen UI
- [ ] Flutter: SOS bottom sheet

### Day 3 (Jan 20)

- [ ] Flutter: SOS response screen
- [ ] API integration
- [ ] Offline cached responses
- [ ] Voice input

### Day 4 (Jan 21)

- [ ] Library screen
- [ ] Search functionality
- [ ] Settings screen
- [ ] Polish & animations

### Day 5 (Jan 22-23)

- [ ] Bug fixes
- [ ] Demo video
- [ ] Pitch deck

---

## 🚀 Starting Development Now

Creating:

1. Django backend project
2. Flutter app project
3. All necessary configuration files

Let's win this hackathon! 🏆
