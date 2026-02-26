# SkyTrack — Development Roadmap

## Timeline Overview (24 Weeks)

```
Week  1-2  ██░░░░░░░░░░░░░░░░░░░░░░  Foundation & Design System
Week  3-4  ████░░░░░░░░░░░░░░░░░░░░  Map & Flight Tracking Core
Week  5-6  ██████░░░░░░░░░░░░░░░░░░  Search, My Flights, Airports
Week  7-9  █████████░░░░░░░░░░░░░░░  Delay Predictions & Import
Week 10-12 ████████████░░░░░░░░░░░░  Widgets, Live Activities, Watch
Week 13-15 ███████████████░░░░░░░░░  Social & Sharing Features
Week 16-18 ██████████████████░░░░░░  AR, 3D, Stats, Advanced Map
Week 19-21 █████████████████████░░░  Subscriptions, CarPlay, Siri
Week 22-24 ████████████████████████  Polish, Beta, Launch
```

---

## Phase 1: Foundation & MVP (Weeks 1–6)

### Week 1: Project Setup & Design System
**Goal**: Xcode project scaffold with architecture patterns and design tokens

| Task | Priority | Effort |
|------|----------|--------|
| Create Xcode project (iOS 17+, SwiftUI) | P0 | 2h |
| Set up folder structure per architecture spec | P0 | 2h |
| Configure Swift Package Manager dependencies | P0 | 1h |
| Build design system: `AppColors`, `AppTypography`, `AppSpacing` | P0 | 4h |
| Build reusable components: `StatusBadge`, `FlightNumberLabel`, `AirportCodeLabel`, `TimeDisplay` | P0 | 6h |
| Set up SwiftLint configuration | P1 | 1h |
| Set up SwiftData model container | P0 | 3h |
| Configure logging subsystem (`os_log` categories) | P1 | 1h |
| Set up tab bar navigation (Map, My Flights, Search, Stats, Settings) | P0 | 3h |
| Create app icon and launch screen | P1 | 2h |

**Deliverables**: Runnable app with tab navigation and design system

**Debug checkpoint**: App launches < 1s, all tabs render placeholder content

---

### Week 2: Networking Layer & API Integration
**Goal**: Working API client with all required endpoints

| Task | Priority | Effort |
|------|----------|--------|
| Build `APIClient` with async/await, error handling, retry logic | P0 | 6h |
| Define `APIEndpoints` for AviationStack | P0 | 2h |
| Build API response models (`FlightAPIResponse`, `AirportAPIResponse`, etc.) | P0 | 4h |
| Build domain models (`Flight`, `Airport`, `Airline`, `Aircraft`) | P0 | 4h |
| Build repository protocol + implementations (`FlightRepository`, `AirportRepository`) | P0 | 4h |
| Add OpenSky Network API for real-time positions | P0 | 3h |
| Build `NetworkMonitor` for connectivity detection | P1 | 2h |
| Add response caching (URLCache + custom disk cache) | P1 | 3h |
| Write unit tests for all API model parsing | P0 | 4h |
| Write unit tests for repository layer | P0 | 3h |

**Deliverables**: API client fetching real flight data, all models mapped, cached responses

**Debug checkpoint**: Unit tests pass for 20+ API response scenarios, network errors handled gracefully

---

### Week 3: Flight Map (Core Feature)
**Goal**: Interactive map with live aircraft positions

| Task | Priority | Effort |
|------|----------|--------|
| Implement `FlightMapView` with MapKit for SwiftUI | P0 | 6h |
| Build `FlightMapViewModel` with `@Observable` | P0 | 3h |
| Create custom `AircraftAnnotationView` (rotated airplane icon) | P0 | 4h |
| Implement aircraft clustering at low zoom | P1 | 4h |
| Add position interpolation/animation between API updates | P1 | 4h |
| Build `FlightPathOverlay` with `MapPolyline` | P0 | 3h |
| Add day/night terminator overlay | P2 | 3h |
| Implement bounding box position loading (load aircraft in visible area) | P0 | 3h |
| Tap annotation → present flight detail sheet | P0 | 2h |
| Build `MapFilterSheet` (basic airline/altitude filters) | P2 | 4h |
| Performance testing with 1000+ annotations | P0 | 2h |

**Deliverables**: Working interactive map with live aircraft, tap-to-detail, smooth animation

**Debug checkpoint**: Map renders < 2s, smooth scrolling with 500+ aircraft, memory < 100MB

---

### Week 4: Flight Detail Panel
**Goal**: Complete flight information screen

| Task | Priority | Effort |
|------|----------|--------|
| Build `FlightDetailView` with all sections | P0 | 8h |
| Build `FlightProgressBar` (animated, airplane icon at position) | P0 | 4h |
| Build `FlightTimelineView` (departure → gate → boarding → takeoff → cruise → landing → arrival) | P1 | 4h |
| Build `AircraftInfoCard` (type, registration, photo, age) | P1 | 3h |
| Implement live data section (speed, altitude, heading) | P0 | 2h |
| Build time display with scheduled vs actual with delay highlighting | P0 | 3h |
| Gate/terminal section with change detection | P0 | 2h |
| Aircraft photo loading (PlaneSpotters.net API or similar) | P2 | 3h |
| Pull-to-refresh implementation | P0 | 1h |
| Share button (basic share sheet) | P1 | 2h |
| `FlightDetailViewModel` with unit tests | P0 | 4h |

