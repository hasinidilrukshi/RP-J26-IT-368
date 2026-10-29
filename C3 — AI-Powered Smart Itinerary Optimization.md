# C3 — AI-Powered Smart Itinerary Optimization & Hazard Intelligence

**Owner:** E.A.D.A. Jithmini (IT23145702)  
**Component:** C3 – Smart Itinerary Optimization & Hazard Intelligence  
**Part of:** CeylonPath (J26-IT-368)  
**Status date:** Progress Presentation 1 (PP1, October 2026)  

---

## FEATURE 01: USING NSGA-II (Itinerary Optimization)

### 1. Dataset(s) and Source
* **Dataset:** `sri_lanka_destinations.csv`
* **Data Type:** Structured CSV dataset.
* **Records:** [Insert verified number of destinations].
* **Attributes:** Destination name, latitude, longitude, climate, vibe, estimated cost, and visiting hours.
* **Source:** Existing Sri Lankan tourist destination dataset provided with the project. The original data provider has not yet been verified.
* **Purpose:** Provides destination information for the NSGA-II algorithm to generate personalized itinerary options according to user preferences, available travel time, estimated costs, and geographical distances.

### 2. Results So Far
The NSGA-II itinerary optimization component has been integrated into the Smart Tourist application.
* **Implemented Results:**
  * Successfully generates personalized itinerary options using the NSGA-II optimization algorithm.
  * Provides Best Route, Shortest Route, and Longest Route options.
  * Displays destinations and itinerary information through the application interface.
  * Visualizes selected destinations using a map.
  * **Notes:** Screens selected itineraries against reported hazards; provides alternative itinerary suggestions when suitable candidates are available.
* **Evaluation Results:**
  * Number of destinations considered: [Insert actual value].
  * Number of Pareto-optimal routes generated: [Insert actual result].
  * Estimated distance of selected itinerary: [Insert actual result] km.
  * Estimated itinerary cost: [Insert actual result].

### Status at PP1
| Development Activity | Status |
|---|---|
| Destination dataset preparation | Done |
| NSGA-II optimization implementation | Done |
| User preference collection | Done |
| Best, Shortest, and Longest itinerary generation | Done |
| Destination and itinerary visualization | Done |
| Hazard administration interface | Done |
| Hazard proximity screening | Done |
| Alternative itinerary suggestion | Done |
| Actual road-network routing | Planned |
| Additional optimization testing and validation | In Progress |

### API Endpoints and Database
The itinerary optimization component uses a Python FastAPI backend to process user preferences and generate optimized itinerary options.
* **API Endpoints:**
  * `GET /api/destinations` — Retrieves available tourist destinations.
  * `POST /api/itinerary/optimize` — Generates personalized itinerary options using NSGA-II.
  * `POST /api/itinerary/risk-screen` — Screens selected itineraries against reported hazards and identifies alternative itinerary candidates.
* **Data Storage:**
  * Tourist destination information: CSV dataset.
  * Hazard reports: SQLite database, as documented in the current implementation. *(MongoDB collection details should only be added if MongoDB has actually been implemented).*

### How to Run
* **Backend:**
  1. Open the `SmartTouristBackend` folder in VS Code.
  2. Activate the Python virtual environment.
  3. Install the required Python dependencies.
  4. Start the FastAPI backend using: 
     ```bash
     python -m uvicorn main:app --port 8001
     ```
  5. Verify the API using the FastAPI documentation endpoint at `http://127.0.0.1:8001/docs`.
* **Frontend:**
  1. Open the Flutter project folder containing `pubspec.yaml`.
  2. Install Flutter dependencies using `flutter pub get`.
  3. Run the application using `flutter run -d chrome` for web or `flutter run -d emulator-5554` for the Android emulator.
  4. Configure the backend URL according to the selected platform.

### Limitations and Next Steps Until PP2
* **Current Limitations:**
  * Route distances are calculated using approximate straight-line geographical distances rather than actual road-network distances.
  * Estimated travel costs do not include every possible expense, such as accommodation, meals, and transportation.
  * Hazard screening uses reported locations near destinations and approximate itinerary segments.
  * Alternative itinerary suggestions do not represent actual road-level rerouting.
  * Hazard reports may be unverified and should not be interpreted as official safety warnings.
* **Next Steps:**
  * Investigate road-network-based distance and travel-time calculations.
  * Improve itinerary optimization accuracy through additional testing.
  * Evaluate optimization performance under different user preferences and travel constraints.
  * Improve hazard visualization and alternative itinerary presentation.
  * Conduct user testing and improve the mobile application interface.

