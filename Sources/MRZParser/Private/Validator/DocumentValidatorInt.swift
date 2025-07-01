//
// Copyright (c) 2019-2021 Keyless Technologies Ltd.
// All Rights Reserved.
//

import Dependencies
import Foundation


final class DocumentValidatorInt {
    
    // Default patterns for initialization
    private static let defaultPatterns: [String: String] = [
        "ITA": "^[A-Z]{2}\\d{5}[A-Z]{2}$", // Italy CIE: 2 letters, 5 digits, 2 letters
    ]
    
    // Dictionary of country-specific patterns (3-letter ISO 3166-1 alpha-3 codes)
    private static let patterns: [String: String] = defaultPatterns
    
    private init() {}
    
    // Validate document number for a given country
    static func validate(documentType:String, issuingCountry:String,documentNumber:String) -> Bool {
        print("VALIDATOR \(documentNumber) in \(issuingCountry)")
        
        
        if(!CountryCodes.isValidAlpha3(issuingCountry)){
            if(!CountryCodes.isValidAlpha2(issuingCountry)){
                print("VALIDATOR: Country code is invalid \(issuingCountry)")
                return false
            }
        }
        
        
        if (["I","C","A"].contains(documentType)) {
            print("VALIDATOR \(documentNumber) in \(issuingCountry)")
            // Normalize country code to uppercase
            let normalizedCountry = issuingCountry.uppercased()
            
            // Map 2-letter code to 3-letter code, or use as-is if 3-letter
            let effectiveCountry = CountryCodes.alpha2ToAlpha3[normalizedCountry] ?? normalizedCountry
            
            // If country is not in patterns, return true (no validation)
            guard let pattern = patterns[effectiveCountry] else {
                return true
            }
            
            // Validate document number against the pattern
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: documentNumber.utf16.count)
                let result =  regex.firstMatch(in: documentNumber, options: [], range: range) != nil
                print("VALIDATOR: result \(result)")
                return result;
            } catch {
                print("VALIDATOR: Invalid regex pattern for country \(issuingCountry): \(pattern)")
                return false
            }
        }else{
            return true
        } // skip if passport or visa
    }
    

}


