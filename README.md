# AeroCheck

A native iOS pre-flight risk evaluation engine and compliance logging tool for FAA 14 CFR Part 107 commercial remote pilots and sUAS operators.

AeroCheck consolidates controlled airspace classification, UASFM ceiling grids, live aviation weather (NOAA METAR), atmospheric wind sounding up to 400 ft AGL, density altitude thrust penalties, and solar twilight times into a single, glanceable cockpit dashboard. With one tap, it exports an audit-ready compliance PDF signed by the Remote Pilot in Command.

Built with **zero external dependencies, zero developer backend, and zero subscription API keys**. All data fetching, geospatial queries, and aerodynamic calculations execute client-side directly against public federal endpoints.

---

## What It Does

### 1. Tactical Airspace & UASFM Ceilings
* Queries the FAA's public ArcGIS FeatureServer REST endpoints concurrently for active UAS Facility Maps (UASFM) and controlled airspace geometry (Class B, C, D, and Class E surface areas).
* Instantly determines if the launch coordinate requires LAANC authorization, reports maximum auto-approval ceiling grids (0–400 ft AGL), and provides a one-tap deep link to open authorized LAANC suppliers (AutoPylot / Aloft).

### 2. Atmospheric Sounding & Altitudinal Wind Shear
* Fetches the closest NOAA Aviation Weather Center (AWC) METAR observation within a geographic bounding box.
* Queries Open-Meteo atmospheric wind soundings at 10m (~33 ft), 80m (~260 ft), and 120m (~400 ft AGL).
* When high-altitude soundings are unavailable, falls back to the empirical **Hellmann Wind Power Law** ($\alpha = 0.20$) to estimate wind shear gradient across 100 ft, 200 ft, 300 ft, and 400 ft AGL.

### 3. Dynamic Mission Altitude Evaluation
* Remote pilots rarely fly at maximum legal altitude when lower operating envelopes are sufficient. AeroCheck features an interactive altitude track (100 ft – 400 ft AGL).
* If high-shear gusts exceed aircraft limits at 400 ft but conditions are calm at 100 ft, adjusting the mission altitude recalculates the entire risk matrix in real time, turning a restrictive warning into a safe flight authorization.

### 4. Density Altitude & Rotor Thrust Degradation
* Calculates Pressure Altitude ($PA$) and true Density Altitude ($DA$) using station barometric pressure (inHg) and ambient temperature.
* Automatically estimates rotor thrust efficiency loss above 3,000 ft DA, warning the pilot of reduced flight times and diminished climb performance on hot or high-elevation operations.

### 5. Solar & Civil Twilight Calculator (FAA § 107.29)
* Runs on-device astronomical solar algorithms (solar declination, equation of time, hour angle) using coordinates and UTC timestamp.
* Computes civil dawn, sunrise, sunset, and civil dusk.
* Automatically flags civil twilight operations (30 minutes before sunrise / 30 minutes after sunset), reminding pilots that anti-collision lighting visible for at least 3 statute miles is mandatory under § 107.29(b).

### 6. Fleet Management
* Ships with factory specs for 15 DJI drones:
  * **Sub-250g / Cat 1:** Mini 4 Pro, Mini 3 Pro, Mini 2 SE, Neo
  * **Air & Commercial:** Air 3, Air 2S, Mavic 3 Pro, Mavic 3 Classic, Mavic 3 Enterprise (3E/3T)
  * **Cinematic & FPV:** Avata 2, Avata, Inspire 3, Custom 5" FPV
  * **Industrial Enterprise:** Matrice 30T, Matrice 350 RTK
* Full CRUD support: select, rename, edit environmental limits (max wind, min/max operating temps), add custom airframes, or reset to factory defaults.

