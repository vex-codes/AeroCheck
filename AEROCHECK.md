# Product Requirements Document (PRD) & Technical Blueprint
## Project Name: AeroCheck (iOS)
### Zero-Cost, Serverless Pre-Flight Airspace & Risk Assessment Engine for Part 107 Remote Pilots

---

## 1. Executive Summary & Core Objectives

### 1.1 Mission & Identity
* **App Store Display Name:** **AeroCheck** (Subtitle: *Pre-Flight 107 Risk Engine*)
* **Bundle Identifier:** `com.developer.aerocheck`
* **Mission:** To provide commercial (Part 107) and recreational UAS operators with a unified, zero-friction, native iOS pre-flight risk evaluation tool. AeroCheck consolidates airspace classification, UASFM ceiling grids, aviation weather (METAR/TAF), estimated wind shear profiles up to 400 ft AGL, and automated "Go / No-Go" risk matrix generation into a single screen—exporting an audit-ready compliance PDF with one tap.

### 1.2 The "Zero-Cost & Zero-Certification" Constraint
* **Zero Infrastructure Cost:** The application requires **no custom cloud backend, no database hosting fees, and no paid API keys**. All data fetching, geospatial queries, and physical calculations execute client-side via Apple frameworks and free, non-authenticated public endpoints.
* **No LAANC Certification Overhead:** Rather than undertaking the costly and legally complex process of becoming an FAA-approved LAANC USS (UAS Service Supplier), AeroCheck acts as an intelligence aggregator. It computes whether authorization is required, displays the exact UASFM ceiling grid, and deep-links directly to free, certified USS applications (such as AutoPylot or Aloft) for filing when necessary.

---

## 2. Technical Stack & System Architecture

```
                                  [Pilot's iPhone / iPad]
                                             │
                        ┌────────────────────┴────────────────────┐
                        ▼                                         ▼
            CoreLocation Services                            MapKit Native
            (GPS Lat, Lon, Altitude)                  (Local Caching & Overlays)
                        │                                         │
     ┌──────────────────┼────────────────────────┬────────────────┘
     ▼                  ▼                        ▼
FAA ArcGIS REST    NOAA AWC METAR           Open-Meteo REST
(Airspace/UASFM)   (Aviation Weather)       (Atmospheric Winds)
     │                  │                        │
     └──────────────────┬────────────────────────┘
                        ▼
             [On-Device Swift Engines]
             ├── Point-in-Polygon Airspace Solver
             ├── Atmospheric & Wind Shear Engine
             ├── Density Altitude Calculator
             └── Aircraft Envelope Evaluator (vs. Preset Drone Specs)
                        │
                        ▼
             [SwiftUI Presentation Layer]
             ├── Master Go / No-Go Status Gauge
             ├── Flight Profile Customizer
             └── 1-Tap Native PDFKit Export Engine
```

### 2.1 Core iOS Frameworks
* **Language:** Swift 5.10 / Swift 6 (Strict Concurrency enabled)
* **UI Framework:** SwiftUI (iOS 17.0+ target)
* **Geospatial & Mapping:** `CoreLocation`, `MapKit`
* **Local Persistence:** `SwiftData` or native `UserDefaults` (for drone profiles, history, and offline presets)
* **Document Generation:** `PDFKit` & `WebKit`
* **Networking:** Native `URLSession` with `async/await` (no third-party pods or packages required)

---

## 3. Data Integration Specifications (100% Free Public APIs)

The app queries three non-authenticated endpoints concurrently using `async let`:

### 3.1 FAA Open Data ArcGIS REST API (Airspace & UASFM Ceilings)
* **Source:** FAA UAS Data Delivery System (Open ArcGIS REST Services)
* **Endpoints:**
  * *UAS Facility Maps (UASFM):* 
    `https://services6.arcgis.com/ssFJjBtikUpload/arcgis/rest/services/UASFM_Admin_Feature_Layer/FeatureServer/0/query`
  * *Controlled Airspace Boundaries (Class B, C, D, E Surface):*
    `https://services6.arcgis.com/ssFJjBtikUpload/arcgis/rest/services/Controlled_Airspace/FeatureServer/0/query`
* **Query Parameters:**
  * `geometry=${lon},${lat}`
  * `geometryType=esriGeometryPoint`
  * `inSR=4326`
  * `spatialRel=esriSpatialRelIntersects`
  * `outFields=*`
  * `returnGeometry=false` (or `true` if rendering airspace polygon outlines on `MapKit`)
  * `f=pjson`
