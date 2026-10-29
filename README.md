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
| **Tourist mobile app** | Foreign and local tourists | Flutter | Planned: under active development for C2–C4 features |
| **Shared backend** | Both surfaces | FastAPI, MongoDB Atlas | Core service running; individual component routers integrated via a unified DB connection URL |

**Admin web site.** The sidebar has two main section groups:
- **Research & Analytics** (Dashboard, Demand Analytics, Forecast Drivers, Market Graph, Demand Alerts, Spatial Demand Map, Model Management, Data Sources & Upload) — implemented by C1.
- **Platform Modules** (Users, Emergencies, Routes, Destinations, Risk Zones & Hazards) — admin pages for C2–C4 management and shared system administration.

**Tourist mobile app.** Delivers tourist-facing features for C2–C4 (emergency assistance, risk-aware itinerary planning, food safety and allergen support) powered by the central backend API.

---

## 2. Team and responsibilities

| # | Student | Student ID | Component | Admin web part | Mobile app part |
|---|---|---|---|---|---|
| 1 (Leader) | G.V.H. Dilrukshi | IT23281578 | **C1 – Tourist Demand Analytics Engine** | Research & Analytics pages (built) | Serves demand forecast indicators |
| 2 | Sewwandi K.L.  | IT23365100  | **C2 – AI-Based Tourist Emergency Severity Assessment & Response** | Emergencies management | Tourist emergency help & response |
| 3 | E.A.D.A.jithmini  | IT23145702  | **C3 – AI-Powered Smart Itinerary Optimization & Hazard Intelligence** | Routes, Destinations & Risk Zones | Risk-aware itinerary planner |
| 4 |SerasingheS. S.  | IT23372412 | **C4 – AI-Driven Food Safety & Personalization** | Food management admin | Food & allergen analyzer |

---

## 3. Problem and aim

Sri Lankan tourism is recovering, but operators and planners still rely on past static reports. Safety support, itinerary planning, food safety, and demand planning are currently handled by isolated tools. CeylonPath combines four specialized AI components into a single platform to support visitors, hoteliers, and regional authorities.

**Overall aim:** Design, build, and evaluate an integrated platform where each component maintains its router logic while communicating through a shared backend API connected to a central MongoDB database.

---

## 4. System architecture

- **Admin web site:** React (Vite) for administrative research and platform controls.
- **Tourist mobile app:** Flutter mobile app for tourist services.
- **Unified Backend:** Single FastAPI application serving all 4 team members via individual router modules.
- **Database:** Centralized MongoDB Atlas cluster accessed through a single database URI.
- **Integration:** Standardized RESTful endpoints connecting both frontends seamlessly.

---

## 5. Components

## C1 — Tourist Demand Analytics Engine (G.V.H. Dilrukshi, IT23281578)

**Surface:** admin web site (built). No tourist-facing screen.

### Problem and research gap

Hoteliers, tour operators and planners in Sri Lanka plan staffing, pricing and capacity from past SLTDA reports, which describe what happened but do not forecast it. Monthly arrivals swing sharply, for example from 279,328 in February 2026 to 135,643 in April 2026. Existing forecasting work treats national arrivals as one isolated series (ARIMA, regression), or uses graph models without outside economic or aviation signals. The proposal's literature review found no study that combines a graph of related tourism markets with source-country macroeconomic and aviation data for Sri Lanka.

**Scope change from the proposal.** SLTDA does not publish monthly regional data (room and attraction data are annual), so the component forecasts arrivals by **source market** (10 markets, 1-month horizon) instead of by region.

### Approach and model(s)

- **Target:** monthly tourist arrivals for the 10 largest source markets (India, United Kingdom, Russian Federation, Germany, China, Australia, France, United States, Canada, Maldives).
- **Proposed model: ST-GNN + GRU** (PyTorch).
  - Each market is a graph node. Each market is linked to its 3 most correlated markets (correlation of monthly changes in the training data), giving 23 edges.
  - A graph layer mixes each market with its neighbours, then a GRU reads a 12-month window.
  - The model learns a correction to a seasonal × drift baseline (same month last year × recent 3-month growth), in log scale.
  - Inputs per market and month: log arrivals, source-country inflation, a COVID flag, month of year (sin/cos).
  - 5 copies trained with different random seeds, averaged.
- **Comparison models:** seasonal naive, seasonal × drift, Ridge, XGBoost, GRU without the graph (ablation), ST-GNN without inflation (ablation).
- **Evaluation:** rolling-origin, 5 folds with 6-month test windows (Apr 2024 – Sep 2026, 30 test months). Each fold trains only on earlier months, with 6 months for early stopping. Metrics: MAE, RMSE, MAPE, WAPE, plus Diebold-Mariano significance tests.
- **Admin dashboard:** React front end + FastAPI back end that loads the saved model and serves forecasts.

