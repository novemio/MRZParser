//
//  FieldComponentsCreator.swift
//  MRZParser
//
//  Created by Roman Mazeev on 21/02/2025.
//

import Dependencies
import Foundation

//@DependencyClient
//struct FieldComponentsCreator: Sendable {
//    var getRawValueAndCheckDigit: @Sendable (
//        _ lines: [String],
//        _ position: FieldType.FieldPosition,
//        _ contentType: FieldType.ContentType,
//        _ shouldValidateCheckDigit: Bool,
//        _ isOCRCorrectionEnabled: Bool
//    ) -> (String, Int?)?
//}

struct FieldComponentsCreator: Sendable {

    let getRawValueAndCheckDigitWithAddition: @Sendable (
        _ lines: [String],
        _ position: FieldType.FieldPosition,
        _ contentType: FieldType.ContentType,
        _ shouldValidateCheckDigit: Bool,
        _ isOCRCorrectionEnabled: Bool,
        _ aditionalValidation: ((String) -> Bool)?
    ) -> (String, Int?)?


    init(
        getRawValueAndCheckDigitWithAddition: @escaping @Sendable (
            _ lines: [String],
            _ position: FieldType.FieldPosition,
            _ contentType: FieldType.ContentType,
            _ shouldValidateCheckDigit: Bool,
            _ isOCRCorrectionEnabled: Bool,
            _ aditionalValidation: ((String) -> Bool)?
        ) -> (String, Int?)?
    ) {
        self.getRawValueAndCheckDigitWithAddition = getRawValueAndCheckDigitWithAddition
    }
    
//    @Sendable
//    func getRawValueAndCheckDigit(
//          lines: [String],
//          position: FieldType.FieldPosition,
//          contentType: FieldType.ContentType,
//          shouldValidateCheckDigit: Bool,
//          isOCRCorrectionEnabled: Bool,
//          aditionalValidation: ((String) -> Bool)? = nil
//    ) -> (String, Int?)?{
//        
//        return getRawValueAndCheckDigitWithAddition(lines, position, contentType,shouldValidateCheckDigit, isOCRCorrectionEnabled, aditionalValidation)
//    }

        
}

extension FieldComponentsCreator {
    @Sendable
    func getRawValueAndCheckDigit(
        lines: [String],
        position: FieldType.FieldPosition,
        contentType: FieldType.ContentType,
        shouldValidateCheckDigit: Bool,
        isOCRCorrectionEnabled: Bool,
        additionalValidation: ((String) -> Bool)? = nil
    ) -> (String, Int?)? {
        return getRawValueAndCheckDigitWithAddition(
            lines,
            position,
            contentType,
            shouldValidateCheckDigit,
            isOCRCorrectionEnabled,
            additionalValidation
        )
    }
}



extension FieldComponentsCreator: DependencyKey {
    static var liveValue: Self {
        @Sendable
        func validate(
            line: String,
            rawValue: String,
            position: FieldType.FieldPosition,
            contentType: FieldType.ContentType,
            isOCRCorrectionEnabled: Bool,
            aditionalValidation: ((String) -> Bool)
        ) -> (String, Int)? {
            MRZLogger.debug("MRZ PARSER: FieldComponentsCreator: Validate line: \(line) rawValue: \(rawValue)")
            func getCheckDigit(
                from string: String,
                endIndex: Int,
                isOCRCorrectionEnabled: Bool
            ) -> Int? {
                let value = string.substring(endIndex, to: endIndex)
                let correctedValue = {
                    if isOCRCorrectionEnabled {
                        @Dependency(\.ocrCorrector) var ocrCorrector
                        return ocrCorrector.correct(value, .digits)

                    } else {
                        return value
                    }
                }()
                
                // Validation not needed because validated through Int initialiser
                return Int(correctedValue)
            }
            
            guard let checkDigit = getCheckDigit(
                from: line,
                endIndex: position.range.upperBound,
                isOCRCorrectionEnabled: isOCRCorrectionEnabled
            ) else {
                return nil
            }
            
            @Dependency(\.validator) var validator
            if !validator.isValueValid(rawValue, checkDigit) {
                MRZLogger.debug("MRZ Parser: Validate: NOT VALID \(rawValue) ")
                if isOCRCorrectionEnabled, contentType == .mixed {
                    @Dependency(\.ocrCorrector) var ocrCorrector
                    MRZLogger.debug("MRZ Parser: Validate: bruteForce \(rawValue) ")
                    guard let bruteForcedString = ocrCorrector.findMatchingStrings([rawValue], {
                        guard let currentString = $0.first else {
                            return false
                        }
                        MRZLogger.debug("MRZ Parser: Validate: isCorrectCombination \(currentString) ")
                        return validator.isValueValid(currentString, checkDigit) && aditionalValidation(currentString)
                    })?.first else {
                        return nil
                    }
                    
                    return (bruteForcedString, checkDigit)
                } else {
                    return nil
                }
            } else {
                return (rawValue, checkDigit)
            }
        }
        
        @Sendable
        func getRawValue(
            from string: String,
            range: Range<Int>,
            contentType: FieldType.ContentType,
            isOCRCorrectionEnabled: Bool
        ) -> String? {
            let value = string.substring(range.lowerBound, to: range.upperBound - 1).uppercased()
            MRZLogger.debug("MRZ Parser: getRawValue: RAW: \(value)")
            let correctedValue = {
                if isOCRCorrectionEnabled {
                    @Dependency(\.ocrCorrector) var ocrCorrector
                    return ocrCorrector.correct( value,  contentType)
                } else {
                    return value
                }
            }()
            MRZLogger.debug("MRZ Parser: getRawValue: Corrected:\(correctedValue)")
            @Dependency(\.validator) var validator
            guard validator.isContentTypeValid( correctedValue,  contentType) else {
                return nil
            }
            return correctedValue
        }
        
        return .init { lines, position, contentType, shouldValidateCheckDigit, isOCRCorrectionEnabled ,additionalValdiation in
            let line = lines[position.line]
            guard let rawValue = getRawValue(
                from: line,
                range: position.range,
                contentType: contentType,
                isOCRCorrectionEnabled: isOCRCorrectionEnabled
            ) else {
                return nil
            }
            
            guard shouldValidateCheckDigit else {
                return (rawValue, nil)
            }
            
            return validate(
                line: line,
                rawValue: rawValue,
                position: position,
                contentType: contentType,
                isOCRCorrectionEnabled: isOCRCorrectionEnabled,
                aditionalValidation: additionalValdiation ?? {value in return true }
            )
        }
    }
}

extension DependencyValues {
    var fieldComponentsCreator: FieldComponentsCreator {
        get { self[FieldComponentsCreator.self] }
        set { self[FieldComponentsCreator.self] = newValue }
    }
}

#if DEBUG
extension FieldComponentsCreator: TestDependencyKey {
    static let testValue = Self(
        getRawValueAndCheckDigitWithAddition: { _, _, _, _, _, _ in nil }
    )
}
#endif