* **Extracted Attributes:** `CEILING` (integer: 0, 50, 100, ..., 400), `AIRSPACE_CLASS` (B, C, D, E), `NAME`, `IDENT`.

### 3.2 NOAA Aviation Weather Center (AWC) API
* **Source:** National Oceanic and Atmospheric Administration
* **Endpoint:** `https://aviationweather.gov/api/data/metar`
* **Query Parameters:**
  * `bbox=${lon-0.5},${lat-0.5},${lon+0.5},${lat+0.5}` (searches stations within bounding box)
  * `format=json`
* **Extracted Data:**
  * Station identifier (ICAO)
  * Observation timestamp
  * Surface wind speed & gust (`wspd`, `wgst` in knots)
  * Wind direction (`wdir`)
  * Flight category (`fltcat`: VFR, MVFR, IFR, LIFR)
  * Cloud ceiling height (`ceil` in hundreds of feet AGL)
  * Visibility (`visib` in statute miles)
  * Temperature (`temp` in $^\circ\text{C}$) & Dewpoint (`dewp`)
  * Altimeter setting (`altim` in hPa / inHg)

### 3.3 Open-Meteo Weather API (Wind Shear & High Altitude Winds)
* **Source:** Open-Meteo (Free for non-commercial/standard tier, no API key required)
* **Endpoint:** `https://api.open-meteo.com/v1/forecast`
* **Query Parameters:**
  * `latitude=${lat}&longitude=${lon}`
  * `hourly=wind_speed_10m,wind_speed_80m,wind_speed_120m,wind_gusts_10m,temperature_2m`
  * `wind_speed_unit=mph` (or `knots`)
  * `forecast_days=1`
* **Purpose:** Direct access to predicted winds at $10\text{ m}$ (~33 ft), $80\text{ m}$ (~260 ft), and $120\text{ m}$ (~400 ft AGL) to eliminate pure estimation when atmospheric sounding models are available.

---

## 4. Mathematical & Algorithmic Engines

All analytical processing happens on-device inside dedicated Swift service actors.

### 4.1 Wind Shear Gradient Profile Engine
When Open-Meteo wind data at altitude is unavailable or offline, AeroCheck applies the **Hellmann Wind Power Law** against the surface NOAA METAR reading to estimate wind velocity at typical UAS operating altitudes ($100\text{ ft}, 200\text{ ft}, 300\text{ ft}, 400\text{ ft}$ AGL):

$$v(z) = v_{10} \times \left(\frac{z}{z_{10}}\right)^\alpha$$

* Where:
  * $z$ = Target flight altitude in meters ($400\text{ ft} \approx 121.92\text{ m}$).
  * $z_{10}$ = Standard METAR measurement height ($10\text{ m} \approx 32.8\text{ ft}$).
  * $v_{10}$ = Surface wind speed recorded at the station.
  * $\alpha$ = Wind shear exponent (empirically derived surface roughness):
    * $\alpha = 0.15$ (Open flat terrain, runways, water bodies)
    * $\alpha = 0.20$ (Suburban terrain, low-density tree cover)
    * $\alpha = 0.30$ (Dense urban centers, structural wind canyons)

### 4.2 Density Altitude & Motor Degradation Engine
Calculates true aerodynamic strain and battery load:
1. **Pressure Altitude ($PA$):**
   $$PA = h_{\text{elevation}} + (29.92 - P_{\text{altim}}) \times 1000$$
   *(where $h_{\text{elevation}}$ is in feet, $P_{\text{altim}}$ is in inHg).*

2. **Standard Temperature ($T_{\text{std}}$ at elevation):**
   $$T_{\text{std}} = 15^\circ\text{C} - \left(1.98^\circ\text{C} \times \frac{h_{\text{elevation}}}{1000}\right)$$

3. **Density Altitude ($DA$):**
   $$DA = PA + 118.8 \times (T_{\text{actual}} - T_{\text{std}})$$

* **Risk Metric:** If $DA > 4000\text{ ft}$, flag an advisory: *"High Density Altitude: Expect a 10–18% drop in motor thrust efficiency and faster battery discharge rates."*

### 4.3 Automated Go / No-Go Risk Assessment Matrix (RAM)

