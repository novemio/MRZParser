//
// Copyright (c) 2019-2021 Keyless Technologies Ltd.
// All Rights Reserved. 
//


struct CountryCodes {
    // Mapa alpha-3 kod -> alpha-2 kod
    static let alpha3ToAlpha2: [String: String] = [
        "AFG": "AF", "ALB": "AL", "DZA": "DZ", "AND": "AD", "AGO": "AO",
        "ARG": "AR", "ARM": "AM", "AUS": "AU", "AUT": "AT", "AZE": "AZ",
        "BHS": "BS", "BHR": "BH", "BGD": "BD", "BRB": "BB", "BLR": "BY",
        "BEL": "BE", "BLZ": "BZ", "BEN": "BJ", "BTN": "BT", "BOL": "BO",
        "BIH": "BA", "BWA": "BW", "BRA": "BR", "BRN": "BN", "BGR": "BG",
        "BFA": "BF", "BDI": "BI", "CPV": "CV", "KHM": "KH", "CMR": "CM",
        "CAN": "CA", "CAF": "CF", "TCD": "TD", "CHL": "CL", "CHN": "CN",
        "COL": "CO", "COM": "KM", "COD": "CD", "COG": "CG", "CRI": "CR",
        "CIV": "CI", "HRV": "HR", "CUB": "CU", "CYP": "CY", "CZE": "CZ",
        "DNK": "DK", "DJI": "DJ", "DMA": "DM", "DOM": "DO", "ECU": "EC",
        "EGY": "EG", "SLV": "SV", "GNQ": "GQ", "ERI": "ER", "EST": "EE",
        "SWZ": "SZ", "ETH": "ET", "FJI": "FJ", "FIN": "FI", "FRA": "FR",
        "GAB": "GA", "GMB": "GM", "GEO": "GE", "DEU": "DE", "GHA": "GH",
        "GRC": "GR", "GRD": "GD", "GTM": "GT", "GIN": "GN", "GNB": "GW",
        "GUY": "GY", "HTI": "HT", "HND": "HN", "HUN": "HU", "ISL": "IS",
        "IND": "IN", "IDN": "ID", "IRN": "IR", "IRQ": "IQ", "IRL": "IE",
        "ISR": "IL", "ITA": "IT", "JAM": "JM", "JPN": "JP", "JOR": "JO",
        "KAZ": "KZ", "KEN": "KE", "KIR": "KI", "KWT": "KW", "KGZ": "KG",
        "LAO": "LA", "LVA": "LV", "LBN": "LB", "LSO": "LS", "LBR": "LR",
        "LBY": "LY", "LIE": "LI", "LTU": "LT", "LUX": "LU", "MDG": "MG",
        "MWI": "MW", "MYS": "MY", "MDV": "MV", "MLI": "ML", "MLT": "MT",
        "MHL": "MH", "MRT": "MR", "MUS": "MU", "MEX": "MX", "FSM": "FM",
        "MDA": "MD", "MCO": "MC", "MNG": "MN", "MNE": "ME", "MAR": "MA",
        "MOZ": "MZ", "MMR": "MM", "NAM": "NA", "NRU": "NR", "NPL": "NP",
        "NLD": "NL", "NZL": "NZ", "NIC": "NI", "NER": "NE", "NGA": "NG",
        "PRK": "KP", "MKD": "MK", "NOR": "NO", "OMN": "OM", "PAK": "PK",
        "PLW": "PW", "PSE": "PS", "PAN": "PA", "PNG": "PG", "PRY": "PY",
        "PER": "PE", "PHL": "PH", "POL": "PL", "PRT": "PT", "QAT": "QA",
        "ROU": "RO", "RUS": "RU", "RWA": "RW", "KNA": "KN", "LCA": "LC",
        "VCT": "VC", "WSM": "WS", "SMR": "SM", "STP": "ST", "SAU": "SA",
        "SEN": "SN", "SRB": "RS", "SYC": "SC", "SLE": "SL", "SGP": "SG",
        "SVK": "SK", "SVN": "SI", "SLB": "SB", "SOM": "SO", "ZAF": "ZA",
        "KOR": "KR", "SSD": "SS", "ESP": "ES", "LKA": "LK", "SDN": "SD",
        "SUR": "SR", "SWE": "SE", "CHE": "CH", "SYR": "SY", "TJK": "TJ",
        "TZA": "TZ", "THA": "TH", "TLS": "TL", "TGO": "TG", "TON": "TO",
        "TTO": "TT", "TUN": "TN", "TUR": "TR", "TKM": "TM", "UGA": "UG",
        "UKR": "UA", "ARE": "AE", "GBR": "GB", "USA": "US", "URY": "UY",
        "UZB": "UZ", "VUT": "VU", "VEN": "VE", "VNM": "VN", "YEM": "YE",
        "ZMB": "ZM", "ZWE": "ZW"
    ]
    
    // Invertovana mapa alpha-2 -> alpha-3
    static let alpha2ToAlpha3: [String: String] = {
        var dict = [String: String]()
        for (key, value) in alpha3ToAlpha2 {
            dict[value] = key
        }
        return dict
    }()
    
    // Proveri da li postoji alpha-3 kod
    static func isValidAlpha3(_ code: String) -> Bool {
        alpha3ToAlpha2.keys.contains(code.uppercased())
    }
    
    // Proveri da li postoji alpha-2 kod
    static func isValidAlpha2(_ code: String) -> Bool {
        alpha2ToAlpha3.keys.contains(code.uppercased())
    }
    
    // Konvertuj alpha-3 u alpha-2 (npr. "ITA" -> "IT")
    static func alpha3ToAlpha2(_ code: String) -> String? {
        alpha3ToAlpha2[code.uppercased()]
    }
    
    // Konvertuj alpha-2 u alpha-3 (npr. "IT" -> "ITA")
    static func alpha2ToAlpha3(_ code: String) -> String? {
        alpha2ToAlpha3[code.uppercased()]
    }
}
