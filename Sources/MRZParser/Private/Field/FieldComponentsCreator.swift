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
    let getRawValueAndCheckDigit: @Sendable (
        _ lines: [String],
        _ position: FieldType.FieldPosition,
        _ contentType: FieldType.ContentType,
        _ shouldValidateCheckDigit: Bool,
        _ isOCRCorrectionEnabled: Bool
    ) -> (String, Int?)?

    init(
        getRawValueAndCheckDigit: @escaping @Sendable (
            _ lines: [String],
            _ position: FieldType.FieldPosition,
            _ contentType: FieldType.ContentType,
            _ shouldValidateCheckDigit: Bool,
            _ isOCRCorrectionEnabled: Bool
        ) -> (String, Int?)?
    ) {
        self.getRawValueAndCheckDigit = getRawValueAndCheckDigit
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
            isOCRCorrectionEnabled: Bool
        ) -> (String, Int)? {
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
                if isOCRCorrectionEnabled, contentType == .mixed {
                    @Dependency(\.ocrCorrector) var ocrCorrector
                    guard let bruteForcedString = ocrCorrector.findMatchingStrings( [rawValue],  {
                        guard let currentString = $0.first else {
                            return false
                        }

                        return validator.isValueValid( currentString,  checkDigit)
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

            let correctedValue = {
                if isOCRCorrectionEnabled {
                    @Dependency(\.ocrCorrector) var ocrCorrector
                    return ocrCorrector.correct( value,  contentType)
                } else {
                    return value
                }
            }()

            @Dependency(\.validator) var validator
            guard validator.isContentTypeValid( correctedValue,  contentType) else {
                return nil
            }

            return correctedValue
        }

        return .init { lines, position, contentType, shouldValidateCheckDigit, isOCRCorrectionEnabled in
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
                isOCRCorrectionEnabled: isOCRCorrectionEnabled
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
        getRawValueAndCheckDigit: { _, _, _, _, _ in nil }
    )
}
#endif