| Factor | Critical (RED / NO-GO) | Warning (YELLOW / CAUTION) | Clear (GREEN / GO) |
| :--- | :--- | :--- | :--- |
| **Airspace Class** | Controlled (B/C/D/E2) with **0 ft Ceiling Grid** | Controlled with Ceiling $> 0\text{ ft}$ (Requires LAANC) | Class G Uncontrolled (Up to 400 ft AGL) |
| **Visibility** | $< 3.0\text{ Statute Miles}$ (FAA § 107.51 violation) | $3.0\text{ to }5.0\text{ Statute Miles}$ | $> 5.0\text{ Statute Miles}$ |
| **Cloud Ceiling** | $< 500\text{ ft AGL}$ (Cannot maintain § 107.51 clearance) | $500\text{ to }1000\text{ ft AGL}$ | $> 1000\text{ ft AGL}$ or Clear |
| **Wind at 400 ft** | Gusts $>$ Aircraft Max Rating (e.g., $> 24\text{ mph}$ for Mini) | Gusts within 15% of Max Rating | Wind & Gusts well within limits |
| **TFR / NOTAM** | Active TFR polygon intersection | Adjacent TFR within $3\text{ NM}$ | No active TFRs |

---

## 5. Drone Profiles & Specs (Preloaded Local JSON)

The app ships with pre-populated configurations and allows pilots to add custom setups:

```json
[
  {
    "id": "dji-mini-4-pro",
    "name": "DJI Mini 4 Pro",
    "weightGrams": 249,
    "maxWindResistanceMph": 24.0,
    "maxOperatingTempC": 40.0,
    "minOperatingTempC": -10.0,
    "category": "Sub-250g / Cat 1 Eligible"
  },
  {
    "id": "dji-air-3",
    "name": "DJI Air 3",
    "weightGrams": 720,
    "maxWindResistanceMph": 27.0,
    "maxOperatingTempC": 40.0,
    "minOperatingTempC": -10.0,
    "category": "Standard Commercial"
  },
  {
    "id": "dji-mavic-3-pro",
    "name": "DJI Mavic 3 Pro / Enterprise",
    "weightGrams": 958,
    "maxWindResistanceMph": 27.0,
    "maxOperatingTempC": 40.0,
    "minOperatingTempC": -10.0,
    "category": "Standard Commercial"
  },
  {
    "id": "dji-matrice-350-rtk",
    "name": "DJI Matrice 350 RTK",
    "weightGrams": 6470,
    "maxWindResistanceMph": 33.5,
    "maxOperatingTempC": 50.0,
    "minOperatingTempC": -20.0,
    "category": "Heavy Enterprise / IP55"
  },
  {
    "id": "custom-5in-fpv",
    "name": "Custom 5-inch FPV Quad",
    "weightGrams": 680,
    "maxWindResistanceMph": 35.0,
    "maxOperatingTempC": 45.0,
    "minOperatingTempC": -5.0,
    "category": "FPV Acro / Cinematic"
  }
]
```

---

## 6. User Interface & Screen Specifications

### Screen 1: Flight Dashboard (Primary View)
* **Top Bar:** Location name / GPS coordinates, current Drone Profile pill selector.
* **Hero Widget:** **Go / Caution / No-Go Verdict Banner** with color status (Green, Amber, Crimson) and summary rationale (e.g., *"Safe to fly in Class G up to 400 ft. Wind shear stable."*).
* **Map Card:** `MapKit` showing drone icon at GPS coordinates, surrounding airspace circular buffer, and UASFM grid polygon boundaries.
* **Airspace & LAANC Card:**
  * Airspace Class indicator badge (e.g., `CLASS G - UNCONTROLLED` or `CLASS D - CONTROLLED`).
  * UASFM Max Ceiling allowed without special authorization.
  * **"Open LAANC Provider" Deep Link button** (App Links to AutoPylot, Aloft, or AirControl).
* **Atmospheric & Wind Shear Card:**
  * Surface Wind vs. 400 ft estimated wind bar charts.
  * Visibility, Cloud Ceiling, Density Altitude indicator, and Temperature.
* **Bottom Action:** Prominent *"Generate Risk Assessment & Sign Off"* button.

### Screen 2: Pre-Flight Checklist & Sign-Off Modal (§ 107.49)
* Interactive switches conforming to FAA Part 107.49:
  * [ ] Airframe, propellers, and structural components inspected.
  * [ ] Battery securely latched; cells balanced; voltage nominal.
  * [ ] Control links, fail-safe RTH altitude set above nearest obstacle.
  * [ ] Visual Observer briefed / airspace clear of non-participating personnel.