---

## FEATURE 02: USING RANDOM FOREST (Weather-Based Risk Prediction)

### 1. Dataset(s) and Source
* **Dataset:** Historical Weather Dataset.
* **Data Source:** Open-Meteo Historical Weather Archive.
* **Data Type:** Structured weather dataset stored in CSV format.
* **Collection Period:** January 2023 – December 2025.
* **Locations:** Kandy, Nuwara Eliya, Ella, Sigiriya, and Colombo.
* **Attributes:** Daily temperature, precipitation, rainfall, and wind-speed information.
* **Total Records:** [Insert verified number of records].
* **Purpose:** The historical weather dataset is used to train a Random Forest classification model to predict whether next-day precipitation reaches the project's experimental heavy-rainfall threshold of 20 mm. The model learns relationships between historical weather conditions and rainfall outcomes to support weather-related risk awareness during tourist itinerary planning.

### 2. Results So Far
The Random Forest model has been developed for weather-based rainfall prediction.
* **Development Results:**
  * Historical weather data prepared for machine-learning training.
  * Random Forest algorithm selected for rainfall classification.
  * Rainfall prediction target defined using the 20 mm daily precipitation threshold.
  * Weather prediction API endpoints documented for backend integration.
  * Weather-related functionality incorporated into the overall application design.
* **Model Evaluation Results:**
  * Training accuracy: [Insert actual value]
  * Testing accuracy: [Insert actual value]
  * Precision: [Insert actual value]
  * Recall: [Insert actual value]
  * F1-score: [Insert actual value]
  * Confusion matrix: [Insert actual result or screenshot]  
  *(These values must be obtained from the actual model evaluation results).*

### Status at PP1
| Development Activity | Status |
|---|---|
| Historical weather data collection | Done |
| Weather dataset preparation | Verify |
| Random Forest model training | Verify |
| Model evaluation | Verify |
| Trained model storage | Verify |
| Backend prediction API implementation | Verify |
| Weather information display | Verify |
| Additional model validation | Planned |
| Improved weather-risk presentation | Planned |

*(Note: The activities marked "Verify" must be updated to Done or In Progress according to the current implementation).*

### API Endpoints and Database
The weather prediction component uses a Python FastAPI backend to process weather information and provide rainfall predictions.
* **API Endpoints:**
  * `GET /api/weather/live` — Retrieves current weather-related information.
  * `GET /api/weather/forecast-assisted-ml` — Provides machine-learning predictions using weather forecast inputs.
  * `GET /api/weather/historical-prediction` — Provides predictions using historical weather-related inputs.
* **Data Storage:**
  * Historical weather information: CSV datasets.
  * Trained Random Forest model: Serialized model files, such as joblib files.
  * Hazard reports: SQLite database, according to the current project documentation.
  *(The weather prediction component uses stored weather data and a trained machine-learning model. MongoDB should only be listed if it is part of the implemented system).*

### How to Run
* **Backend:**
  1. Open the `SmartTouristBackend` project folder in VS Code.
  2. Activate the Python virtual environment.
  3. Ensure the required Python libraries and trained model files are available.
  4. Start the FastAPI backend using: 
     ```bash
     python -m uvicorn main:app --port 8001
     ```
  5. Open the FastAPI documentation interface at `http://127.0.0.1:8001/docs`.
  6. Test the available weather prediction endpoints.
* **Frontend:**
  1. Open the Flutter project.
  2. Run `flutter pub get` to install dependencies.
  3. Start the application using `flutter run -d chrome` or an available Android device.
  4. Generate an itinerary and access the weather-related functionality to view the available weather information and predictions.

### Limitations and Next Steps Until PP2
* **Current Limitations:**
  * The model is trained using historical weather information from selected Sri Lankan locations.
  * Prediction performance may vary for locations or weather conditions not adequately represented in the training dataset.
  * The 20 mm precipitation threshold is an experimental project-defined classification threshold.
  * Weather predictions cannot independently determine whether a destination is safe for travel.
  * The system does not provide officially validated flood, landslide, or other disaster warnings.
* **Next Steps:**
  * Conduct additional model evaluation using unseen weather data.
  * Improve model performance through feature selection and hyperparameter tuning.
  * Evaluate prediction performance across different geographical locations.
  * Improve the integration between rainfall predictions and itinerary planning.
  * Enhance the presentation of weather-related risks in the application.
  * Investigate the use of verified weather alerts and hazard information.
  * Conduct additional testing and validation before PP2.
