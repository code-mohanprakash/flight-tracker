# SkyTrack — Feature Specification (Detailed)

## Competitive Feature Matrix

Based on research of all major flight tracking apps (Flightradar24, FlightAware, Flighty, Plane Finder, RadarBox, KAYAK, FlightStats, byAir, The Flight Tracker Pro), here is a comprehensive breakdown of every feature with implementation details.

---

## PHASE 1: MVP — Core Flight Tracking (Weeks 1-6)

### Feature 1.1: Real-Time Flight Map

**What it does**: Interactive world map showing live aircraft positions in real-time.

**Competitive benchmark**: Flightradar24 (best-in-class), FlightAware, Plane Finder

**Implementation details**:
- MapKit with SwiftUI (`Map` view, iOS 17+)
- Custom `MapAnnotation` for aircraft icons (airplane SF Symbol rotated by heading)
- Aircraft clustering at low zoom levels using `MKClusterAnnotation`
- Flight path overlay using `MapPolyline` for active tracked flights
- Day/night terminator overlay
- Smooth position interpolation between API updates (animate aircraft movement)
- Pull positions from OpenSky Network API (free) every 10 seconds
- Tap annotation → show flight detail sheet

**Data model**:
```swift
struct FlightPosition: Identifiable, Codable {
    let id: String              // ICAO24 transponder address
    let callsign: String?       // Flight callsign (e.g., "UAL123")
    let latitude: Double
    let longitude: Double
    let altitude: Double        // Barometric altitude in meters
    let velocity: Double        // Ground speed in m/s
    let trueTrack: Double       // Heading in degrees (0-360)
    let verticalRate: Double    // Climb/descent rate in m/s
    let onGround: Bool
    let lastUpdate: Date
    let originCountry: String
}
```

**Debug checkpoints**:
- [ ] Map renders without blank tiles
- [ ] Aircraft annotations show correct heading rotation
- [ ] Clustering works smoothly at zoom transitions
- [ ] Memory usage stays under 100MB with 1000+ aircraft visible
- [ ] Position animation is smooth (no teleporting between updates)
- [ ] Tap gesture correctly selects aircraft (not map)

---

### Feature 1.2: Flight Search

**What it does**: Search for flights by number, route, or airport.

**Competitive benchmark**: Flighty (best autocomplete UX), FlightStats (deepest search)

**Implementation details**:
- Tab-based search: "Flight Number" / "Route" / "Airport"
- Autocomplete with debounced API calls (300ms delay)
- IATA/ICAO code recognition (typed "SFO" or "KSFO" resolves to San Francisco International)
- Recent searches stored locally (SwiftData)
- Trending/most-tracked flights section
- Search results as cards with key info (status, time, route)

**Search types**:
```
Flight Number: "UA 123" or "United 123" → Flight detail
Route:         "SFO → JFK" or "SFO JFK" → List of flights on route
Airport:       "SFO" or "San Francisco" → Airport detail with boards
```

**Debug checkpoints**:
- [ ] Autocomplete debounce prevents excessive API calls
- [ ] Search handles IATA, ICAO, city name, and airline name inputs
- [ ] Empty state shown for no results
- [ ] Loading state shown during API call
- [ ] Recent searches persist across app launches
- [ ] Keyboard dismiss on scroll

---

### Feature 1.3: Flight Detail Panel

**What it does**: Complete information panel for a specific flight.

**Competitive benchmark**: Flighty (cleanest design), Flightradar24 (most data)

**Sections**:

**Header**:
- Airline logo + name
- Flight number (styled monospace)
- Aircraft type + registration
- Flight status badge (On Time / Delayed X min / Cancelled / Diverted / Landed)

**Route & Progress**:
- Origin airport (IATA code + city name)
- Destination airport (IATA code + city name)
- Progress bar with airplane icon at current position
- Distance remaining / total distance
- Percentage complete

**Times**:
- Scheduled departure → Actual/Estimated departure
- Scheduled arrival → Actual/Estimated arrival
- Delay duration (highlighted if > 0)
- Flight duration (elapsed / total)

**Gate & Terminal**:
- Departure gate + terminal
- Arrival gate + terminal
- Baggage claim carousel
- Gate change indicator (if changed from original)

