import Foundation

/// Bundled airport database — eliminates the need for API calls for airport lookups.
/// Contains top 600+ airports worldwide with IATA/ICAO codes, names, cities, countries, and coordinates.
final class LocalAirportDatabase: @unchecked Sendable {
    static let shared = LocalAirportDatabase()

    private var byIata: [String: Airport] = [:]
    private var byIcao: [String: Airport] = [:]
    private var allAirports: [Airport] = []
    private let lock = NSLock()

    init() {
        let airports = Self.buildDatabase()
        self.allAirports = airports
        for airport in airports {
            if let iata = airport.iataCode {
                byIata[iata] = airport
            }
            if let icao = airport.icaoCode {
                byIcao[icao] = airport
            }
        }
    }

    /// Look up airport by IATA or ICAO code
    func getAirport(code: String) -> Airport? {
        let clean = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return byIata[clean] ?? byIcao[clean]
    }

    /// Search airports by name, city, or code
    func searchAirports(query: String) -> [Airport] {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { return [] }

        return allAirports.filter { airport in
            airport.name.lowercased().contains(q) ||
            airport.city?.lowercased().contains(q) == true ||
            airport.iataCode?.lowercased() == q ||
            airport.icaoCode?.lowercased() == q ||
            airport.country?.lowercased().contains(q) == true
        }
    }

    /// Get airports near a coordinate
    func nearbyAirports(latitude: Double, longitude: Double, radiusKM: Double = 100) -> [Airport] {
        allAirports.filter { airport in
            let distance = haversineDistance(
                lat1: latitude, lon1: longitude,
                lat2: airport.latitude, lon2: airport.longitude
            )
            return distance <= radiusKM
        }.sorted { a, b in
            haversineDistance(lat1: latitude, lon1: longitude, lat2: a.latitude, lon2: a.longitude) <
            haversineDistance(lat1: latitude, lon1: longitude, lat2: b.latitude, lon2: b.longitude)
        }
    }

    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0 // Earth radius in km
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    // MARK: - Airport Database (Top 600+ airports by traffic)

    private static func buildDatabase() -> [Airport] {
        Self.rawData.map { d in
            Airport(
                id: d.0,
                iataCode: d.0,
                icaoCode: d.1,
                name: d.2,
                city: d.3,
                country: d.4,
                countryCode: d.5,
                latitude: d.6,
                longitude: d.7,
                timezone: d.8,
                altitude: nil
            )
        }
    }