### Dataset(s) and source

| Dataset | Source | Coverage | Use |
|---|---|---|---|
| Tourist arrivals by country and month | SLTDA "Tourist Arrivals from All Countries" files | Jan 2019 – Sep 2026, 206 countries | Model target and inputs |
| Monthly and weekly arrival totals | SLTDA weekly and monthly reports | Jan 2023 – Oct 2026 | Checking totals, dashboard |
| Annual tourism indicators (earnings, stay, occupancy, employment) | SLTDA Annual Statistical Reports, Year in Review | 2019 – 2025 | Context |
| Hotel rooms by province; attraction visitors | SLTDA Year in Review | Rooms 2019 – 2025; attractions 2022 – 2025 | Illustrative map page only |
| Inflation (consumer prices, annual %) | World Bank Open Data | 2019 – 2025 (2026 reuses 2025) | Model input |
| Airline and last-departure-airport tables | SLTDA Monthly Report, Feb 2026 | Single month | Analysis of hub dependence only |

All SLTDA data was extracted into one workbook (`SLTDA ALL DATA.xlsx`). Country figures matched the official monthly totals in every month checked (85 of 93 months in the first check; the rest are being verified). All data is aggregated and public; no personal data is used.

### Results so far (metrics)

Folds 2–5 (fold 1 had only 36 usable training samples). Lower is better.

| Model | MAE | RMSE | MAPE (%) | WAPE (%) |
|---|---|---|---|---|
| Seasonal naive | 2,363 | 3,919 | 19.8 | 18.1 |
| **Seasonal × drift (best baseline)** | **1,803** | 3,332 | 16.1 | **13.8** |
| Ridge | 1,919 | 3,374 | 16.8 | 14.7 |
| XGBoost | 2,152 | 3,805 | 18.9 | 16.4 |
| GRU (no graph) | 1,837 | **3,259** | 16.1 | 14.0 |
| **ST-GNN + GRU (proposed)** | 1,838 | 3,273 | 16.0 | 14.0 |
| ST-GNN, no inflation | 1,823 | 3,318 | **15.9** | 13.9 |

All five folds pooled (MAPE / WAPE): seasonal × drift 19.1 / 15.9, ST-GNN + GRU 21.0 / 17.5.

MAPE by test window, ST-GNN vs drift baseline:

| Test window | Training samples | Drift MAPE (%) | ST-GNN MAPE (%) |
|---|---|---|---|
| Apr 2024 | 36 | 31.0 | 41.4 |
| Oct 2024 | 51 | 12.8 | 13.1 |
| Apr 2025 | 105 | 17.4 | 18.2 |
| Oct 2025 | 165 | 16.6 | 15.9 |
| Apr 2026 | 225 | 17.5 | 16.7 |

**What the results show**
- The ST-GNN is level with the drift baseline: 16.0 % vs 16.1 % MAPE. The difference is not significant (Diebold-Mariano p = 0.135).
- The ST-GNN is ahead of the baseline in the two latest windows, which have the most training data, but behind it in two earlier ones. This is suggestive only, not established.
- It is significantly better than Ridge (p = 0.019) and XGBoost (p = 0.007), but that result is driven by fold 1.
- The graph adds no measurable gain over the GRU without the graph (p = 0.122). Inflation's effect is inconsistent across folds.
- The proposal's target of a 10–15 % MAPE reduction over the best baseline (SO5) is **not met yet**.
- Results are stable across random seeds: pooled MAPE varies by ±0.5.
- The March–April 2026 drop affected markets very differently (UK, Germany, France and Russia fell sharply; India and China grew). This coincides with Middle East flight disruption and cannot be anticipated from arrival history alone, which motivates adding aviation data.

**Admin web pages (implemented by C1)**

| Page | Route | Shows | Data status |
|---|---|---|---|
| Dashboard | `/dashboard` | Last-month arrivals, next-month forecast, forecast error (ST-GNN WAPE 14.0 %), alerts, low-confidence flags | API-connected |
| Demand Analytics | `/demand-analytics` | Arrivals by source market, forecast vs backtest, year-on-year change, forecast range | API-connected |
| Forecast Drivers | `/forecast-drivers` | Model inputs and the inflation ablation (SHAP not computed yet) | Partly API-connected |
| Market Graph | `/market-graph` | 10 markets, 23 edges (density 0.51), linked by correlation of monthly changes; shows co-movement, not tourist flow | API-connected |
| Demand Alerts | `/demand-alerts` | Outlook alerts and backtest alerts (for example March–April 2026) | API-connected |
| Spatial Demand Map | `/spatial-demand-map` | Illustrative district visualisation — **demo data, not a model output** | Demo |
| Model Management | `/model-management` | Metrics for all models (folds 2–5), significance tests | API-connected |
| Data Sources & Upload | `/data-sources` | SLTDA arrivals and World Bank inflation (active); aviation data not available | Partly API-connected |