**Aircraft Info**:
- Aircraft type (e.g., "Boeing 737-800")
- Registration / tail number
- Aircraft age
- Aircraft photo (from PlaneSpotters API or similar)
- Seat configuration (if available)

**Live Data** (when airborne):
- Ground speed
- Altitude
- Vertical speed (climb/descent)
- Heading
- Current position coordinates

**Data model**:
```swift
struct Flight: Identifiable, Codable {
    let id: String
    let flightNumber: String
    let airline: Airline
    let aircraft: Aircraft?
    let departure: FlightEndpoint
    let arrival: FlightEndpoint
    let status: FlightStatus
    let liveData: LiveFlightData?
    let lastUpdated: Date
}

struct FlightEndpoint: Codable {
    let airport: Airport
    let scheduledTime: Date?
    let estimatedTime: Date?
    let actualTime: Date?
    let gate: String?
    let terminal: String?
    let baggageClaim: String?
    let delay: Int?  // minutes
}

enum FlightStatus: String, Codable {
    case scheduled, active, landed, cancelled, diverted, incident, unknown
}

struct LiveFlightData: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let speed: Double
    let heading: Double
    let verticalSpeed: Double
    let isGround: Bool
    let updated: Date
}
```

**Debug checkpoints**:
- [ ] All time zones handled correctly (display in local airport time)
- [ ] Progress bar accurately reflects position between origin/destination
- [ ] Gate changes visually highlighted
- [ ] Delay minutes calculation handles timezone edge cases
- [ ] Aircraft photo loads or shows placeholder
- [ ] Pull-to-refresh updates all data

---

### Feature 1.4: My Flights (Personal Flight List)

**What it does**: Users save and track their personal flights.

**Competitive benchmark**: Flighty (best organization), byAir (best import)

**Implementation details**:
- Add flight by number + date
- Two sections: "Upcoming" and "Past"
- Flight card with: flight number, route, date, time, status badge
- Swipe to delete
- Tap to open flight detail
- Empty state with illustration + CTA to add first flight
- Pull-to-refresh all tracked flights
- Sort by date (default), airline, status
- SwiftData persistence + CloudKit sync

**Debug checkpoints**:
- [ ] Adding duplicate flight (same number + date) shows error
- [ ] Past flights auto-move from Upcoming to Past after landing
- [ ] SwiftData CRUD operations are atomic and thread-safe
- [ ] CloudKit sync works across iPhone + iPad
- [ ] Empty state renders correctly
- [ ] Swipe-to-delete has confirmation

---

### Feature 1.5: Push Notifications & Alerts

**What it does**: Real-time push alerts for tracked flight changes.

**Competitive benchmark**: Flighty (fastest, 2-90 min ahead of airlines)

**Notification types**:
| Type | Trigger | Priority |
|------|---------|----------|
| Departure delay | Estimated departure changes by > 10 min | High |
| Arrival delay | Estimated arrival changes by > 10 min | High |
| Gate change | Gate number updated | High |
| Cancellation | Flight status → cancelled | Critical |
| Diversion | Flight status → diverted | Critical |
| Boarding soon | 30 min before scheduled departure | Medium |
| Departed | Aircraft pushed back / wheels up | Medium |
| Landed | Aircraft touched down | Medium |
| Baggage claim | Carousel assigned | Low |

**Implementation**:
- APNs registration on app launch
- Background fetch every 5 minutes for tracked flights
- Local notification fallback when server push unavailable
- Notification categories with actions ("View Flight", "Share Update")
- Critical alerts for cancellations (bypass DND)
- Notification settings per flight (All / Important Only / None)

**Debug checkpoints**:
- [ ] APNs token registration succeeds
- [ ] Background fetch fires reliably
- [ ] Notification tap opens correct flight detail
- [ ] Notification grouping by flight works
- [ ] Settings per flight persist correctly
- [ ] No duplicate notifications for same event

---

### Feature 1.6: Airport Information

**What it does**: Comprehensive airport detail pages with live data.

**Competitive benchmark**: FlightStats (most comprehensive), byAir (AI-powered guide)

**Sections**:

**Airport Overview**:
- Name, IATA/ICAO codes, city, country, flag
- Current time at airport (timezone)
- Airport status / delay index
- Basic map with airport location
- Distance from user's location

