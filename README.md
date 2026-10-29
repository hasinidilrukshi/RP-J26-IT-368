# CeylonPath — Intelligent Safety, Real-Time Localization, and Predictive Multi-Modal Analytics Framework for Sri Lanka Tourism

| | |
|---|---|
| **Project ID** | J26-IT-368 |
| **Programme** | B.Sc. (Hons) in Information Technology, Specialization in Information Technology |
| **Institute** | Sri Lanka Institute of Information Technology (SLIIT), Department of Information Technology |
| **Supervisor** | Ms. Manori Gamage |
| **Co-supervisor** | Ms. Uthpala Samarakoon |
| **Status** | Progress Presentation 1 (PP1, ~50 % complete) — last updated: `2026-10-29` |

> CeylonPath is an integrated smart-tourism platform for Sri Lanka featuring four distinct AI components developed by a 4-member team. The system utilizes a unified FastAPI backend infrastructure and a centralized MongoDB Atlas database connection. Component 1 (C1) operates and manages the research & analytics modules on the **Admin Web Site**, while Components 2, 3, and 4 (C2–C4) primarily serve tourist-facing features on the **Tourist Mobile App** alongside their administrative modules.

---

## 1. Platform overview

| Surface | Users | Technology | Status at PP1 |
|---|---|---|---|
| **Admin web site** | Researchers, hoteliers, regional tourism authorities, administrators | React (Vite) | Research & Analytics pages (C1) built; other admin pages in progress |
| **Tourist mobile app** | Foreign and local tourists | Flutter | Planned: under active development for C2–C4 features[cite: 14] |
| **Shared backend** | Both surfaces | FastAPI, MongoDB Atlas | Core service running; individual component routers integrated via a unified DB connection URL[cite: 14] |

**Admin web site.** The sidebar has two main section groups:
- **Research & Analytics** (Dashboard, Demand Analytics, Forecast Drivers, Market Graph, Demand Alerts, Spatial Demand Map, Model Management, Data Sources & Upload) — implemented by C1[cite: 14].
- **Platform Modules** (Users, Emergencies, Routes, Destinations, Risk Zones & Hazards) — admin pages for C2–C4 management and shared system administration[cite: 14].

**Tourist mobile app.** Delivers tourist-facing features for C2–C4 (emergency assistance, risk-aware itinerary planning, food safety and allergen support) powered by the central backend API[cite: 14].

---

## 2. Team and responsibilities

| # | Student | Student ID | Component | Admin web part | Mobile app part |
|---|---|---|---|---|---|
| 1 (Leader) | G.V.H. Dilrukshi | IT23281578 | **C1 – Tourist Demand Analytics Engine** | Research & Analytics pages (built)[cite: 14] | Serves demand forecast indicators[cite: 14] |
| 2 | `<Student Name>` | `<IT Number>` | **C2 – AI-Based Tourist Emergency Severity Assessment & Response** | Emergencies management | Tourist emergency help & response[cite: 14] |
| 3 | `<Student Name>` | `<IT Number>` | **C3 – AI-Powered Smart Itinerary Optimization & Hazard Intelligence** | Routes, Destinations & Risk Zones | Risk-aware itinerary planner[cite: 14] |
| 4 | `<Student Name>` | `<IT Number>` | **C4 – AI-Driven Food Safety & Personalization** | Food management admin | Food & allergen analyzer[cite: 14] |

---

## 3. Problem and aim

Sri Lankan tourism is recovering, but operators and planners still rely on past static reports[cite: 14]. Safety support, itinerary planning, food safety, and demand planning are currently handled by isolated tools[cite: 14]. CeylonPath combines four specialized AI components into a single platform to support visitors, hoteliers, and regional authorities[cite: 14].

**Overall aim:** Design, build, and evaluate an integrated platform where each component maintains its router logic while communicating through a shared backend API connected to a central MongoDB database[cite: 14].

---

## 4. System architecture

- **Admin web site:** React (Vite) for administrative research and platform controls[cite: 14].
- **Tourist mobile app:** Flutter mobile app for tourist services[cite: 14].
- **Unified Backend:** Single FastAPI application serving all 4 team members via individual router modules[cite: 14].
- **Database:** Centralized MongoDB Atlas cluster accessed through a single database URI[cite: 14].
- **Integration:** Standardized RESTful endpoints connecting both frontends seamlessly[cite: 14].

---

## 5. Components

### C1 — Tourist Demand Analytics Engine (G.V.H. Dilrukshi, IT23281578)

**Surface:** Admin Web Site (Built)[cite: 14].

#### Problem and research gap
Hoteliers and tourism planners in Sri Lanka plan staffing, pricing, and capacity from historical SLTDA reports, which do not forecast future demand[cite: 14]. Existing forecasting methods treat national arrivals as an isolated series (ARIMA, regression) without integrating macroeconomic indicators or graph-based market dependencies[cite: 14].

#### Approach and model(s)
- **Target:** Monthly tourist arrivals for 10 major source markets[cite: 14].
- **Proposed Model:** ST-GNN + GRU (PyTorch) capturing market co-movement graphs linked by statistical correlations[cite: 14].
- **Inputs:** Log arrivals, source-country inflation, COVID flag, and seasonal encodings[cite: 14].
- **Baselines:** Seasonal naive, Seasonal × drift, Ridge, XGBoost, and ablation models[cite: 14].

*(Refer to C1 documentation directory for detailed metrics and screenshots)*[cite: 14]

---

### C2 — AI-Based Tourist Emergency Severity Assessment & Response (`<Student Name>`, `<IT Number>`)
**Purpose:** Automated incident severity detection and emergency routing[cite: 14].
**Surface:** Admin Web (Emergencies) and Tourist Mobile App[cite: 14].

---

### C3 — AI-Powered Smart Itinerary Optimization & Hazard Intelligence (`<Student Name>`, `<IT Number>`)
**Purpose:** Personalized, risk-aware travel route planning and dynamic rerouting[cite: 14].
**Surface:** Admin Web (Routes/Hazards) and Tourist Mobile App[cite: 14].

---

### C4 — AI-Driven Food Safety & Personalization (`<Student Name>`, `<IT Number>`)
**Purpose:** Culinary image recognition and personalized allergen identification[cite: 14].
**Surface:** Tourist Mobile App and Admin Web (Food Management)[cite: 14].

---

## 6. Technology stack

| Layer | Technology |
|---|---|
| Admin web site | React, Vite[cite: 14] |
| Tourist mobile app | Flutter[cite: 14] |
| Backend | Python, FastAPI, Uvicorn, Motor (Async MongoDB Driver)[cite: 14] |
| Database | MongoDB Atlas (Single shared database URL)[cite: 14] |
| ML / AI | PyTorch, scikit-learn, XGBoost, pandas, NumPy, TensorFlow/PyTorch (C2-C4)[cite: 14] |

---

## 7. Getting started

**1. Configure environment.** Copy `.env.example` to `.env` and fill in the values[cite: 14].

```env
MONGO_URI=<your_shared_mongodb_atlas_connection_string>
ALLOWED_ORIGINS=http://localhost:5173
VITE_API_URL=http://localhost:8000