**Deliverables**: Complete flight detail screen with all data sections

**Debug checkpoint**: All timezone conversions correct, progress bar matches actual position, no layout issues on any iPhone size

---

### Week 5: Search & My Flights
**Goal**: Flight search and personal flight management

| Task | Priority | Effort |
|------|----------|--------|
| Build `SearchView` with tabbed interface (Flight / Route / Airport) | P0 | 4h |
| Implement flight number search with debounced autocomplete | P0 | 4h |
| Implement route search (origin → destination) | P0 | 3h |
| Implement airport search (name, IATA, ICAO) | P0 | 3h |
| Build `SearchResultsView` with flight/airport cards | P0 | 3h |
| Build `RecentSearchesView` with SwiftData persistence | P1 | 2h |
| Build `MyFlightsView` with upcoming/past sections | P0 | 4h |
| Build `FlightCardView` for flight list items | P0 | 3h |
| Build `AddFlightSheet` (flight number + date picker) | P0 | 3h |
| Implement swipe-to-delete with confirmation | P0 | 1h |
| `SearchViewModel` and `MyFlightsViewModel` with tests | P0 | 4h |

**Deliverables**: Working search across all types, personal flight list with CRUD

**Debug checkpoint**: Autocomplete responsive < 300ms, search covers all IATA/ICAO codes, flights persist across launches

---

### Week 6: Airport Info & Push Notifications
**Goal**: Airport detail pages and notification system

| Task | Priority | Effort |
|------|----------|--------|
| Build `AirportDetailView` with overview section | P0 | 4h |
| Build `DepartureBoardView` with live data table | P0 | 4h |
| Build `ArrivalBoardView` with live data table | P0 | 4h |
| Build `AirportWeatherView` with current conditions | P0 | 3h |
| Implement board filtering (airline, terminal, status) | P1 | 3h |
| Implement board auto-refresh (60s interval) | P0 | 1h |
| Set up APNs registration and token management | P0 | 3h |
| Implement background fetch for tracked flight updates | P0 | 4h |
| Build local notification system (fallback when server push unavailable) | P0 | 3h |
| Implement notification categories (delay, gate change, cancel, etc.) | P0 | 3h |
| Build `NotificationSettingsView` (per-flight alert preferences) | P1 | 2h |
| `AirportViewModel` with unit tests | P0 | 3h |

**Deliverables**: Airport screens with live boards, full notification system

**Debug checkpoint**: Boards refresh without scroll reset, notifications fire for all 8+ event types, background fetch reliable

---

### Phase 1 Milestone Review
- [ ] App runs on physical device (iPhone 15+)
- [ ] All 5 core features working end-to-end
- [ ] Unit test coverage ≥ 80% on domain + data layers
- [ ] No memory leaks (Instruments Allocations)
- [ ] No UI jank (Instruments Time Profiler)
- [ ] API rate limits respected
- [ ] Offline mode shows cached data gracefully

---

## Phase 2: Smart Features & Platform (Weeks 7–12)

### Week 7: Delay Prediction Engine
| Task | Priority | Effort |
|------|----------|--------|
| Build `DelayPredictionService` with multi-factor analysis | P0 | 8h |
| Implement inbound aircraft tracking ("Where's My Plane") | P0 | 6h |
| Integrate FAA SWIM data for ground stops/delays | P1 | 4h |
| Build historical on-time performance lookup | P1 | 4h |
| Create delay prediction UI (confidence bar, reason, factors) | P0 | 4h |
| Build prediction explanation view (why the delay is expected) | P0 | 3h |
| Unit tests for prediction logic | P0 | 4h |

### Week 8: Auto-Import & Sync
| Task | Priority | Effort |
|------|----------|--------|
| Build iOS Calendar import (EventKit) | P0 | 4h |
| Build email forwarding parser for booking confirmations | P1 | 8h |
| Implement TripIt API integration | P2 | 4h |
| Build CloudKit sync for My Flights across devices | P0 | 6h |
| Handle sync conflicts (last-write-wins with user prompt) | P1 | 3h |
| Unit tests for email parser (top 20 airline formats) | P0 | 4h |

### Week 9: iOS Widgets
| Task | Priority | Effort |
|------|----------|--------|
| Create widget extension target | P0 | 1h |
| Build small widget (next flight countdown + status) | P0 | 4h |
| Build medium widget (active flight progress + ETA) | P0 | 4h |
| Build large widget (upcoming flights list) | P1 | 4h |
| Build lock screen widgets (circular + rectangular) | P0 | 4h |
| Implement `TimelineProvider` with proper refresh schedule | P0 | 4h |
| Test widget previews for all families | P0 | 2h |
| Widget deep link → correct flight in app | P0 | 2h |