**Departure Board**:
- Table: Time | Flight | Destination | Gate | Status
- Color-coded status (green/yellow/red)
- Filter by airline, terminal
- Sort by time (default), status, destination
- Auto-refresh every 60 seconds

**Arrival Board**:
- Table: Time | Flight | Origin | Gate | Status | Baggage
- Same filtering and sorting as departures

**Weather**:
- Current conditions: temperature, wind speed/direction, visibility, cloud cover, conditions icon
- Decoded METAR data
- 24-hour forecast summary
- Weather impact on operations (delays expected / normal ops)

**Data model**:
```swift
struct Airport: Identifiable, Codable {
    let id: String            // IATA code
    let iataCode: String
    let icaoCode: String
    let name: String
    let city: String
    let country: String
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let timezone: String
    let altitude: Int?        // feet above sea level
}

struct AirportWeather: Codable {
    let temperature: Double    // Celsius
    let windSpeed: Double      // knots
    let windDirection: Int     // degrees
    let visibility: Double     // km
    let cloudCover: String
    let conditions: String
    let pressure: Double       // hPa
    let humidity: Int          // percentage
    let metar: String?         // raw METAR string
    let updatedAt: Date
}
```

**Debug checkpoints**:
- [ ] Departure/arrival boards load within 2 seconds
- [ ] Board auto-refresh doesn't cause scroll position reset
- [ ] Timezone displays correctly for all airports
- [ ] Weather data shows "unavailable" for airports without METAR
- [ ] Empty departure/arrival boards show meaningful message
- [ ] Airport search works with partial name, IATA, and ICAO

---

## PHASE 2: Smart Features (Weeks 7-12)

### Feature 2.1: Delay Prediction Engine

**What it does**: ML-powered delay predictions hours before airline announces.

**Competitive benchmark**: Flighty (6 hours ahead, ML-based), FlightStats (93% accuracy)

**Prediction factors**:
1. **Late inbound aircraft** — Track the plane assigned to your flight. If it's delayed on its previous leg, your flight will likely be delayed too.
2. **ATC ground stops** — FAA SWIM data for ground delay programs, ground stops, and airspace flow programs.
3. **Weather impact** — Current and forecasted weather at origin, destination, and en-route.
4. **Historical performance** — On-time performance of this flight number over the past 90 days.
5. **Airport congestion** — Current departure/arrival rate vs. capacity.
6. **Crew/maintenance** — Inferred from unusual delay patterns.

**Output**:
```swift
struct DelayPrediction: Codable {
    let flightId: String
    let predictedDelayMinutes: Int
    let confidence: Double         // 0.0 - 1.0
    let primaryReason: DelayReason
    let factors: [DelayFactor]
    let generatedAt: Date
    let validUntil: Date
}

enum DelayReason: String, Codable {
    case lateAircraft
    case weather
    case atcGroundStop
    case atcCongestion
    case crewAvailability
    case maintenance
    case airportCongestion
    case securityEvent
    case unknown
}
```

---

### Feature 2.2: iOS Widgets

**Competitive benchmark**: Flighty (best widget design), Flightradar24 (most tracked widget)

**Widget sizes**:

| Size | Content | Refresh |
|------|---------|---------|
| Small | Next flight: countdown timer, status badge | Every 15 min |
| Medium | Active flight: progress bar, ETA, gate, delay | Every 15 min |
| Large | Next 3 flights: compact cards with status | Every 15 min |
| Lock Screen (circular) | Countdown hours to next flight | Every 15 min |
| Lock Screen (rectangular) | Flight number + status + gate | Every 15 min |

---

### Feature 2.3: Live Activities & Dynamic Island

**Competitive benchmark**: Flighty (best implementation), byAir

**States**:
- **Pre-departure**: Countdown to boarding, gate number, delay status
- **Boarding**: "Now Boarding" indicator, gate number
- **In-flight**: Progress bar, altitude, ETA countdown
- **Approaching**: Landing countdown, arrival gate
- **Landed**: "Landed" status, baggage claim info
- **Gate change**: Highlighted new gate number

---

### Feature 2.4: Auto-Import (Email + Calendar)

**Competitive benchmark**: Flighty (best parser, AI-powered), KAYAK, byAir

