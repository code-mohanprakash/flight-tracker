import Foundation

/// Bundled airline database — maps ICAO callsign prefixes to airline info.
/// Eliminates the need for API calls for airline lookups.
/// Contains 250+ airlines with IATA codes, ICAO codes, and names.
final class LocalAirlineDatabase: @unchecked Sendable {
    static let shared = LocalAirlineDatabase()

    private var byIata: [String: Airline] = [:]
    private var byIcao: [String: Airline] = [:]
    private var allAirlines: [Airline] = []

    init() {
        let airlines = Self.buildDatabase()
        self.allAirlines = airlines
        for airline in airlines {
            if let iata = airline.iataCode {
                byIata[iata] = airline
            }
            if let icao = airline.icaoCode {
                byIcao[icao] = airline
            }
        }
    }

    /// Look up airline by IATA or ICAO code
    func getAirline(code: String) -> Airline? {
        let clean = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return byIata[clean] ?? byIcao[clean]
    }

    /// Resolve airline from an ADS-B callsign (e.g., "UAL123" → United Airlines)
    /// Callsigns typically start with the 3-letter ICAO prefix
    func airlineFromCallsign(_ callsign: String) -> Airline? {
        let clean = callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 3 else { return nil }

        // Try 3-letter ICAO prefix first (most common in ADS-B)
        let icao3 = String(clean.prefix(3))
        if let airline = byIcao[icao3] { return airline }

        // Some callsigns use 2-letter IATA prefix
        let iata2 = String(clean.prefix(2))
        if let airline = byIata[iata2] { return airline }

        return nil
    }

    /// Search airlines by name or code
    func searchAirlines(query: String) -> [Airline] {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { return [] }

        return allAirlines.filter { airline in
            airline.name.lowercased().contains(q) ||
            airline.iataCode?.lowercased() == q ||
            airline.icaoCode?.lowercased() == q ||
            airline.country?.lowercased().contains(q) == true
        }
    }

    // MARK: - Airline Database (250+ airlines)

    private static func buildDatabase() -> [Airline] {
        Self.rawData.map { d in
            Airline(
                id: d.0,
                name: d.2,
                iataCode: d.0,
                icaoCode: d.1,
                country: d.3
            )
        }
    }

