# SkyTrack - Flight Tracking iOS App — Complete Plan

## Table of Contents

1. [Market Research & Competitive Analysis](#1-market-research--competitive-analysis)
2. [Feature Specification](#2-feature-specification)
3. [Technical Architecture](#3-technical-architecture)
4. [Project Structure](#4-project-structure)
5. [Development Phases & Roadmap](#5-development-phases--roadmap)
6. [API & Data Sources](#6-api--data-sources)
7. [UI/UX Design Guidelines](#7-uiux-design-guidelines)
8. [Debugging & Quality Assurance](#8-debugging--quality-assurance)

---

## 1. Market Research & Competitive Analysis

### Top Flight Tracking Apps (Ranked by Downloads & Popularity)

| Rank | App | Downloads/Users | Rating | Pricing |
|------|-----|----------------|--------|---------|
| 1 | **Flightradar24** | #1 in 150+ countries, 4M+ daily users | 4.5★ | Free / Silver $2.99/mo / Gold $7.99/mo |
| 2 | **FlightAware** | 12M+ users worldwide | 4.6★ | Free / Premium tiers |
| 3 | **Flighty** | Millions (iOS only) | 4.8★ | Free / Pro $49/yr or $300 lifetime |
| 4 | **FlightStats** (Cirium) | Millions | 4.3★ | Free / $2.99/mo premium |
| 5 | **App in the Air** | 5M+ users | 4.6★ | Free / Pro $49.99/yr |
| 6 | **PlaneFinder** | 1M+ | 4.4★ | $4.99 one-time |
| 7 | **The Flight Tracker** | 1M+ | 4.7★ | $4.99 one-time |
| 8 | **OpenADSB** | Top 7 paid travel | 4.5★ | $10.99 one-time |

### Key Differentiators by App

- **Flightradar24**: Largest ADS-B network (40,000+ receivers), best 3D/AR views, most comprehensive global coverage
- **Flighty**: Fastest alerts (2–90 min ahead of airlines), ML delay predictions, Apple Design Award winner, best iOS-native UX
- **FlightAware**: Best developer API (AeroAPI), predictive ETA with Foresight ML, strong enterprise features
- **FlightStats**: 93% delay prediction accuracy, strongest historical data analytics
- **App in the Air**: Best travel stats/gamification, carbon footprint tracking, lounge access integration

---

## 2. Feature Specification

### CATEGORY A: Core Flight Tracking (Must-Have — MVP)

#### A1. Real-Time Flight Map
- Interactive world map showing live aircraft positions
- Aircraft icons with rotation based on heading
- Tap aircraft for flight details panel
- Smooth animation of aircraft movement
- Pinch-to-zoom with clustering at lower zoom levels
- Day/night overlay on map

#### A2. Flight Search
- Search by flight number (e.g., UA123)
- Search by route (e.g., SFO → JFK)
- Search by airport (departures/arrivals)
- Search by airline
- Autocomplete suggestions with IATA/ICAO codes
- Recent searches history

#### A3. Flight Detail Panel
- Flight number, airline name & logo
- Origin/destination with airport names & IATA codes
- Scheduled vs actual departure/arrival times
- Flight status (On Time, Delayed, Cancelled, Diverted, Landed)
- Flight progress bar with percentage complete
- Gate information (departure & arrival)
- Terminal information
- Baggage claim carousel number
- Aircraft type, registration, and photo
- Ground speed, altitude, vertical speed
- Route distance and estimated remaining time

#### A4. My Flights (Personal Flight List)
- Add flights manually by flight number + date
- Flight cards with at-a-glance status
- Upcoming vs past flights sections
- Pull-to-refresh for status updates
- Swipe actions (delete, share, archive)

#### A5. Push Notifications & Alerts
- Departure time changes
- Arrival time changes
- Gate changes
- Cancellation alerts
- Delay alerts with reason
- Boarding time reminders
- Landing notification
- Baggage carousel assignment

### CATEGORY B: Airport Information (Must-Have — MVP)

#### B1. Airport Overview
- Airport name, IATA/ICAO code, city, country
- Airport map with terminal layout
- Current weather conditions (temp, wind, visibility, conditions)
- Airport delay index / performance status
- Operating hours
- Timezone information

#### B2. Departure & Arrival Boards
- Live departure board with flight number, destination, gate, status, time
- Live arrival board with flight number, origin, gate, status, time
- Filter by airline, terminal, status
- Sort by time, status, airline
- Color-coded status indicators (green=on-time, yellow=delayed, red=cancelled)

#### B3. Airport Weather
- Current conditions (METAR data decoded)
- Forecast (TAF data decoded)
- Wind direction and speed visualization
- Visibility conditions
- Weather radar overlay near airport

### CATEGORY C: Smart Features (High Priority — Phase 2)

#### C1. Delay Prediction Engine
- ML-based delay prediction up to 6 hours in advance
- Late aircraft tracking ("Where's My Plane" — track inbound aircraft)
- ATC ground stop/delay monitoring
- Weather impact analysis
- Historical on-time performance scoring
- Delay reason explanation (late aircraft, ATC, weather, crew, maintenance)
- Confidence score for predictions

#### C2. Auto-Import & Sync
- Email parsing for booking confirmations (IMAP integration)
- Calendar import (iOS Calendar integration)
- TripIt import
- iCloud sync across devices
- Automatic flight detection from forwarded emails

#### C3. Smart Notifications
- Predictive alerts before airline announces delays
- "Leave Now" alerts based on distance to airport + traffic
- Connection risk alerts for layovers
- Airport congestion warnings
- TSA wait time estimates

### CATEGORY D: Social & Sharing (Medium Priority — Phase 2)

#### D1. Flight Sharing
- Share flight status via iMessage, WhatsApp, email
- Shareable live tracking link
- Share as image card (flight details snapshot)
- Deep link support (open specific flight in app)

#### D2. Friends Tracking (Flighty Friends equivalent)
- Track friends/family flights privately
- Real-time landing countdown for airport pickups
- Delay and gate change alerts for tracked flights
- No account required for person being tracked

#### D3. CarPlay Integration
- Show active flights on CarPlay dashboard
- Pickup countdown timer
- Navigate to airport terminal

### CATEGORY E: 3D & AR Features (Medium Priority — Phase 3)

#### E1. Augmented Reality View
- Point device at sky to identify flights overhead
- Aircraft photo, flight number, origin/destination overlay
- Tap to track any identified flight
- Altitude and speed indicators in AR

#### E2. 3D Flight View
- 3D terrain rendering
- Realistic aircraft model with airline livery
- Pilot's eye view (cockpit perspective)
- Smooth flight following with map rotation
- Aircraft shadow rendering

### CATEGORY F: Travel Stats & History (Medium Priority — Phase 3)

#### F1. Personal Flight Log / Passport
- Complete flight history with stats
- Total miles/kilometers flown
- Total flights and flight hours
- Airlines used (frequency breakdown)
- Aircraft types flown
- Airports visited (map visualization)
- Countries visited counter
- Year-in-review annual summary
- Time lost to delays aggregate

#### F2. Aircraft History
- Tail number tracking
- Aircraft age and model details
- Previous routes of specific aircraft
- Aircraft photo gallery

### CATEGORY G: Advanced Map Features (Nice-to-Have — Phase 3)

#### G1. Map Layers & Filters
- Filter by: airline, aircraft type, altitude range, speed range
- Filter by flight category: passenger, cargo, military, private
- Weather layers: clouds, precipitation, wind, turbulence
- Aeronautical charts overlay
- Oceanic tracks (NAT, PACOTS)
- ATC/FIR boundaries
- Volcanic ash cloud layer

#### G2. Airport Heatmap
- Real-time airport busyness visualization
- Departure/arrival density
- Delay heatmap by region

### CATEGORY H: Widgets & Platform Integration (High Priority — Phase 2)

#### H1. iOS Widgets
- Small: Next flight countdown with status
- Medium: Active flight progress with ETA
- Large: Upcoming flights list with statuses
- Lock Screen widgets: flight countdown, status indicator

#### H2. Live Activities & Dynamic Island
- In-flight progress bar
- Countdown to landing
- Gate change notifications
- Delay updates in real-time

#### H3. Apple Watch App
- Active flight status at a glance
- Boarding time complication
- Gate information
- Nearby aircraft list

#### H4. Siri & Shortcuts
- "Hey Siri, what's the status of flight UA123?"
- "Hey Siri, when does my next flight depart?"
- Shortcuts integration for automation workflows

### CATEGORY I: Premium & Monetization (Phase 4)

#### I1. Subscription Tiers
- **Free**: Basic tracking, flight search, airport info, 3 active flights, 7-day history
- **Pro ($4.99/mo or $39.99/yr)**: Unlimited flights, push notifications, delay predictions, widgets, Live Activities, 1-year history, no ads
- **Elite ($9.99/mo or $79.99/yr)**: Everything in Pro + 3D/AR views, advanced filters, weather layers, unlimited history, CarPlay, priority support

#### I2. Onboarding & Trial
- First flight gets all Pro features free
- 7-day free trial for new users
- Feature highlights during onboarding

---

## 3. Technical Architecture

### Technology Stack

| Component | Technology |
|-----------|-----------|
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI (iOS 17+) |
| **Architecture** | MVVM + Clean Architecture |
| **Maps** | MapKit (SwiftUI native) |
| **AR** | ARKit + RealityKit |
| **3D** | SceneKit / RealityKit |
| **Networking** | URLSession + async/await |
| **Data Persistence** | SwiftData (Core Data successor) |
| **Cloud Sync** | CloudKit |
| **Push Notifications** | APNs + Firebase Cloud Messaging |
| **Analytics** | Firebase Analytics |
| **CI/CD** | Xcode Cloud / GitHub Actions |
| **Dependency Manager** | Swift Package Manager |
| **Minimum iOS** | iOS 17.0 |
| **Supported Devices** | iPhone, iPad, Apple Watch, CarPlay |

### Architecture Diagram (MVVM + Clean Architecture)

```
┌──────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                    │
│  ┌──────────┐  ┌──────────────┐  ┌────────────────────┐ │
│  │  Views    │  │  ViewModels  │  │  View Components   │ │
│  │ (SwiftUI)│──│ (@Observable)│  │  (Reusable UI)     │ │
│  └──────────┘  └──────────────┘  └────────────────────┘ │
├──────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                         │
│  ┌──────────┐  ┌──────────────┐  ┌────────────────────┐ │
│  │  Models  │  │  Use Cases   │  │  Repository        │ │
│  │          │  │              │  │  Protocols          │ │
│  └──────────┘  └──────────────┘  └────────────────────┘ │
├──────────────────────────────────────────────────────────┤
│                       DATA LAYER                          │
│  ┌──────────┐  ┌──────────────┐  ┌────────────────────┐ │
│  │  API     │  │  Local DB    │  │  Repository        │ │
│  │  Service │  │ (SwiftData)  │  │  Implementations   │ │
│  └──────────┘  └──────────────┘  └────────────────────┘ │
├──────────────────────────────────────────────────────────┤
│                    INFRASTRUCTURE                          │
│  ┌──────────┐  ┌──────────────┐  ┌────────────────────┐ │
│  │ Network  │  │  CloudKit    │  │  Location          │ │
│  │ Client   │  │  Sync        │  │  Services          │ │
│  └──────────┘  └──────────────┘  └────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### Key Architecture Decisions

1. **MVVM with @Observable (iOS 17)**: SwiftUI's new observation framework for clean, reactive data binding without Combine boilerplate
2. **Clean Architecture layers**: Strict separation — Views never touch network/DB directly
3. **Protocol-oriented repositories**: Easy to mock for testing and swap data sources
4. **Coordinator pattern**: For navigation management across complex flows
5. **Dependency injection**: Via environment values and a lightweight DI container
6. **Actor-based concurrency**: Swift actors for thread-safe flight data updates
7. **Combine for real-time streams**: WebSocket/SSE flight position streams via Combine publishers

---

## 4. Project Structure

```
SkyTrack/
├── SkyTrack.xcodeproj
├── SkyTrack/
│   ├── App/
│   │   ├── SkyTrackApp.swift              # App entry point
│   │   ├── AppDelegate.swift              # Push notifications, lifecycle
│   │   └── DependencyContainer.swift      # DI setup
│   │
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── Flight.swift               # Flight data model
│   │   │   ├── Airport.swift              # Airport data model
│   │   │   ├── Airline.swift              # Airline data model
│   │   │   ├── Aircraft.swift             # Aircraft data model
│   │   │   ├── FlightStatus.swift         # Status enum & metadata
│   │   │   ├── WeatherInfo.swift          # Weather data model
│   │   │   └── FlightPosition.swift       # Real-time position model
│   │   │
│   │   ├── Services/
│   │   │   ├── FlightTrackingService.swift     # Core tracking logic
│   │   │   ├── NotificationService.swift       # Push notification handling
│   │   │   ├── LocationService.swift           # User location manager
│   │   │   ├── DelayPredictionService.swift    # ML delay predictions
│   │   │   └── ImportService.swift             # Email/calendar import
│   │   │
│   │   ├── Repositories/
│   │   │   ├── Protocols/
│   │   │   │   ├── FlightRepositoryProtocol.swift
│   │   │   │   ├── AirportRepositoryProtocol.swift
│   │   │   │   └── UserFlightRepositoryProtocol.swift
│   │   │   ├── FlightRepository.swift
│   │   │   ├── AirportRepository.swift
│   │   │   └── UserFlightRepository.swift
│   │   │
│   │   └── UseCases/
│   │       ├── TrackFlightUseCase.swift
│   │       ├── SearchFlightsUseCase.swift
│   │       ├── GetAirportInfoUseCase.swift
│   │       ├── PredictDelayUseCase.swift
│   │       └── ImportFlightsUseCase.swift
│   │
│   ├── Features/
│   │   ├── Map/
│   │   │   ├── Views/
│   │   │   │   ├── FlightMapView.swift          # Main map screen
│   │   │   │   ├── AircraftAnnotationView.swift  # Custom plane marker
│   │   │   │   ├── FlightPathOverlay.swift       # Route line drawing
│   │   │   │   └── MapFilterSheet.swift          # Filter controls
│   │   │   └── ViewModels/
│   │   │       └── FlightMapViewModel.swift
│   │   │
│   │   ├── FlightDetail/
│   │   │   ├── Views/
│   │   │   │   ├── FlightDetailView.swift        # Flight info screen
│   │   │   │   ├── FlightProgressBar.swift       # Progress indicator
│   │   │   │   ├── FlightTimelineView.swift      # Event timeline
│   │   │   │   └── AircraftInfoCard.swift        # Aircraft details
│   │   │   └── ViewModels/
│   │   │       └── FlightDetailViewModel.swift
│   │   │
│   │   ├── Search/
│   │   │   ├── Views/
│   │   │   │   ├── SearchView.swift              # Search screen
│   │   │   │   ├── SearchResultsView.swift       # Results list
│   │   │   │   └── RecentSearchesView.swift      # Search history
│   │   │   └── ViewModels/
│   │   │       └── SearchViewModel.swift
│   │   │
│   │   ├── MyFlights/
│   │   │   ├── Views/
│   │   │   │   ├── MyFlightsView.swift           # Personal flight list
│   │   │   │   ├── FlightCardView.swift          # Individual flight card
│   │   │   │   └── AddFlightSheet.swift          # Add new flight
│   │   │   └── ViewModels/
│   │   │       └── MyFlightsViewModel.swift
│   │   │
│   │   ├── Airport/
│   │   │   ├── Views/
│   │   │   │   ├── AirportDetailView.swift       # Airport info screen
│   │   │   │   ├── DepartureBoardView.swift      # Departures list
│   │   │   │   ├── ArrivalBoardView.swift        # Arrivals list
│   │   │   │   └── AirportWeatherView.swift      # Weather display
│   │   │   └── ViewModels/
│   │   │       └── AirportViewModel.swift
│   │   │
│   │   ├── AR/
│   │   │   ├── Views/
│   │   │   │   ├── ARFlightView.swift            # AR camera overlay
│   │   │   │   └── ARFlightAnnotation.swift      # AR flight label
│   │   │   └── ViewModels/
│   │   │       └── ARFlightViewModel.swift
│   │   │
│   │   ├── Stats/
│   │   │   ├── Views/
│   │   │   │   ├── TravelStatsView.swift         # Stats dashboard
│   │   │   │   ├── FlightHistoryView.swift       # Past flights list
│   │   │   │   └── YearInReviewView.swift        # Annual summary
│   │   │   └── ViewModels/
│   │   │       └── StatsViewModel.swift
│   │   │
│   │   ├── Friends/
│   │   │   ├── Views/
│   │   │   │   ├── FriendsListView.swift         # Friends tracking
│   │   │   │   └── FriendFlightCard.swift        # Friend's flight
│   │   │   └── ViewModels/
│   │   │       └── FriendsViewModel.swift
│   │   │
│   │   └── Settings/
│   │       ├── Views/
│   │       │   ├── SettingsView.swift             # App settings
│   │       │   ├── SubscriptionView.swift         # Premium plans
│   │       │   └── NotificationSettingsView.swift # Alert preferences
│   │       └── ViewModels/
│   │           └── SettingsViewModel.swift
│   │
│   ├── Networking/
│   │   ├── APIClient.swift                 # Base networking client
│   │   ├── APIEndpoints.swift              # Endpoint definitions
│   │   ├── APIModels/
│   │   │   ├── FlightAPIResponse.swift
│   │   │   ├── AirportAPIResponse.swift
│   │   │   └── WeatherAPIResponse.swift
│   │   ├── WebSocketClient.swift           # Real-time position stream
│   │   └── NetworkMonitor.swift            # Connectivity handling
│   │
│   ├── Persistence/
│   │   ├── SwiftDataModels/
│   │   │   ├── PersistedFlight.swift
│   │   │   ├── PersistedAirport.swift
│   │   │   └── PersistedSearchHistory.swift
│   │   ├── ModelContainer+Setup.swift
│   │   └── CloudKitSync.swift
│   │
│   ├── DesignSystem/
│   │   ├── Theme/
│   │   │   ├── AppColors.swift             # Color palette
│   │   │   ├── AppTypography.swift         # Text styles
│   │   │   ├── AppSpacing.swift            # Layout constants
│   │   │   └── AppIcons.swift              # SF Symbols mapping
│   │   ├── Components/
│   │   │   ├── StatusBadge.swift           # On-time/delayed badge
│   │   │   ├── FlightNumberLabel.swift     # Styled flight number
│   │   │   ├── AirportCodeLabel.swift      # IATA code display
│   │   │   ├── TimeDisplay.swift           # Formatted time views
│   │   │   ├── LoadingView.swift           # Loading states
│   │   │   └── ErrorView.swift             # Error states
│   │   └── Modifiers/
│   │       ├── CardModifier.swift
│   │       └── ShimmerModifier.swift
│   │
│   ├── Utilities/
│   │   ├── DateFormatters.swift
│   │   ├── DistanceCalculator.swift
│   │   ├── CoordinateUtils.swift
│   │   └── Constants.swift
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   ├── Localizable.strings
│   │   ├── AirlineLogos/
│   │   └── AircraftModels/              # 3D models for AR
│   │
│   └── Extensions/
│       ├── CLLocationCoordinate2D+Extensions.swift
│       ├── Date+Extensions.swift
│       ├── Color+Extensions.swift
│       └── String+Extensions.swift
│
├── SkyTrackWidgets/
│   ├── SmallFlightWidget.swift
│   ├── MediumFlightWidget.swift
│   ├── LargeFlightWidget.swift
│   └── LockScreenWidgets.swift
│
├── SkyTrackWatch/
│   ├── WatchApp.swift
│   ├── FlightStatusView.swift
│   ├── ComplicationProvider.swift
│   └── NearbyAircraftView.swift
│
├── SkyTrackLiveActivity/
│   ├── FlightLiveActivity.swift
│   ├── FlightActivityAttributes.swift
│   └── LiveActivityView.swift
│
├── SkyTrackTests/
│   ├── ViewModelTests/
│   ├── RepositoryTests/
│   ├── UseCaseTests/
│   └── ServiceTests/
│
├── SkyTrackUITests/
│   └── FlowTests/
│
└── Packages/
    └── SkyTrackNetworking/             # SPM local package for networking
```

---

## 5. Development Phases & Roadmap

### Phase 1: Foundation & MVP (Weeks 1–6)

**Goal**: Working app with core tracking, search, and airport info

| Week | Tasks | Deliverables |
|------|-------|-------------|
| **1** | Project setup, architecture scaffold, design system | Xcode project, folder structure, theme/colors, reusable components |
| **2** | API integration (AviationStack or FlightAware), networking layer | APIClient, flight search working, models mapped |
| **3** | Flight Map — MapKit integration, aircraft annotations, flight path overlay | Interactive map with live aircraft positions |
| **4** | Flight Detail — full detail panel, progress bar, timeline | Complete flight detail screen |
| **5** | Search — flight/airport/route search with autocomplete; My Flights — add/manage flights | Working search and personal flight list |
| **6** | Airport info — departure/arrival boards, weather; push notifications setup | Airport screens, basic notifications |

**Phase 1 Debug Checkpoints:**
- [ ] API responses are correctly parsed (unit tests for all API models)
- [ ] Map annotations render without memory leaks (Instruments profiling)
- [ ] Flight positions update smoothly (no UI jank)
- [ ] Push notification payload handling verified
- [ ] Offline graceful degradation tested
- [ ] All ViewModels have unit test coverage ≥ 80%

### Phase 2: Smart Features & Platform Integration (Weeks 7–12)

**Goal**: Delay predictions, widgets, Live Activities, auto-import

| Week | Tasks | Deliverables |
|------|-------|-------------|
| **7** | Delay prediction engine — ML model integration, late aircraft tracking | Working delay predictions with confidence scores |
| **8** | Auto-import — email parsing, calendar integration, TripIt sync | Automatic flight detection from email/calendar |
| **9** | iOS Widgets — small, medium, large, lock screen | All widget sizes working with timeline updates |
| **10** | Live Activities & Dynamic Island — in-flight progress, gate changes | Live Activity with real-time updates |
| **11** | Apple Watch app — flight status, complications, nearby aircraft | WatchOS companion app |
| **12** | Smart notifications — predictive alerts, "leave now", connection risk | Intelligent notification system |

**Phase 2 Debug Checkpoints:**
- [ ] ML model accuracy ≥ 85% on test dataset
- [ ] Widget timeline provider tested for all edge cases
- [ ] Live Activity updates reliably in background
- [ ] Watch app communicates correctly with phone app
- [ ] Email parser handles top 20 airline confirmation formats
- [ ] Background fetch doesn't drain battery (Energy Diagnostics)

### Phase 3: Social, AR & Advanced Features (Weeks 13–18)

**Goal**: Friends tracking, AR view, 3D flight view, travel stats

| Week | Tasks | Deliverables |
|------|-------|-------------|
| **13** | Flight sharing — share cards, deep links, iMessage integration | Sharing flow complete |
| **14** | Friends tracking — private flight tracking, pickup countdowns | Friends feature working |
| **15** | AR View — ARKit camera overlay, flight identification | AR flight identification |
| **16** | 3D Flight View — SceneKit terrain, aircraft models with liveries | 3D following view |
| **17** | Travel stats — flight log, maps, year-in-review | Stats dashboard |
| **18** | Advanced map — filters, weather layers, ATC boundaries | Advanced map overlays |

**Phase 3 Debug Checkpoints:**
- [ ] AR view handles edge cases (no flights overhead, camera permissions denied)
- [ ] 3D rendering performance ≥ 60fps on iPhone 14
- [ ] Deep links resolve correctly from all sharing methods
- [ ] Stats calculations match manual verification
- [ ] Memory usage stays under 200MB during AR sessions

### Phase 4: Polish, Monetization & Launch (Weeks 19–24)

**Goal**: Subscription system, CarPlay, Siri, final polish, App Store launch

| Week | Tasks | Deliverables |
|------|-------|-------------|
| **19** | Subscription — StoreKit 2 integration, paywall, trial logic | In-app purchase flow |
| **20** | CarPlay integration, Siri Shortcuts, Spotlight indexing | Platform integrations |
| **21** | Onboarding flow, app tutorial, accessibility audit | First-run experience |
| **22** | Performance optimization — startup time, scroll performance, memory | Optimized app |
| **23** | Beta testing (TestFlight), crash monitoring, analytics setup | TestFlight build |
| **24** | App Store submission — screenshots, description, ASO, launch | App Store release |

---

## 6. API & Data Sources

### Primary API: AviationStack (Recommended for MVP)

**Why**: Generous free tier (500 requests/month), simple REST API, comprehensive data, good documentation

```
Base URL: http://api.aviationstack.com/v1/

Endpoints:
  GET /flights          — Real-time flight data
  GET /flights?dep_iata=SFO  — Departures from airport
  GET /flights?arr_iata=JFK  — Arrivals at airport
  GET /flights?flight_iata=UA123 — Specific flight
  GET /airports          — Airport database
  GET /airlines          — Airline database
  GET /airplanes         — Aircraft database
  GET /routes            — Route database
```

**Pricing**:
- Free: 500 requests/month
- Basic: $49.99/mo — 10,000 requests
- Professional: $149.99/mo — 50,000 requests
- Business: $499.99/mo — 250,000 requests

### Secondary API: FlightAware AeroAPI (For Premium Features)

**Why**: Best predictive ETA (Foresight ML), deepest historical data (since 2011), event-driven alerts

```
Base URL: https://aeroapi.flightaware.com/aeroapi/

Key Endpoints:
  GET /flights/{ident}         — Flight info by ident
  GET /flights/{ident}/track   — Flight position track
  GET /airports/{id}/flights   — Airport flights
  GET /airports/{id}/weather   — Airport weather
  POST /alerts                 — Set up flight alerts
```

**Pricing**:
- Personal: $1/query (first 15 queries free)
- Standard: Custom pricing
- Premium: Custom pricing (includes Foresight)

### Supplementary Data Sources

| Source | Use Case | Cost |
|--------|----------|------|
| **OpenSky Network** | Free ADS-B position data for map | Free (open source) |
| **AirLabs** | Real-time flight radar data | Free tier available |
| **Aviation Edge** | Airport codes, airline data, routes | From $15/mo |
| **OpenWeather API** | Airport weather data | Free tier (1000 calls/day) |
| **FAA SWIM** | US airspace data, ground stops, delays | Free (registration required) |
| **Eurocontrol** | European ATC data | Free (registration required) |

### Recommended API Strategy

```
Phase 1 (MVP):        AviationStack (primary) + OpenSky (map positions)
Phase 2 (Smart):      + FlightAware AeroAPI (predictions) + FAA SWIM (delays)
Phase 3 (Advanced):   + AirLabs (extended data) + OpenWeather (weather layers)
Phase 4 (Production): Evaluate costs, potentially build own ADS-B aggregation
```

---

## 7. UI/UX Design Guidelines

### Design Principles (iOS Native)

1. **Dark-first design** — Aviation apps look best with dark backgrounds (like cockpit instruments)
2. **Glanceable information** — Key data visible without tapping
3. **Status color system** — Consistent color coding across all screens
4. **Fluid animations** — Smooth transitions following iOS design language
5. **Accessibility** — VoiceOver, Dynamic Type, and color-blind safe palettes

### Color Palette

```
Background:      #0A0E1A (deep navy)
Surface:         #141929 (card background)
Surface Elevated:#1E2338 (elevated cards)
Primary:         #4A9EFF (sky blue — active tracking)
Success:         #34D058 (on-time, landed)
Warning:         #FFB020 (delayed)
Danger:          #F85149 (cancelled, diverted)
Text Primary:    #FFFFFF
Text Secondary:  #8B92A8
Text Tertiary:   #565E75
Accent:          #A78BFA (premium features)
```

### Typography (SF Pro)

```
Title:           SF Pro Display Bold 28pt
Heading:         SF Pro Display Semibold 22pt
Subheading:      SF Pro Text Medium 17pt
Body:            SF Pro Text Regular 15pt
Caption:         SF Pro Text Regular 13pt
Flight Number:   SF Mono Bold 20pt (monospace for codes)
IATA Code:       SF Mono Semibold 15pt
Time:            SF Mono Medium 17pt (tabular figures)
```

### Key Screen Layouts

**Tab Bar Navigation:**
1. **Map** (globe icon) — Default landing screen
2. **My Flights** (airplane icon) — Personal tracked flights
3. **Search** (magnifying glass) — Flight/airport search
4. **Stats** (chart icon) — Travel statistics
5. **Settings** (gear icon) — App configuration

**Flight Detail Sheet:**
- Presented as a `.sheet` sliding up from bottom
- Drag handle for interactive dismissal
- Sections: Status Header → Progress → Times → Gate/Terminal → Aircraft → Weather

---

## 8. Debugging & Quality Assurance

### Step-by-Step Debugging Protocol

#### Level 1: Build-Time Checks
```
1. Enable all Xcode warnings (-Wall, -Wextra equivalents)
2. Enable strict concurrency checking (Swift 6 preparation)
3. SwiftLint configuration for consistent code style
4. No force unwraps (!) allowed — use guard/if-let
5. All API models conform to Codable with custom keys
```

#### Level 2: Unit Testing Strategy
```
1. Every ViewModel gets a corresponding test file
2. Repository protocols enable mock injection
3. API response parsing tested with JSON fixtures
4. Date/timezone calculations tested across timezones
5. Coordinate math tested with known flight paths
6. Target: ≥ 80% code coverage on domain + data layers
```

#### Level 3: Runtime Debugging
```
1. Instruments: Time Profiler for scroll/map performance
2. Instruments: Allocations for memory leak detection
3. Instruments: Network for API call optimization
4. Instruments: Energy Log for background fetch impact
5. Console logging with os_log (categorized by subsystem)
6. Network request/response logging in DEBUG builds
7. Flight data sanity checks (position within valid coordinates, speed > 0)
```

#### Level 4: UI/UX Testing
```
1. XCUITest for critical user flows (search → track → notification)
2. Snapshot tests for all screens (light/dark mode, accessibility sizes)
3. VoiceOver audit for every interactive element
4. Dynamic Type tested at all 7 size categories
5. iPad layout verification (split view, slide over)
6. Memory pressure simulation (backgrounding with many tracked flights)
```

#### Level 5: Integration Testing
```
1. API failure simulation (no network, timeout, 500, rate limit)
2. Push notification payload handling (all 8+ notification types)
3. Widget timeline accuracy verification
4. Live Activity lifecycle testing (start, update, end, stale)
5. Background app refresh reliability
6. CloudKit sync conflict resolution
```

#### Level 6: Pre-Release Checklist
```
1. TestFlight internal build → team testing (1 week)
2. TestFlight external build → beta testers (2 weeks)
3. Crash-free rate target: ≥ 99.5%
4. App launch time target: < 1.5 seconds (cold start)
5. API response caching verified (offline mode)
6. App Store screenshot validation on all device sizes
7. Privacy nutrition labels accurate
8. App Review Guidelines compliance check
```

### Logging Architecture

```swift
// Structured logging with subsystems
import os

extension Logger {
    static let networking = Logger(subsystem: "com.skytrack.app", category: "networking")
    static let tracking   = Logger(subsystem: "com.skytrack.app", category: "tracking")
    static let map        = Logger(subsystem: "com.skytrack.app", category: "map")
    static let notifications = Logger(subsystem: "com.skytrack.app", category: "notifications")
    static let persistence = Logger(subsystem: "com.skytrack.app", category: "persistence")
}

// Usage: Logger.networking.info("Flight \(flightId) position updated")
// Usage: Logger.tracking.error("Failed to parse flight data: \(error)")
```

---

## Summary: Feature Priority Matrix

| Priority | Category | Features | Phase |
|----------|----------|----------|-------|
| **P0 — Critical** | Core Tracking | Real-time map, flight search, flight detail, my flights, push alerts | Phase 1 |
| **P0 — Critical** | Airport | Airport info, departure/arrival boards, weather | Phase 1 |
| **P1 — High** | Smart | Delay predictions, auto-import, smart notifications | Phase 2 |
| **P1 — High** | Platform | Widgets, Live Activities, Apple Watch | Phase 2 |
| **P2 — Medium** | Social | Sharing, friends tracking, CarPlay | Phase 3 |
| **P2 — Medium** | Visual | AR view, 3D flight view | Phase 3 |
| **P2 — Medium** | Analytics | Travel stats, flight log, year-in-review | Phase 3 |
| **P3 — Low** | Advanced | Map filters, weather layers, ATC boundaries | Phase 3 |
| **P3 — Low** | Business | Subscriptions, onboarding, analytics | Phase 4 |

---

*This plan is designed to compete with Flightradar24, Flighty, and FlightAware by combining the best features from each into a single, beautifully designed iOS-native experience.*