**Import sources**:
- iOS Calendar events (EventKit)
- Email forwarding to app-specific address
- TripIt account sync
- Manual entry fallback

---

### Feature 2.5: Apple Watch App

**Competitive benchmark**: Flighty (most complete Watch app)

**Screens**:
- Active flight status (default)
- Boarding time countdown complication
- Gate number complication
- Flight progress complication

---

## PHASE 3: Social & Advanced (Weeks 13-18)

### Feature 3.1: Flight Sharing
- Share flight status as rich card (image)
- Share live tracking link
- iMessage app extension
- Share sheet integration

### Feature 3.2: Friends Tracking
- Add friend by sharing a one-time link
- Private flight tracking (no account required for friend)
- Pickup countdown for airport arrivals
- Gate change alerts for friends' flights

### Feature 3.3: AR Flight View
- ARKit camera with overlay
- Identify overhead flights by pointing camera at sky
- Show flight number, airline, route, altitude
- Tap to track identified flight

### Feature 3.4: 3D Flight View
- SceneKit terrain rendering
- Aircraft 3D models with airline liveries
- Pilot's eye / cockpit perspective
- Following camera mode

### Feature 3.5: Travel Statistics
- Total flights, miles, hours
- Airlines used (pie chart)
- Airports visited (world map with pins)
- Aircraft types flown
- Year-in-review summary (shareable card)
- Time lost to delays aggregate

### Feature 3.6: Advanced Map Layers
- Weather: clouds, precipitation, wind
- Filters: airline, aircraft type, altitude, category (passenger/cargo/military)
- Aeronautical charts
- ATC/FIR boundaries
- Volcanic ash layers

---

## PHASE 4: Polish & Launch (Weeks 19-24)

### Feature 4.1: Subscription (StoreKit 2)
- Free / Pro / Elite tiers
- Paywall at feature boundaries
- Trial logic (first flight gets Pro free)
- Receipt validation
- Family sharing support

### Feature 4.2: CarPlay
- Active flight on dashboard
- Pickup countdown
- Navigate to terminal

### Feature 4.3: Siri & Shortcuts
- "What's the status of flight [X]?"
- "When does my next flight depart?"
- Shortcuts app integration

### Feature 4.4: Onboarding
- 3-screen intro (Track → Predict → Travel)
- Permission requests (notifications, location)
- Import first flight CTA
- Feature tour for premium

### Feature 4.5: Accessibility
- Full VoiceOver support
- Dynamic Type (all 7 sizes)
- Color-blind safe status colors
- Reduced motion support
- High contrast mode

---

## API Endpoints Required (AviationStack)

```
# Flight data
GET /flights?flight_iata=UA123           → Single flight by number
GET /flights?dep_iata=SFO               → Departures from airport
GET /flights?arr_iata=JFK               → Arrivals at airport
GET /flights?airline_iata=UA            → All flights by airline
GET /flights?flight_status=active       → All active flights

# Airport data
GET /airports?iata_code=SFO             → Airport info
GET /airports?search=San Francisco      → Airport search

# Airline data
GET /airlines?iata_code=UA              → Airline info

# Aircraft data
GET /airplanes?registration=N12345      → Aircraft by registration

# Real-time positions (OpenSky Network — free supplement)
GET /states/all?lamin=X&lamax=X&lomin=X&lomax=X  → Aircraft in bounding box
GET /states/all?icao24=ABC123           → Single aircraft position
```

---

## Key Metrics to Track Post-Launch

| Metric | Target | Tool |
|--------|--------|------|
| App Store rating | ≥ 4.7★ | App Store Connect |
| Crash-free rate | ≥ 99.5% | Firebase Crashlytics |
| Cold launch time | < 1.5s | Xcode Instruments |
| API response time (p95) | < 500ms | Custom analytics |
| Push notification delivery | ≥ 98% | APNs dashboard |
| Daily active users (DAU) | Track growth | Firebase Analytics |
| Widget engagement | Track installs | WidgetKit analytics |
| Subscription conversion | ≥ 5% free → Pro | RevenueCat / StoreKit |
| Retention (Day 7) | ≥ 40% | Firebase Analytics |
| Retention (Day 30) | ≥ 20% | Firebase Analytics |
