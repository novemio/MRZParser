//
//  FieldCreator.swift
//  MRZParser
//
//  Created by Roman Mazeev on 17/02/2025.
//

import Dependencies
import Foundation

struct FieldCreator: Sendable {
    let createStringField: @Sendable (
        _ lines: [String],
        _ format: MRZCode.Format,
        _ type: FieldType,
        _ isRussianNationalPassport: Bool,
        _ isOCRCorrectionEnabled: Bool
    ) -> Field<String>?
    
    let createDocumentNumberField: @Sendable (
        _ lines: [String],
        _ format: MRZCode.Format,
        _ russianNationalPassportHiddenCharacter: Character?,
        _ documentType: MRZCode.DocumentType,
        _ issuingCountry: MRZCode.Country,
        _ isOCRCorrectionEnabled: Bool
    ) -> Field<String>?
    
    let createCharacterField: @Sendable (
        _ lines: [String],
        _ format: MRZCode.Format,
        _ type: FieldType,
        _ isOCRCorrectionEnabled: Bool
    ) -> Field<Character>?
    
    let createNameField: @Sendable (
        _ lines: [String],
        _ format: MRZCode.Format,
        _ isRussianNationalPassport: Bool,
        _ isOCRCorrectionEnabled: Bool
    ) -> Field<MRZCode.Name>?
    
    let createDateField: @Sendable (
        _ lines: [String],
        _ format: MRZCode.Format,
        _ dateFieldType: FieldType.DateFieldType,
        _ isOCRCorrectionEnabled: Bool
    ) -> Field<Date>?
    
    let createFinalCheckDigitField: @Sendable (
        _ lines: [String],
        _ format: MRZCode.Format,
        _ isOCRCorrectionEnabled: Bool
    ) -> Field<Int>?
    
    init(
        createStringField: @escaping @Sendable (
            _ lines: [String],
            _ format: MRZCode.Format,
            _ type: FieldType,
            _ isRussianNationalPassport: Bool,
            _ isOCRCorrectionEnabled: Bool
        ) -> Field<String>?,
        createDocumentNumberField: @escaping @Sendable (
            _ lines: [String],
            _ format: MRZCode.Format,
            _ russianNationalPassportHiddenCharacter: Character?,
            _ documentType: MRZCode.DocumentType,
            _ issuingCountry: MRZCode.Country,
            _ isOCRCorrectionEnabled: Bool
        ) -> Field<String>?,
        createCharacterField: @escaping @Sendable (
            _ lines: [String],
            _ format: MRZCode.Format,
            _ type: FieldType,
            _ isOCRCorrectionEnabled: Bool
        ) -> Field<Character>?,
        createNameField: @escaping @Sendable (
            _ lines: [String],
            _ format: MRZCode.Format,
            _ isRussianNationalPassport: Bool,
            _ isOCRCorrectionEnabled: Bool
        ) -> Field<MRZCode.Name>?,
        createDateField: @escaping @Sendable (
            _ lines: [String],
            _ format: MRZCode.Format,
            _ dateFieldType: FieldType.DateFieldType,
            _ isOCRCorrectionEnabled: Bool
        ) -> Field<Date>?,
        createFinalCheckDigitField: @escaping @Sendable (
            _ lines: [String],
            _ format: MRZCode.Format,
            _ isOCRCorrectionEnabled: Bool
        ) -> Field<Int>?
    ) {
        self.createStringField = createStringField
        self.createDocumentNumberField = createDocumentNumberField
        self.createCharacterField = createCharacterField
        self.createNameField = createNameField
        self.createDateField = createDateField
        self.createFinalCheckDigitField = createFinalCheckDigitField
    }
}