* Digital signature field (`PencilKit` or signature trace).
* Pilot Certificate Number entry field.

### Screen 3: Audit-Ready PDF Generator & Exporter
* Generates an official, clean **FAA Part 107 Pre-Flight Risk Assessment Matrix (RAM)** in PDF format via `PDFKit`.
* Includes:
  * Timestamp, Pilot Name, Remote Pilot Certificate #.
  * Aircraft make, model, serial, and weight.
  * Latitude, Longitude, and nearest street/city address.
  * Raw METAR string from nearest aviation station + time of observation.
  * Density Altitude, calculated 400 ft winds, visibility, cloud ceiling.
  * Airspace class, UASFM grid ceiling, and LAANC status.
  * Completed pre-flight checklist verification and pilot signature image.
* Native iOS Share Sheet trigger (`UIActivityViewController`) to save to Files, AirDrop, or attach to an email.

---

## 7. Master AI Prompt for Antigravity IDE / Cursor

*Copy and paste the entire block below directly into your AI IDE to generate the complete iOS application codebase:*

```markdown
You are an expert Principal iOS Engineer specializing in SwiftUI, MapKit, CoreLocation, and FAA Part 107 Aviation Systems.

Build a complete, standalone, production-ready native iOS app named "AeroCheck" (com.developer.aerocheck) in Swift (iOS 17+ target). 
The app must have ZERO backend dependencies, ZERO paid API keys, and require NO developer fee subscriptions.

### Architecture Requirements:
1. Pure SwiftUI with MVVM architecture + Swift Concurrency (`async/await`, `@Observable` macros).
2. Clean separation of concerns:
   - `Services/`: Network requests and calculation algorithms.
   - `Models/`: Swift `Codable` structs for FAA GeoJSON, NOAA METAR, Open-Meteo, and Drone Profiles.
   - `ViewModels/`: Observable state managing GPS location, data fetching, and risk status.
   - `Views/`: Modular SwiftUI components.
   - `PDF/`: PDFKit-based compliance sheet generator.

### Core Data Services to Implement:
1. `FAADataService.swift`:
   - Query the public FAA ArcGIS REST service for UAS Facility Maps (UASFM) and Controlled Airspace using spatial coordinate intersection (`geometry=${lon},${lat}&geometryType=esriGeometryPoint&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=*&f=pjson`).
   - Parse `AIRSPACE_CLASS` and `CEILING`.
2. `WeatherService.swift`:
   - Query NOAA Aviation Weather Center METAR endpoint (`https://aviationweather.gov/api/data/metar?bbox=...&format=json`) to fetch nearest station METAR, wind, gust, visibility, and cloud ceiling.
   - Query Open-Meteo (`https://api.open-meteo.com/v1/forecast?latitude=...&longitude=...&hourly=wind_speed_10m,wind_speed_80m,wind_speed_120m,wind_gusts_10m&wind_speed_unit=mph`) for high-altitude wind data.
3. `AviationMath.swift`:
   - Calculate wind shear using the Hellmann Power Law: v(z) = v_10 * (z / 10)^alpha (default alpha = 0.2).
   - Calculate Density Altitude: Pressure Altitude + 118.8 * (Actual Temp - Std Temp).
4. `RiskEngine.swift`:
   - Evaluate environmental data against selected `DroneProfile` limits (e.g., DJI Mini 4 Pro, Air 3, Mavic 3 Pro, Matrice 350, Custom FPV).
   - Return an overall status: `.safe` (Green), `.caution` (Yellow), or `.noGo` (Red) with specific human-readable violation bullets.

### User Interface Requirements:
- Modern, clean aviation UI with dark-mode aesthetic.
- Interactive `Map` showing current coordinate and flight boundary radius.
- Big Go / No-Go verdict banner displaying status and rationale.
- 400ft wind shear visualization comparing surface wind vs 400ft altitude.
- Pre-flight checklist modal with digital sign-off (§ 107.49 compliance).
- "Export Audit PDF" button that generates a single-page compliance report using `UIGraphicsPDFRenderer` / `PDFKit` and presents the native iOS share sheet.
- Direct external link button to open popular free LAANC apps (`autopylot://` or web fallback).

Generate all necessary Swift files with complete, working code, proper error handling, mock preview data, and comprehensive comments explaining the Part 107 regulatory tie-ins.
```