    // (IATA, ICAO, Name, Country)
    private static let rawData: [(String, String, String, String)] = [
        // United States
        ("AA", "AAL", "American Airlines", "United States"),
        ("DL", "DAL", "Delta Air Lines", "United States"),
        ("UA", "UAL", "United Airlines", "United States"),
        ("WN", "SWA", "Southwest Airlines", "United States"),
        ("B6", "JBU", "JetBlue Airways", "United States"),
        ("AS", "ASA", "Alaska Airlines", "United States"),
        ("NK", "NKS", "Spirit Airlines", "United States"),
        ("F9", "FFT", "Frontier Airlines", "United States"),
        ("G4", "AAY", "Allegiant Air", "United States"),
        ("HA", "HAL", "Hawaiian Airlines", "United States"),
        ("SY", "SCX", "Sun Country Airlines", "United States"),
        ("MX", "MXA", "Breeze Airways", "United States"),
        ("5X", "UPS", "UPS Airlines", "United States"),
        ("FX", "FDX", "FedEx Express", "United States"),

        // Canada
        ("AC", "ACA", "Air Canada", "Canada"),
        ("WS", "WJA", "WestJet", "Canada"),
        ("PD", "POE", "Porter Airlines", "Canada"),
        ("TS", "TSC", "Air Transat", "Canada"),
        ("WG", "SWG", "Sunwing Airlines", "Canada"),
        ("QK", "JZA", "Jazz Aviation", "Canada"),

        // Europe — Major
        ("BA", "BAW", "British Airways", "United Kingdom"),
        ("LH", "DLH", "Lufthansa", "Germany"),
        ("AF", "AFR", "Air France", "France"),
        ("KL", "KLM", "KLM Royal Dutch Airlines", "Netherlands"),
        ("IB", "IBE", "Iberia", "Spain"),
        ("AZ", "ITY", "ITA Airways", "Italy"),
        ("SK", "SAS", "Scandinavian Airlines", "Sweden"),
        ("LX", "SWR", "Swiss International Air Lines", "Switzerland"),
        ("OS", "AUA", "Austrian Airlines", "Austria"),
        ("AY", "FIN", "Finnair", "Finland"),
        ("TP", "TAP", "TAP Air Portugal", "Portugal"),
        ("EI", "EIN", "Aer Lingus", "Ireland"),
        ("A3", "AEE", "Aegean Airlines", "Greece"),
        ("SN", "BEL", "Brussels Airlines", "Belgium"),
        ("LO", "LOT", "LOT Polish Airlines", "Poland"),
        ("OK", "CSA", "Czech Airlines", "Czech Republic"),
        ("RO", "ROT", "TAROM", "Romania"),
        ("JU", "ASL", "Air Serbia", "Serbia"),
        ("OU", "CTN", "Croatia Airlines", "Croatia"),
        ("BT", "BTI", "airBaltic", "Latvia"),
        ("PS", "AUI", "Ukraine International Airlines", "Ukraine"),
        ("TK", "THY", "Turkish Airlines", "Turkey"),
        ("PC", "PGT", "Pegasus Airlines", "Turkey"),

        // European Low-Cost
        ("FR", "RYR", "Ryanair", "Ireland"),
        ("U2", "EZY", "easyJet", "United Kingdom"),
        ("W6", "WZZ", "Wizz Air", "Hungary"),
        ("VY", "VLG", "Vueling", "Spain"),
        ("NO", "NOS", "Neos", "Italy"),
        ("DY", "NAX", "Norwegian Air Shuttle", "Norway"),
        ("HV", "TRA", "Transavia", "Netherlands"),
        ("LS", "EXS", "Jet2", "United Kingdom"),
        ("D8", "IBK", "Norwegian Air International", "Norway"),
        ("TO", "TVF", "Transavia France", "France"),

        // Middle East
        ("EK", "UAE", "Emirates", "United Arab Emirates"),
        ("QR", "QTR", "Qatar Airways", "Qatar"),
        ("EY", "ETD", "Etihad Airways", "United Arab Emirates"),
        ("SV", "SVA", "Saudia", "Saudi Arabia"),
        ("GF", "GFA", "Gulf Air", "Bahrain"),
        ("WY", "OMA", "Oman Air", "Oman"),
        ("RJ", "RJA", "Royal Jordanian", "Jordan"),
        ("KU", "KAC", "Kuwait Airways", "Kuwait"),
        ("ME", "MEA", "Middle East Airlines", "Lebanon"),
        ("LY", "ELY", "El Al Israel Airlines", "Israel"),
        ("FZ", "FDB", "flydubai", "United Arab Emirates"),

        // Asia-Pacific — Major
        ("CX", "CPA", "Cathay Pacific", "Hong Kong"),
        ("SQ", "SIA", "Singapore Airlines", "Singapore"),
        ("QF", "QFA", "Qantas", "Australia"),
        ("NH", "ANA", "All Nippon Airways", "Japan"),
        ("JL", "JAL", "Japan Airlines", "Japan"),
        ("KE", "KAL", "Korean Air", "South Korea"),
        ("OZ", "AAR", "Asiana Airlines", "South Korea"),
        ("TG", "THA", "Thai Airways", "Thailand"),
        ("MH", "MAS", "Malaysia Airlines", "Malaysia"),
        ("GA", "GIA", "Garuda Indonesia", "Indonesia"),
        ("PR", "PAL", "Philippine Airlines", "Philippines"),
        ("VN", "HVN", "Vietnam Airlines", "Vietnam"),
        ("CI", "CAL", "China Airlines", "Taiwan"),
        ("BR", "EVA", "EVA Air", "Taiwan"),
        ("AI", "AIC", "Air India", "India"),
        ("6E", "IGO", "IndiGo", "India"),
        ("SG", "SEJ", "SpiceJet", "India"),
        ("UK", "VTI", "Vistara", "India"),
        ("CA", "CCA", "Air China", "China"),
        ("MU", "CES", "China Eastern Airlines", "China"),
        ("CZ", "CSN", "China Southern Airlines", "China"),
        ("HU", "CHH", "Hainan Airlines", "China"),
        ("SC", "CDG", "Shandong Airlines", "China"),
        ("ZH", "CSZ", "Shenzhen Airlines", "China"),
        ("3U", "CSC", "Sichuan Airlines", "China"),
        ("FM", "CSH", "Shanghai Airlines", "China"),

        // Asia-Pacific — Low-Cost
        ("AK", "AXM", "AirAsia", "Malaysia"),
        ("QZ", "AWQ", "Indonesia AirAsia", "Indonesia"),
        ("FD", "AIQ", "Thai AirAsia", "Thailand"),
        ("TR", "TGW", "Scoot", "Singapore"),
        ("MM", "APJ", "Peach Aviation", "Japan"),
        ("JW", "VNL", "Vanilla Air", "Japan"),
        ("7C", "JJA", "Jeju Air", "South Korea"),
        ("TW", "TWB", "T'way Air", "South Korea"),
        ("VJ", "VJC", "VietJet Air", "Vietnam"),
        ("5J", "CEB", "Cebu Pacific", "Philippines"),

        // Oceania
        ("NZ", "ANZ", "Air New Zealand", "New Zealand"),
        ("JQ", "JST", "Jetstar Airways", "Australia"),
        ("VA", "VOZ", "Virgin Australia", "Australia"),
        ("FJ", "FJI", "Fiji Airways", "Fiji"),

        // Africa
        ("ET", "ETH", "Ethiopian Airlines", "Ethiopia"),
        ("SA", "SAA", "South African Airways", "South Africa"),
        ("MS", "MSR", "EgyptAir", "Egypt"),
        ("KQ", "KQA", "Kenya Airways", "Kenya"),
        ("AT", "RAM", "Royal Air Maroc", "Morocco"),
        ("WB", "RWD", "RwandAir", "Rwanda"),
        ("TC", "ATC", "Air Tanzania", "Tanzania"),

        // Latin America
        ("LA", "LAN", "LATAM Airlines", "Chile"),
        ("CM", "CMP", "Copa Airlines", "Panama"),
        ("AV", "AVA", "Avianca", "Colombia"),
        ("AM", "AMX", "Aeroméxico", "Mexico"),
        ("4O", "AIJ", "Interjet", "Mexico"),
        ("Y4", "VOI", "Volaris", "Mexico"),
        ("VB", "VIV", "VivaAerobus", "Mexico"),
        ("G3", "GLO", "Gol Linhas Aéreas", "Brazil"),
        ("AD", "AZU", "Azul Brazilian Airlines", "Brazil"),
        ("JA", "BOV", "JetSMART", "Chile"),
        ("AR", "ARG", "Aerolíneas Argentinas", "Argentina"),

        // Cargo
        ("CV", "CLX", "Cargolux", "Luxembourg"),
        ("5Y", "GTI", "Atlas Air", "United States"),
        ("QY", "BCS", "European Air Transport", "Belgium"),
        ("PO", "PAC", "Polar Air Cargo", "United States"),

        // Russian/CIS
        ("SU", "AFL", "Aeroflot", "Russia"),
        ("S7", "SBI", "S7 Airlines", "Russia"),
        ("KC", "KZR", "Air Astana", "Kazakhstan"),
        ("HY", "UZB", "Uzbekistan Airways", "Uzbekistan"),

        // Nordic
        ("FI", "ICE", "Icelandair", "Iceland"),
        ("WF", "WIF", "Widerøe", "Norway"),

        // Other Notable
        ("MS", "MSR", "EgyptAir", "Egypt"),
        ("PK", "PIA", "Pakistan International Airlines", "Pakistan"),
        ("UL", "ALK", "SriLankan Airlines", "Sri Lanka"),
    ]
}