### 7. Part 107.49 Pre-Flight Sign-Off & Audit PDF
* Integrated interactive checklist covering mandatory FAA pre-flight inspection requirements (airframe, battery lock/balance, fail-safe RTH programming, crew briefing).
* Digital signature capture with pilot certificate number storage.
* Generates a single-page US Letter PDF via `UIGraphicsPDFRenderer` and `PDFKit` with bounded typography to ensure zero text overlap. Includes timestamped file naming (`AeroCheck_RAM_Audit_YYYY-MM-dd_HHmm.pdf`) and native iOS `ShareLink` export.

---

## Zero-Backend Architecture

AeroCheck does not use a cloud server, Supabase instance, Firebase project, or proxy layer:

```
                      [ Pilot's iPhone / iPad ]
                                  │
                 ┌────────────────┴────────────────┐
                 ▼                                 ▼
      CoreLocation & MapKit               AviationMath Engine
     (GPS, Reverse Geocode,              (Density Altitude, Solar,
        Apple Maps Search)                 Hellmann Wind Shear)
                 │                                 │
     ┌───────────┼────────────────────────┐        │
     ▼           ▼                        ▼        ▼
 FAA ArcGIS   NOAA AWC               Open-Meteo  RiskEngine
  REST API    METAR API               REST API   (Part 107 Matrix)
     │           │                        │        │
     └───────────┼────────────────────────┘        ▼
                 ▼                        [ SwiftUI Dashboard ]
       FlightDashboardViewModel                    │
        (@Observable Concurrency)                  ▼
                                           [ PDFKit RAM Export ]
```

* **No tracking, no telemetry, no analytics.** Pilot names, certificate numbers, and custom aircraft profiles stay in `UserDefaults` on the device.
* **Resilient in the field:** Works offline using cached station data and manual coordinate entry when flying in remote areas without cellular connectivity.

---

## Regulations Addressed

| 14 CFR Part 107 Regulation | Compliance Enforcement in AeroCheck |
| :--- | :--- |
| **§ 107.41** Airspace Authorization | Automatic UASFM ceiling lookup, Class B/C/D/E boundary check, LAANC gateway. |
| **§ 107.49** Pre-Flight Verification | Airframe inspection checklist, battery check, fail-safe RTH, PIC sign-off. |
| **§ 107.51** Operating Limitations | 400 ft AGL ceiling check, 3 SM visibility floor, 500 ft below cloud buffer. |
| **§ 107.29** Daylight & Twilight Operations | Astronomical sunrise/sunset/civil twilight calculation, 3 SM strobe reminder. |

---

## Requirements & Building

* **iOS Target:** iOS 17.0+
* **Xcode:** Xcode 15.0+ (Tested through Xcode 16)
* **Swift:** Swift 5.10 / Swift 6 (Strict Concurrency enabled)
* **Dependencies:** None (`SwiftPM: 0`, `CocoaPods: 0`)

### Build Steps

1. Clone repository:
   ```bash
   git clone https://github.com/vex-codes/AeroCheck.git
   cd AeroCheck
   ```

2. Open the Xcode project:
   ```bash
   open AeroCheck.xcodeproj
   ```

3. Select your development team under **Signing & Capabilities** for bundle identifier `com.developer.aerocheck` (or your personal team ID).

4. Select an iOS 17+ Simulator or connected physical device and run (`⌘R`).

Or build via command line:
```bash
xcodebuild -scheme AeroCheck -destination 'generic/platform=iOS Simulator' build
```

---

## Design System

The user interface follows Apple's Human Interface Guidelines with an aviation cockpit visual hierarchy:
* **True OLED Black Canvas** (`#000000`) for night vision preservation in the field.
* **Apple Secondary Surfaces** (`#1C1C1E`) with 0.5pt subtle hairline dividers (`#38383A`).
* **Tactile Aviation Signal Colors:** Status Safe Green (`#34C759`), Warning Amber (`#FF9500`), Regulatory Alert Red (`#FF3B30`), and Tactical Precision Blue (`#0A84FF`).
* **Instant Glanceability:** High-contrast 30pt verdict headline, 28pt numeric telemetry readouts, and spring micro-interactions on all interactive controls.

---

## License

MIT License. Free to use, modify, and distribute.