### Status at PP1

| Item | Status |
|---|---|
| SLTDA data extraction and cleaning (2019 – Sep 2026) | ✅ Done |
| World Bank inflation input | ✅ Done |
| Market graph (correlation links) | ✅ Done |
| ST-GNN + GRU model, trained and saved (`stgnn_gru.pt`, trained to Sep 2025) | ✅ Done |
| Baselines, ablations, rolling evaluation, significance tests | ✅ Done |
| FastAPI forecast service | ✅ Done |
| React admin pages (8 pages) | 🔄 Built; connecting remaining pages to the API |
| Run the dashboard with the trained model on a laptop | 🔄 In progress |
| Retrain on data up to Sep 2026 | 🔄 In progress |
| LSTM version (the proposal states LSTM; current model uses GRU) | 🔄 In progress |
| ARIMA/SARIMA and ARDL baselines (listed in the proposal) | 📋 Planned |
| Exchange rate and GDP inputs | 📋 Planned |
| Aviation data (OpenSky, or SLTDA airline/airport tables for route-based links) | 📋 Planned |
| Login with hashed passwords and JWT; MongoDB integration | 📋 Planned |
| SUS usability test with hoteliers (target ≥ 68) | 📋 Planned |

### API endpoints and MongoDB collection

Base URL: `http://localhost:8000` (interactive docs at `/docs`). 

| Method | Endpoint | Returns |
|---|---|---|
| GET | `/api/health` | Model status, markets, data range, warnings |
| GET | `/api/overview` | Headline numbers for the dashboard |
| GET | `/api/arrivals/monthly?months=36` | Total monthly arrivals, all countries |
| GET | `/api/markets` | The 10 forecast markets |
| GET | `/api/forecast/next` | Next-month forecast per market, 80 % range, baseline, alerts |
| GET | `/api/forecast/history?market=India&months=36` | Actual vs model vs baseline for one market |
| GET | `/api/model/evaluation` | Evaluation results and live accuracy |
| GET | `/api/regions` | Hotel rooms and top attractions by province |
| POST | `/api/reload` | Re-read data files after adding a new month |

**MongoDB collection (planned): `demand_forecasts`.** One document per market and month, so the mobile app and other components can read forecasts (example values):

```json
{
  "market": "India",
  "month": "2026-10",
  "forecast": 51412,
  "low": 39254,
  "high": 63569,
  "baseline": 51879,
  "change_vs_last_year_pct": 6.9,
  "alert": null,
  "model_version": "stgnn_gru_v1",
  "trained_to": "2025-09",
  "created_at": "2026-10-27T00:00:00Z"
}

### How to run

1. Put the data files (`SLTDA ALL DATA.xlsx`, `Worldbank data.xls`) and the model file `stgnn_gru.pt` in the data folder configured in `.env`. `<TODO: confirm folder and variable names.>`
2. Start the backend and the admin web site as described in Section 9.
3. Open `http://localhost:8000/docs` to test the API, then `http://localhost:5173`.
4. After adding a new month of data, call `POST /api/reload`.

Training notebooks are in `components/c1-demand-analytics/notebooks/` (data and baselines → rolling-origin evaluation → final fit and export).

### Limitations and next steps until PP2

**Limitations:**
- Only 93 monthly points per market; COVID months cannot be used as training signal.
- Inflation is annual only; there is no flight data yet.
- Prediction intervals are pooled across markets, so they are too narrow for markets that are collapsing (such as Russia, flagged "low confidence").
- One-month horizon only. The model file in use was trained only to Sep 2025.

**Next steps:**
1. Retrain on data to Sep 2026 and update the served model.
2. Source monthly aviation data, or run a hub-exposure scenario analysis from the SLTDA airline and airport tables.
3. Add SARIMA and ARDL baselines and a 25-market run.
4. Add SHAP or feature-group explanations.
5. Add login (hashed passwords, JWT) and protect the routes.
6. Run a hotelier usability test (3–5 participants, SUS ≥ 68).
7. Write forecasts to the `demand_forecasts` collection.