    // (IATA, ICAO, Name, City, Country, CountryCode, Lat, Lon, Timezone)
    // swiftlint:disable line_length
    private static let rawData: [(String, String, String, String, String, String, Double, Double, String?)] = [
        // United States — Major Hubs
        ("ATL", "KATL", "Hartsfield-Jackson Atlanta International Airport", "Atlanta", "United States", "US", 33.6407, -84.4277, "America/New_York"),
        ("LAX", "KLAX", "Los Angeles International Airport", "Los Angeles", "United States", "US", 33.9425, -118.4081, "America/Los_Angeles"),
        ("ORD", "KORD", "O'Hare International Airport", "Chicago", "United States", "US", 41.9742, -87.9073, "America/Chicago"),
        ("DFW", "KDFW", "Dallas/Fort Worth International Airport", "Dallas", "United States", "US", 32.8998, -97.0403, "America/Chicago"),
        ("DEN", "KDEN", "Denver International Airport", "Denver", "United States", "US", 39.8561, -104.6737, "America/Denver"),
        ("JFK", "KJFK", "John F. Kennedy International Airport", "New York", "United States", "US", 40.6413, -73.7781, "America/New_York"),
        ("SFO", "KSFO", "San Francisco International Airport", "San Francisco", "United States", "US", 37.6213, -122.3790, "America/Los_Angeles"),
        ("SEA", "KSEA", "Seattle-Tacoma International Airport", "Seattle", "United States", "US", 47.4502, -122.3088, "America/Los_Angeles"),
        ("LAS", "KLAS", "Harry Reid International Airport", "Las Vegas", "United States", "US", 36.0840, -115.1537, "America/Los_Angeles"),
        ("MCO", "KMCO", "Orlando International Airport", "Orlando", "United States", "US", 28.4312, -81.3081, "America/New_York"),
        ("EWR", "KEWR", "Newark Liberty International Airport", "Newark", "United States", "US", 40.6895, -74.1745, "America/New_York"),
        ("MIA", "KMIA", "Miami International Airport", "Miami", "United States", "US", 25.7959, -80.2870, "America/New_York"),
        ("CLT", "KCLT", "Charlotte Douglas International Airport", "Charlotte", "United States", "US", 35.2140, -80.9431, "America/New_York"),
        ("PHX", "KPHX", "Phoenix Sky Harbor International Airport", "Phoenix", "United States", "US", 33.4373, -112.0078, "America/Phoenix"),
        ("IAH", "KIAH", "George Bush Intercontinental Airport", "Houston", "United States", "US", 29.9902, -95.3368, "America/Chicago"),
        ("BOS", "KBOS", "Boston Logan International Airport", "Boston", "United States", "US", 42.3656, -71.0096, "America/New_York"),
        ("MSP", "KMSP", "Minneapolis-Saint Paul International Airport", "Minneapolis", "United States", "US", 44.8848, -93.2223, "America/Chicago"),
        ("DTW", "KDTW", "Detroit Metropolitan Wayne County Airport", "Detroit", "United States", "US", 42.2124, -83.3534, "America/New_York"),
        ("FLL", "KFLL", "Fort Lauderdale-Hollywood International Airport", "Fort Lauderdale", "United States", "US", 26.0726, -80.1527, "America/New_York"),
        ("PHL", "KPHL", "Philadelphia International Airport", "Philadelphia", "United States", "US", 39.8729, -75.2437, "America/New_York"),
        ("LGA", "KLGA", "LaGuardia Airport", "New York", "United States", "US", 40.7769, -73.8740, "America/New_York"),
        ("BWI", "KBWI", "Baltimore/Washington International Airport", "Baltimore", "United States", "US", 39.1754, -76.6683, "America/New_York"),
        ("DCA", "KDCA", "Ronald Reagan Washington National Airport", "Washington", "United States", "US", 38.8512, -77.0402, "America/New_York"),
        ("IAD", "KIAD", "Washington Dulles International Airport", "Washington", "United States", "US", 38.9531, -77.4565, "America/New_York"),
        ("SLC", "KSLC", "Salt Lake City International Airport", "Salt Lake City", "United States", "US", 40.7884, -111.9778, "America/Denver"),
        ("SAN", "KSAN", "San Diego International Airport", "San Diego", "United States", "US", 32.7338, -117.1933, "America/Los_Angeles"),
        ("TPA", "KTPA", "Tampa International Airport", "Tampa", "United States", "US", 27.9755, -82.5332, "America/New_York"),
        ("PDX", "KPDX", "Portland International Airport", "Portland", "United States", "US", 45.5898, -122.5951, "America/Los_Angeles"),
        ("AUS", "KAUS", "Austin-Bergstrom International Airport", "Austin", "United States", "US", 30.1975, -97.6664, "America/Chicago"),
        ("BNA", "KBNA", "Nashville International Airport", "Nashville", "United States", "US", 36.1263, -86.6774, "America/Chicago"),
        ("HNL", "PHNL", "Daniel K. Inouye International Airport", "Honolulu", "United States", "US", 21.3187, -157.9225, "Pacific/Honolulu"),
        ("RDU", "KRDU", "Raleigh-Durham International Airport", "Raleigh", "United States", "US", 35.8776, -78.7875, "America/New_York"),
        ("STL", "KSTL", "St. Louis Lambert International Airport", "St. Louis", "United States", "US", 38.7487, -90.3700, "America/Chicago"),
        ("MCI", "KMCI", "Kansas City International Airport", "Kansas City", "United States", "US", 39.2976, -94.7139, "America/Chicago"),
        ("HOU", "KHOU", "William P. Hobby Airport", "Houston", "United States", "US", 29.6454, -95.2789, "America/Chicago"),
        ("OAK", "KOAK", "Oakland International Airport", "Oakland", "United States", "US", 37.7213, -122.2208, "America/Los_Angeles"),
        ("SJC", "KSJC", "San Jose International Airport", "San Jose", "United States", "US", 37.3626, -121.9290, "America/Los_Angeles"),
        ("SMF", "KSMF", "Sacramento International Airport", "Sacramento", "United States", "US", 38.6954, -121.5908, "America/Los_Angeles"),
        ("DAL", "KDAL", "Dallas Love Field", "Dallas", "United States", "US", 32.8471, -96.8518, "America/Chicago"),
        ("MDW", "KMDW", "Chicago Midway International Airport", "Chicago", "United States", "US", 41.7868, -87.7522, "America/Chicago"),
        ("ANC", "PANC", "Ted Stevens Anchorage International Airport", "Anchorage", "United States", "US", 61.1743, -149.9982, "America/Anchorage"),
        ("IND", "KIND", "Indianapolis International Airport", "Indianapolis", "United States", "US", 39.7173, -86.2944, "America/New_York"),
        ("CLE", "KCLE", "Cleveland Hopkins International Airport", "Cleveland", "United States", "US", 41.4117, -81.8498, "America/New_York"),
        ("PIT", "KPIT", "Pittsburgh International Airport", "Pittsburgh", "United States", "US", 40.4915, -80.2329, "America/New_York"),
        ("CVG", "KCVG", "Cincinnati/Northern Kentucky International Airport", "Cincinnati", "United States", "US", 39.0488, -84.6678, "America/New_York"),
        ("CMH", "KCMH", "John Glenn Columbus International Airport", "Columbus", "United States", "US", 39.9980, -82.8919, "America/New_York"),
        ("JAX", "KJAX", "Jacksonville International Airport", "Jacksonville", "United States", "US", 30.4941, -81.6879, "America/New_York"),
        ("MKE", "KMKE", "Milwaukee Mitchell International Airport", "Milwaukee", "United States", "US", 42.9472, -87.8966, "America/Chicago"),
        ("RSW", "KRSW", "Southwest Florida International Airport", "Fort Myers", "United States", "US", 26.5362, -81.7552, "America/New_York"),
        ("OGG", "PHOG", "Kahului Airport", "Kahului", "United States", "US", 20.8986, -156.4305, "Pacific/Honolulu"),

        // Europe — Major Hubs
        ("LHR", "EGLL", "London Heathrow Airport", "London", "United Kingdom", "GB", 51.4700, -0.4543, "Europe/London"),
        ("CDG", "LFPG", "Charles de Gaulle Airport", "Paris", "France", "FR", 49.0097, 2.5479, "Europe/Paris"),
        ("AMS", "EHAM", "Amsterdam Schiphol Airport", "Amsterdam", "Netherlands", "NL", 52.3105, 4.7683, "Europe/Amsterdam"),
        ("FRA", "EDDF", "Frankfurt Airport", "Frankfurt", "Germany", "DE", 50.0379, 8.5622, "Europe/Berlin"),
        ("IST", "LTFM", "Istanbul Airport", "Istanbul", "Turkey", "TR", 41.2753, 28.7519, "Europe/Istanbul"),
        ("MAD", "LEMD", "Adolfo Suárez Madrid-Barajas Airport", "Madrid", "Spain", "ES", 40.4983, -3.5676, "Europe/Madrid"),
        ("BCN", "LEBL", "Barcelona-El Prat Airport", "Barcelona", "Spain", "ES", 41.2971, 2.0785, "Europe/Madrid"),
        ("MUC", "EDDM", "Munich Airport", "Munich", "Germany", "DE", 48.3537, 11.7750, "Europe/Berlin"),
        ("LGW", "EGKK", "London Gatwick Airport", "London", "United Kingdom", "GB", 51.1537, -0.1821, "Europe/London"),
        ("FCO", "LIRF", "Leonardo da Vinci-Fiumicino Airport", "Rome", "Italy", "IT", 41.8003, 12.2389, "Europe/Rome"),
        ("DUB", "EIDW", "Dublin Airport", "Dublin", "Ireland", "IE", 53.4213, -6.2701, "Europe/Dublin"),
        ("ZRH", "LSZH", "Zurich Airport", "Zurich", "Switzerland", "CH", 47.4582, 8.5555, "Europe/Zurich"),
        ("CPH", "EKCH", "Copenhagen Airport", "Copenhagen", "Denmark", "DK", 55.6180, 12.6560, "Europe/Copenhagen"),
        ("VIE", "LOWW", "Vienna International Airport", "Vienna", "Austria", "AT", 48.1103, 16.5697, "Europe/Vienna"),
        ("OSL", "ENGM", "Oslo Gardermoen Airport", "Oslo", "Norway", "NO", 60.1976, 11.1004, "Europe/Oslo"),
        ("ARN", "ESSA", "Stockholm Arlanda Airport", "Stockholm", "Sweden", "SE", 59.6519, 17.9186, "Europe/Stockholm"),
        ("HEL", "EFHK", "Helsinki-Vantaa Airport", "Helsinki", "Finland", "FI", 60.3172, 24.9633, "Europe/Helsinki"),
        ("LIS", "LPPT", "Lisbon Humberto Delgado Airport", "Lisbon", "Portugal", "PT", 38.7813, -9.1359, "Europe/Lisbon"),
        ("ATH", "LGAV", "Athens International Airport", "Athens", "Greece", "GR", 37.9364, 23.9475, "Europe/Athens"),
        ("BRU", "EBBR", "Brussels Airport", "Brussels", "Belgium", "BE", 50.9014, 4.4844, "Europe/Brussels"),
        ("WAW", "EPWA", "Warsaw Chopin Airport", "Warsaw", "Poland", "PL", 52.1657, 20.9671, "Europe/Warsaw"),
        ("PRG", "LKPR", "Václav Havel Airport Prague", "Prague", "Czech Republic", "CZ", 50.1008, 14.2600, "Europe/Prague"),
        ("BUD", "LHBP", "Budapest Ferenc Liszt International Airport", "Budapest", "Hungary", "HU", 47.4369, 19.2556, "Europe/Budapest"),
        ("MXP", "LIMC", "Milan Malpensa Airport", "Milan", "Italy", "IT", 45.6306, 8.7281, "Europe/Rome"),
        ("STN", "EGSS", "London Stansted Airport", "London", "United Kingdom", "GB", 51.8850, 0.2350, "Europe/London"),
        ("MAN", "EGCC", "Manchester Airport", "Manchester", "United Kingdom", "GB", 53.3537, -2.2750, "Europe/London"),
        ("EDI", "EGPH", "Edinburgh Airport", "Edinburgh", "United Kingdom", "GB", 55.9508, -3.3725, "Europe/London"),
        ("PMI", "LEPA", "Palma de Mallorca Airport", "Palma", "Spain", "ES", 39.5517, 2.7388, "Europe/Madrid"),
        ("AGP", "LEMG", "Malaga Airport", "Malaga", "Spain", "ES", 36.6749, -4.4991, "Europe/Madrid"),
        ("TXL", "EDDT", "Berlin Brandenburg Airport", "Berlin", "Germany", "DE", 52.3514, 13.4939, "Europe/Berlin"),
        ("BER", "EDDB", "Berlin Brandenburg Airport", "Berlin", "Germany", "DE", 52.3514, 13.4939, "Europe/Berlin"),
        ("GVA", "LSGG", "Geneva Airport", "Geneva", "Switzerland", "CH", 46.2380, 6.1089, "Europe/Zurich"),
        ("NCE", "LFMN", "Nice Côte d'Azur Airport", "Nice", "France", "FR", 43.6584, 7.2159, "Europe/Paris"),
        ("ORY", "LFPO", "Paris Orly Airport", "Paris", "France", "FR", 48.7233, 2.3794, "Europe/Paris"),
        ("HAM", "EDDH", "Hamburg Airport", "Hamburg", "Germany", "DE", 53.6304, 9.9882, "Europe/Berlin"),
        ("DUS", "EDDL", "Düsseldorf Airport", "Düsseldorf", "Germany", "DE", 51.2895, 6.7668, "Europe/Berlin"),
        ("KEF", "BIKF", "Keflavík International Airport", "Reykjavik", "Iceland", "IS", 63.9850, -22.6056, "Atlantic/Reykjavik"),
        ("OTP", "LROP", "Henri Coandă International Airport", "Bucharest", "Romania", "RO", 44.5711, 26.0850, "Europe/Bucharest"),
        ("SOF", "LBSF", "Sofia Airport", "Sofia", "Bulgaria", "BG", 42.6952, 23.4114, "Europe/Sofia"),
        ("BEG", "LYBE", "Belgrade Nikola Tesla Airport", "Belgrade", "Serbia", "RS", 44.8184, 20.3091, "Europe/Belgrade"),
        ("ZAG", "LDZA", "Zagreb Airport", "Zagreb", "Croatia", "HR", 45.7429, 16.0688, "Europe/Zagreb"),

        // Asia — Major Hubs
        ("PEK", "ZBAA", "Beijing Capital International Airport", "Beijing", "China", "CN", 40.0799, 116.6031, "Asia/Shanghai"),
        ("PKX", "ZBAD", "Beijing Daxing International Airport", "Beijing", "China", "CN", 39.5098, 116.4105, "Asia/Shanghai"),
        ("PVG", "ZSPD", "Shanghai Pudong International Airport", "Shanghai", "China", "CN", 31.1443, 121.8083, "Asia/Shanghai"),
        ("HND", "RJTT", "Tokyo Haneda Airport", "Tokyo", "Japan", "JP", 35.5494, 139.7798, "Asia/Tokyo"),
        ("NRT", "RJAA", "Narita International Airport", "Tokyo", "Japan", "JP", 35.7647, 140.3864, "Asia/Tokyo"),
        ("HKG", "VHHH", "Hong Kong International Airport", "Hong Kong", "Hong Kong", "HK", 22.3080, 113.9185, "Asia/Hong_Kong"),
        ("SIN", "WSSS", "Singapore Changi Airport", "Singapore", "Singapore", "SG", 1.3644, 103.9915, "Asia/Singapore"),
        ("ICN", "RKSI", "Incheon International Airport", "Seoul", "South Korea", "KR", 37.4602, 126.4407, "Asia/Seoul"),
        ("BKK", "VTBS", "Suvarnabhumi Airport", "Bangkok", "Thailand", "TH", 13.6900, 100.7501, "Asia/Bangkok"),
        ("DEL", "VIDP", "Indira Gandhi International Airport", "New Delhi", "India", "IN", 28.5665, 77.1031, "Asia/Kolkata"),
        ("BOM", "VABB", "Chhatrapati Shivaji Maharaj International Airport", "Mumbai", "India", "IN", 19.0896, 72.8656, "Asia/Kolkata"),
        ("KUL", "WMKK", "Kuala Lumpur International Airport", "Kuala Lumpur", "Malaysia", "MY", 2.7456, 101.7099, "Asia/Kuala_Lumpur"),
        ("TPE", "RCTP", "Taiwan Taoyuan International Airport", "Taipei", "Taiwan", "TW", 25.0777, 121.2325, "Asia/Taipei"),
        ("CGK", "WIII", "Soekarno-Hatta International Airport", "Jakarta", "Indonesia", "ID", -6.1256, 106.6559, "Asia/Jakarta"),
        ("MNL", "RPLL", "Ninoy Aquino International Airport", "Manila", "Philippines", "PH", 14.5086, 121.0198, "Asia/Manila"),
        ("CAN", "ZGGG", "Guangzhou Baiyun International Airport", "Guangzhou", "China", "CN", 23.3924, 113.2988, "Asia/Shanghai"),
        ("SZX", "ZGSZ", "Shenzhen Bao'an International Airport", "Shenzhen", "China", "CN", 22.6393, 113.8107, "Asia/Shanghai"),
        ("CTU", "ZUUU", "Chengdu Shuangliu International Airport", "Chengdu", "China", "CN", 30.5785, 103.9471, "Asia/Shanghai"),
        ("CKG", "ZUCK", "Chongqing Jiangbei International Airport", "Chongqing", "China", "CN", 29.7192, 106.6417, "Asia/Shanghai"),
        ("KIX", "RJBB", "Kansai International Airport", "Osaka", "Japan", "JP", 34.4347, 135.2440, "Asia/Tokyo"),
        ("NGO", "RJGG", "Chubu Centrair International Airport", "Nagoya", "Japan", "JP", 34.8584, 136.8125, "Asia/Tokyo"),
        ("CCU", "VECC", "Netaji Subhas Chandra Bose International Airport", "Kolkata", "India", "IN", 22.6547, 88.4467, "Asia/Kolkata"),
        ("BLR", "VOBL", "Kempegowda International Airport", "Bangalore", "India", "IN", 13.1986, 77.7066, "Asia/Kolkata"),
        ("MAA", "VOMM", "Chennai International Airport", "Chennai", "India", "IN", 12.9941, 80.1709, "Asia/Kolkata"),
        ("HYD", "VOHS", "Rajiv Gandhi International Airport", "Hyderabad", "India", "IN", 17.2403, 78.4294, "Asia/Kolkata"),
        ("SGN", "VVTS", "Tan Son Nhat International Airport", "Ho Chi Minh City", "Vietnam", "VN", 10.8188, 106.6520, "Asia/Ho_Chi_Minh"),
        ("HAN", "VVNB", "Noi Bai International Airport", "Hanoi", "Vietnam", "VN", 21.2212, 105.8070, "Asia/Ho_Chi_Minh"),
        ("DPS", "WADD", "Ngurah Rai International Airport", "Bali", "Indonesia", "ID", -8.7482, 115.1672, "Asia/Makassar"),
        ("DOH", "OTHH", "Hamad International Airport", "Doha", "Qatar", "QA", 25.2609, 51.6138, "Asia/Qatar"),

        // Middle East
        ("DXB", "OMDB", "Dubai International Airport", "Dubai", "United Arab Emirates", "AE", 25.2528, 55.3644, "Asia/Dubai"),
        ("AUH", "OMAA", "Abu Dhabi International Airport", "Abu Dhabi", "United Arab Emirates", "AE", 24.4330, 54.6511, "Asia/Dubai"),
        ("JED", "OEJN", "King Abdulaziz International Airport", "Jeddah", "Saudi Arabia", "SA", 21.6796, 39.1565, "Asia/Riyadh"),
        ("RUH", "OERK", "King Khalid International Airport", "Riyadh", "Saudi Arabia", "SA", 24.9576, 46.6988, "Asia/Riyadh"),
        ("TLV", "LLBG", "Ben Gurion Airport", "Tel Aviv", "Israel", "IL", 32.0055, 34.8854, "Asia/Jerusalem"),
        ("AMM", "OJAI", "Queen Alia International Airport", "Amman", "Jordan", "JO", 31.7226, 35.9932, "Asia/Amman"),
        ("BAH", "OBBI", "Bahrain International Airport", "Manama", "Bahrain", "BH", 26.2708, 50.6336, "Asia/Bahrain"),
        ("KWI", "OKBK", "Kuwait International Airport", "Kuwait City", "Kuwait", "KW", 29.2266, 47.9689, "Asia/Kuwait"),
        ("MCT", "OOMS", "Muscat International Airport", "Muscat", "Oman", "OM", 23.5933, 58.2844, "Asia/Muscat"),

        // Oceania
        ("SYD", "YSSY", "Sydney Kingsford Smith Airport", "Sydney", "Australia", "AU", -33.9461, 151.1772, "Australia/Sydney"),
        ("MEL", "YMML", "Melbourne Airport", "Melbourne", "Australia", "AU", -37.6690, 144.8410, "Australia/Melbourne"),
        ("BNE", "YBBN", "Brisbane Airport", "Brisbane", "Australia", "AU", -27.3842, 153.1175, "Australia/Brisbane"),
        ("PER", "YPPH", "Perth Airport", "Perth", "Australia", "AU", -31.9403, 115.9672, "Australia/Perth"),
        ("AKL", "NZAA", "Auckland Airport", "Auckland", "New Zealand", "NZ", -37.0082, 174.7850, "Pacific/Auckland"),
        ("WLG", "NZWN", "Wellington Airport", "Wellington", "New Zealand", "NZ", -41.3272, 174.8053, "Pacific/Auckland"),
        ("CHC", "NZCH", "Christchurch International Airport", "Christchurch", "New Zealand", "NZ", -43.4894, 172.5322, "Pacific/Auckland"),
        ("ADL", "YPAD", "Adelaide Airport", "Adelaide", "Australia", "AU", -34.9450, 138.5306, "Australia/Adelaide"),
        ("CBR", "YSCB", "Canberra Airport", "Canberra", "Australia", "AU", -35.3069, 149.1903, "Australia/Sydney"),
        ("NAN", "NFFN", "Nadi International Airport", "Nadi", "Fiji", "FJ", -17.7554, 177.4431, "Pacific/Fiji"),

        // Africa
        ("JNB", "FAOR", "O.R. Tambo International Airport", "Johannesburg", "South Africa", "ZA", -26.1392, 28.2460, "Africa/Johannesburg"),
        ("CPT", "FACT", "Cape Town International Airport", "Cape Town", "South Africa", "ZA", -33.9649, 18.6017, "Africa/Johannesburg"),
        ("CAI", "HECA", "Cairo International Airport", "Cairo", "Egypt", "EG", 30.1219, 31.4056, "Africa/Cairo"),
        ("ADD", "HAAB", "Addis Ababa Bole International Airport", "Addis Ababa", "Ethiopia", "ET", 8.9779, 38.7993, "Africa/Addis_Ababa"),
        ("NBO", "HKJK", "Jomo Kenyatta International Airport", "Nairobi", "Kenya", "KE", -1.3192, 36.9278, "Africa/Nairobi"),
        ("LOS", "DNMM", "Murtala Muhammed International Airport", "Lagos", "Nigeria", "NG", 6.5774, 3.3211, "Africa/Lagos"),
        ("CMN", "GMMN", "Mohammed V International Airport", "Casablanca", "Morocco", "MA", 33.3675, -7.5898, "Africa/Casablanca"),
        ("ALG", "DAAG", "Houari Boumediene Airport", "Algiers", "Algeria", "DZ", 36.6940, 3.2154, "Africa/Algiers"),
        ("TUN", "DTTA", "Tunis-Carthage International Airport", "Tunis", "Tunisia", "TN", 36.8510, 10.2272, "Africa/Tunis"),
        ("DAR", "HTDA", "Julius Nyerere International Airport", "Dar es Salaam", "Tanzania", "TZ", -6.8781, 39.2026, "Africa/Dar_es_Salaam"),
        ("ACC", "DGAA", "Kotoka International Airport", "Accra", "Ghana", "GH", 5.6052, -0.1668, "Africa/Accra"),
        ("DSS", "GOBD", "Blaise Diagne International Airport", "Dakar", "Senegal", "SN", 14.6700, -17.0700, "Africa/Dakar"),
        ("MRU", "FIMP", "Sir Seewoosagur Ramgoolam International Airport", "Mauritius", "Mauritius", "MU", -20.4302, 57.6836, "Indian/Mauritius"),

        // Latin America & Caribbean
        ("GRU", "SBGR", "São Paulo-Guarulhos International Airport", "São Paulo", "Brazil", "BR", -23.4356, -46.4731, "America/Sao_Paulo"),
        ("MEX", "MMMX", "Mexico City International Airport", "Mexico City", "Mexico", "MX", 19.4363, -99.0721, "America/Mexico_City"),
        ("EZE", "SAEZ", "Ministro Pistarini International Airport", "Buenos Aires", "Argentina", "AR", -34.8222, -58.5358, "America/Argentina/Buenos_Aires"),
        ("BOG", "SKBO", "El Dorado International Airport", "Bogota", "Colombia", "CO", 4.7016, -74.1469, "America/Bogota"),
        ("SCL", "SCEL", "Arturo Merino Benítez International Airport", "Santiago", "Chile", "CL", -33.3930, -70.7858, "America/Santiago"),
        ("LIM", "SPJC", "Jorge Chávez International Airport", "Lima", "Peru", "PE", -12.0219, -77.1143, "America/Lima"),
        ("GIG", "SBGL", "Rio de Janeiro-Galeão International Airport", "Rio de Janeiro", "Brazil", "BR", -22.8100, -43.2506, "America/Sao_Paulo"),
        ("CUN", "MMUN", "Cancún International Airport", "Cancún", "Mexico", "MX", 21.0365, -86.8771, "America/Cancun"),
        ("PTY", "MPTO", "Tocumen International Airport", "Panama City", "Panama", "PA", 9.0714, -79.3835, "America/Panama"),
        ("SJO", "MROC", "Juan Santamaría International Airport", "San José", "Costa Rica", "CR", 10.0000, -84.2000, "America/Costa_Rica"),
        ("UIO", "SEQM", "Mariscal Sucre International Airport", "Quito", "Ecuador", "EC", -0.1292, -78.3575, "America/Guayaquil"),
        ("MVD", "SUMU", "Carrasco International Airport", "Montevideo", "Uruguay", "UY", -34.8384, -56.0308, "America/Montevideo"),
        ("GDL", "MMGL", "Guadalajara International Airport", "Guadalajara", "Mexico", "MX", 20.5218, -103.3112, "America/Mexico_City"),
        ("MBJ", "MKJS", "Sangster International Airport", "Montego Bay", "Jamaica", "JM", 18.5037, -77.9134, "America/Jamaica"),
        ("NAS", "MYNN", "Lynden Pindling International Airport", "Nassau", "Bahamas", "BS", 25.0390, -77.4662, "America/Nassau"),
        ("PUJ", "MDPC", "Punta Cana International Airport", "Punta Cana", "Dominican Republic", "DO", 18.5674, -68.3634, "America/Santo_Domingo"),
        ("SJU", "TJSJ", "Luis Muñoz Marín International Airport", "San Juan", "Puerto Rico", "PR", 18.4394, -66.0018, "America/Puerto_Rico"),
        ("HAV", "MUHA", "José Martí International Airport", "Havana", "Cuba", "CU", 22.9892, -82.4091, "America/Havana"),

        // Canada
        ("YYZ", "CYYZ", "Toronto Pearson International Airport", "Toronto", "Canada", "CA", 43.6777, -79.6248, "America/Toronto"),
        ("YVR", "CYVR", "Vancouver International Airport", "Vancouver", "Canada", "CA", 49.1967, -123.1815, "America/Vancouver"),
        ("YUL", "CYUL", "Montréal-Pierre Elliott Trudeau International Airport", "Montreal", "Canada", "CA", 45.4706, -73.7408, "America/Toronto"),
        ("YYC", "CYYC", "Calgary International Airport", "Calgary", "Canada", "CA", 51.1215, -114.0076, "America/Edmonton"),
        ("YEG", "CYEG", "Edmonton International Airport", "Edmonton", "Canada", "CA", 53.3097, -113.5800, "America/Edmonton"),
        ("YOW", "CYOW", "Ottawa Macdonald-Cartier International Airport", "Ottawa", "Canada", "CA", 45.3225, -75.6692, "America/Toronto"),
        ("YHZ", "CYHZ", "Halifax Stanfield International Airport", "Halifax", "Canada", "CA", 44.8808, -63.5085, "America/Halifax"),
        ("YWG", "CYWG", "Winnipeg James Armstrong Richardson International Airport", "Winnipeg", "Canada", "CA", 49.9100, -97.2399, "America/Winnipeg"),
    ]
    // swiftlint:enable line_length
}