extension FieldCreator: DependencyKey {
    static var liveValue: Self {
        .init(
            createStringField: { lines, format, type, isRussianNationalPassport, isOCRCorrectionEnabled in
                guard let position = type.position(for: format) else {
                    return nil
                }

                @Dependency(\.fieldComponentsCreator) var fieldComponentsCreator
                guard let (rawValue, checkDigit) = fieldComponentsCreator.getRawValueAndCheckDigitWithAddition(
                     lines,
                     position,
                     type.contentType(isRussianNationalPassport: isRussianNationalPassport),
                     type.shouldValidateCheckDigit(mrzFormat: format),
                     isOCRCorrectionEnabled,
                     nil
                ), let value = rawValue.fieldValue else {
                    return nil
                }

                return .init(value: value, rawValue: rawValue, checkDigit: checkDigit, type: type)
            },
            createDocumentNumberField: { lines, format, russianNationalPassportHiddenCharacter, documentType, issuingCountry,  isOCRCorrectionEnabled in
                let type: FieldType = .documentNumber
                guard let position = type.position(for: format) else {
                    assertionFailure("Document number position not found for format: \(format)")
                    return nil
                }

                @Dependency(\.fieldComponentsCreator) var fieldComponentsCreator
                guard let (rawValue, checkDigit) = fieldComponentsCreator.getRawValueAndCheckDigitWithAddition(
                     lines,
                     position,
                     type.contentType(isRussianNationalPassport: russianNationalPassportHiddenCharacter != nil),
                     type.shouldValidateCheckDigit(mrzFormat: format),
                     isOCRCorrectionEnabled,
                     { value in
                        MRZLogger.debug("Additional validation \(value)")
                        let documentTypeString: String = String(documentType.identifier)
                        let issuingCountryString: String = issuingCountry.identifier
                        return  DocumentValidatorInt.validate(documentType:documentTypeString, issuingCountry: issuingCountryString, documentNumber: value)
                        
                    }

                ), var value = rawValue.fieldValue else {
                    return nil
                }

                if let russianNationalPassportHiddenCharacter {
                    value.insert(russianNationalPassportHiddenCharacter, at: value.index(value.startIndex, offsetBy: 3))
                }

                return .init(value: value, rawValue: rawValue, checkDigit: checkDigit, type: type)
            },
            createCharacterField: { lines, format, type, isOCRCorrectionEnabled in
                guard let position = type.position(for: format) else {
                    assertionFailure("Document number position not found for format: \(format)")
                    return nil
                }

                @Dependency(\.fieldComponentsCreator) var fieldComponentsCreator
                guard let (rawValue, checkDigit) = fieldComponentsCreator.getRawValueAndCheckDigitWithAddition(
                     lines,
                     position,
                    // `isRussianNationalPassport` doesn't matter here
                     type.contentType(isRussianNationalPassport: false),
                     type.shouldValidateCheckDigit(mrzFormat: format),
                     isOCRCorrectionEnabled,
                     nil
                ), let value = rawValue.fieldValue, let character = value.first else {
                    return nil
                }

                return .init(value: character, rawValue: rawValue, checkDigit: checkDigit, type: type)
            },
            createNameField: { lines, format, isRussianNationalPassport, isOCRCorrectionEnabled in
                let type: FieldType = .name
                guard let position = type.position(for: format) else {
                    assertionFailure("Document number position not found for format: \(format)")
                    return nil
                }

                @Dependency(\.fieldComponentsCreator) var fieldComponentsCreator
                guard let (rawValue, checkDigit) = fieldComponentsCreator.getRawValueAndCheckDigitWithAddition(
                     lines,
                     position,
                     type.contentType(isRussianNationalPassport: isRussianNationalPassport),
                     type.shouldValidateCheckDigit(mrzFormat: format),
                     isOCRCorrectionEnabled,
                     nil
                ) else {
                    return nil
                }

                let convertedValue = {
                    if isRussianNationalPassport {
                        // Convert to cyrilic
                        @Dependency(\.cyrillicNameConverter) var cyrillicNameConverter
                        return cyrillicNameConverter.convert( rawValue, isOCRCorrectionEnabled)
                    } else {
                        return rawValue
                    }
                }()

                @Dependency(\.validator) var validator
                guard validator.isContentTypeValid( convertedValue,  .letters) else {
                    return nil
                }

                let identifiers = convertedValue.trimmingFillers
                    .components(separatedBy: "<<")
                    .map { $0.replace("<", with: " ") }

                return .init(
                    value: .init(surname: identifiers[0], givenNames: identifiers.count > 1 ? identifiers[1] : nil),
                    rawValue: rawValue,
                    checkDigit: checkDigit,
                    type: type
                )
            },
            createDateField: { lines, format, dateFieldType, isOCRCorrectionEnabled in
                func date(from string: String, dateFieldType: FieldType.DateFieldType) -> Date? {
                    guard let parsedYear = Int(string.substring(0, to: 1)) else {
                        return nil
                    }

                    @Dependency(\.date.now) var dateNow
                    let currentCentennial = Calendar.current.component(.year, from: dateNow) / 100
                    let previousCentennial = currentCentennial - 1
                    let currentYear = Calendar.current.component(.year, from: dateNow) - currentCentennial * 100
                    let boundaryYear = currentYear + 50
                    let centennial = switch dateFieldType {
                    case .birth:
                        (parsedYear > currentYear) ? String(previousCentennial) : String(currentCentennial)
                    case .expiry:
                        parsedYear >= boundaryYear ? String(previousCentennial) : String(currentCentennial)
                    }

                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMdd"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
                    return formatter.date(from: centennial + string)
                }

                let type: FieldType = .date(dateFieldType)
                guard let position = type.position(for: format) else {
                    assertionFailure("Document number position not found for format: \(format)")
                    return nil
                }

                @Dependency(\.fieldComponentsCreator) var fieldComponentsCreator
                guard let (rawValue, checkDigit) = fieldComponentsCreator.getRawValueAndCheckDigitWithAddition(
                     lines,
                     position,
                    // `isRussianNationalPassport` doesn't matter here
                     type.contentType(isRussianNationalPassport: false),
                     type.shouldValidateCheckDigit(mrzFormat: format),
                     isOCRCorrectionEnabled,
                     nil
                ), let dateValue = date(from: rawValue, dateFieldType: dateFieldType) else {
                    return nil
                }

                return .init(value: dateValue, rawValue: rawValue, checkDigit: checkDigit, type: type)
            },
            createFinalCheckDigitField: { lines, format, isOCRCorrectionEnabled in
                let type: FieldType = .finalCheckDigit
                guard let position = type.position(for: format) else {
                    return nil
                }

                @Dependency(\.fieldComponentsCreator) var fieldComponentsCreator
                guard let (rawValue, checkDigit) = fieldComponentsCreator.getRawValueAndCheckDigitWithAddition(
                     lines,
                     position,
                    // `isRussianNationalPassport` doesn't matter here
                     type.contentType(isRussianNationalPassport: false),
                     type.shouldValidateCheckDigit(mrzFormat: format),
                     isOCRCorrectionEnabled,
                     nil
                ), let value = rawValue.fieldValue, let intValue = Int(value) else {
                    return nil
                }

                return .init(value: intValue, rawValue: rawValue, checkDigit: checkDigit, type: type)
            }
        )
    }
}

extension DependencyValues {
    var fieldCreator: FieldCreator {
        get { self[FieldCreator.self] }
        set { self[FieldCreator.self] = newValue }
    }
}

#if DEBUG
extension FieldCreator: TestDependencyKey {
    static let testValue = Self(
        createStringField: { _, _, _, _, _ in nil },
        createDocumentNumberField: { _, _, _, _, _,_ in nil },
        createCharacterField: { _, _, _, _ in nil },
        createNameField: { _, _, _, _ in nil },
        createDateField: { _, _, _, _ in nil },
        createFinalCheckDigitField: { _, _, _ in nil }
    )
}
#endif