### Week 10: Live Activities & Dynamic Island
| Task | Priority | Effort |
|------|----------|--------|
| Create Live Activity extension target | P0 | 1h |
| Define `FlightActivityAttributes` model | P0 | 2h |
| Build compact/minimal Dynamic Island views | P0 | 4h |
| Build expanded Dynamic Island view | P0 | 3h |
| Build lock screen Live Activity view | P0 | 4h |
| Implement activity lifecycle (start on boarding, update in-flight, end on arrival) | P0 | 4h |
| Background push update integration | P0 | 4h |
| Test all states: pre-departure, boarding, in-flight, landing, arrived | P0 | 3h |

### Week 11: Apple Watch App
| Task | Priority | Effort |
|------|----------|--------|
| Create WatchOS target | P0 | 1h |
| Build main flight status view | P0 | 4h |
| Build boarding time complication | P0 | 3h |
| Build gate number complication | P0 | 2h |
| Build flight progress complication | P1 | 3h |
| Implement Watch Connectivity for phone ↔ watch sync | P0 | 4h |
| Build nearby aircraft list (using phone's API data) | P2 | 4h |

### Week 12: Smart Notifications
| Task | Priority | Effort |
|------|----------|--------|
| Build predictive delay alerts (fire before airline announces) | P0 | 6h |
| Build "Leave Now" alert (distance to airport + traffic estimation) | P1 | 4h |
| Build connection risk alerts for layover flights | P1 | 4h |
| Build airport congestion warnings | P2 | 3h |
| Notification A/B testing framework | P2 | 3h |
| Integration testing for all notification paths | P0 | 4h |

---

### Phase 2 Milestone Review
- [ ] Delay predictions fire ≥ 30 min before airline
- [ ] Widgets refresh reliably every 15 min
- [ ] Live Activities update in real-time during flights
- [ ] Watch app shows correct data synced from phone
- [ ] Calendar import works for iOS Calendar events
- [ ] Background battery usage < 5% per day

---

## Phase 3: Social & Advanced (Weeks 13–18)

### Week 13-14: Sharing & Friends
- Share flight as rich image card
- Share live tracking URL
- iMessage app extension
- Friends tracking with invite link
- Pickup countdown timer
- Friends alert forwarding

### Week 15-16: AR & 3D
- ARKit camera overlay for sky identification
- Overhead flight detection using GPS + API
- 3D terrain rendering (SceneKit)
- Aircraft 3D models with livery
- Cockpit perspective view
- Following camera mode

### Week 17-18: Stats & Advanced Map
- Travel statistics dashboard
- Flight history timeline
- World map with visited airports
- Year-in-review generator
- Advanced map filters (airline, type, altitude, speed)
- Weather layers (clouds, precipitation)
- ATC boundary overlay

---

## Phase 4: Polish & Launch (Weeks 19–24)

### Week 19-20: Subscriptions & Platform
- StoreKit 2 subscription integration
- Paywall UI at feature boundaries
- Free trial logic
- CarPlay dashboard integration
- Siri Shortcuts for flight status queries
- Spotlight indexing for flights and airports

### Week 21-22: Onboarding & Accessibility
- 3-screen onboarding flow
- Permission request flow (notifications, location)
- Full VoiceOver audit + fixes
- Dynamic Type at all 7 sizes
- Color-blind safe palette verification
- Reduced motion support

### Week 23-24: Beta & Launch
- Internal TestFlight build → team testing
- External TestFlight → beta testers (500+ users)
- Crash monitoring (Firebase Crashlytics)
- Performance profiling pass
- App Store screenshots (all device sizes)
- App Store description + keywords (ASO)
- App Store submission
- Launch day monitoring

---

## Risk Register

| Risk | Impact | Probability | Mitigation |
|------|--------|------------|------------|
| API rate limits exceeded | High | Medium | Aggressive caching, request batching, fallback to secondary API |
| API provider pricing changes | High | Low | Abstract behind repository pattern, easy to swap providers |
| Map performance with many aircraft | Medium | Medium | Clustering, viewport-only loading, annotation recycling |
| Push notification delivery unreliable | High | Low | Local notification fallback, background fetch redundancy |
| ML delay predictions inaccurate | Medium | Medium | Start with simple heuristics, iterate with real data, A/B test |
| App Store rejection | High | Low | Follow HIG strictly, review guidelines pre-submission |
| Memory issues with AR/3D | Medium | Medium | Lazy loading, resource cleanup on dismiss, memory warnings handling |
| CloudKit sync conflicts | Medium | Medium | Last-write-wins with user prompt for conflicts |

---

## Success Criteria for Launch

| Metric | Target |
|--------|--------|
| App Store rating | ≥ 4.5★ |
| Crash-free sessions | ≥ 99.5% |
| Cold start time | < 1.5s |
| Flight search → result | < 2s |
| Map initial load | < 3s |
| Push notification delivery | ≥ 98% |
| Widget refresh reliability | ≥ 95% |
| Accessibility audit | 100% VoiceOver coverage |
| Unit test coverage | ≥ 80% |
| Beta tester NPS | ≥ 60 |
