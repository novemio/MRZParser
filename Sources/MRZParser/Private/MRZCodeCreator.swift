//
//  MRZCodeCreator.swift
//  MRZParser
//
//  Created by Roman Mazeev on 17/02/2025.
//

import Dependencies


//@DependencyClient
//struct MRZCodeCreator: Sendable {
//    var create: @Sendable (_ mrzLines: [String], _ isOCRCorrectionEnabled: Bool) -> MRZCode?
//}

struct MRZCodeCreator: Sendable {
    let create: @Sendable (_ mrzLines: [String], _ isOCRCorrectionEnabled: Bool) -> MRZCode?
    init(create: @escaping @Sendable (_ mrzLines: [String], _ isOCRCorrectionEnabled: Bool) -> MRZCode?) {
        self.create = create
    }
}

extension MRZCodeCreator: DependencyKey {
    static var liveValue: Self {
        // MARK: - MRZ-Format detection

        @Sendable
        func createMRZFormat(from mrzLines: [String]) -> MRZCode.Format? {
            guard let firstLine = mrzLines.first, let firstCharacter = firstLine.first else { return nil }

            /// MRV-B and MRV-A types
            let isVisaDocument = MRZCode.DocumentType(identifier: firstCharacter) == .visa
            let td2Format = MRZCode.Format.td2(isVisaDocument: isVisaDocument)
            let td3Format = MRZCode.Format.td3(isVisaDocument: isVisaDocument)

            switch mrzLines.count {
            case td2Format.linesCount, td3Format.linesCount:
                return [td2Format, td3Format].first(where: { $0.lineLength == uniformedLineLength(for: mrzLines) })
            case MRZCode.Format.td1.linesCount:
                return (uniformedLineLength(for: mrzLines) == MRZCode.Format.td1.lineLength) ? .td1 : nil
            default:
                return nil
            }
        }

        @Sendable
        func uniformedLineLength(for mrzLines: [String]) -> Int? {
            let lineLength = mrzLines[0].count
            guard mrzLines.allSatisfy({ $0.count == lineLength }) else { return nil }

            return lineLength
        }

        // MARK: - Initialisation

        @Sendable
        func validateAndCorrectIfNeeded(
            fieldsToValidate: [any FieldProtocol],
            isRussianNationalPassport: Bool,
            finalCheckDigit: Int,
            isOCRCorrectionEnabled: Bool
        ) -> [Field<String>]? {
            let fieldsToValidate = LockIsolated(fieldsToValidate)

            @Dependency(\.validator) var validator
            if !validator.isCompositionValid(fieldsToValidate.value, finalCheckDigit){
                if isOCRCorrectionEnabled {
                    let fieldsToBruteForce = fieldsToValidate.value.filter { $0.type.contentType(isRussianNationalPassport: isRussianNationalPassport) == .mixed }
                    // TODO: Do not bruteforce check digit
                    @Dependency(\.ocrCorrector) var ocrCorrector
                    guard let updatedFields = ocrCorrector.findMatchingStrings( fieldsToBruteForce.map(\.rawValue),  { combination in
                        combination.enumerated().forEach { index, element in
                            guard let value = element.fieldValue else {
                                assertionFailure("Can not be nil")
                                return
                            }

                            let field = Field<String>(
                                value: value,
                                rawValue: element,
                                checkDigit: fieldsToBruteForce[index].checkDigit,
                                type: fieldsToBruteForce[index].type
                            )

                            guard let index = fieldsToValidate.value.firstIndex(where: { $0.type == field.type }) else {
                                assertionFailure("Can not be nil")
                                return
                            }

                            fieldsToValidate.withValue { $0[index] = field }
                        }

                        return validator.isCompositionValid( fieldsToValidate.value,  finalCheckDigit)
                    }) else {
                        return nil
                    }

                    var result: [Field<String>] = []
                    fieldsToBruteForce.enumerated().forEach {
                        guard let value = updatedFields[$0.offset].fieldValue else {
                            assertionFailure("Can not be nil")
                            return
                        }

                        result.append(.init(
                            value: value,
                            rawValue: updatedFields[$0.offset],
                            checkDigit: $0.element.checkDigit,
                            type: $0.element.type
                        ))
                    }

                    return result
                } else {
                    return nil
                }
            } else {
                return [] // No corrections needed
            }
        }

        return .init(
            create: { mrzLines, isOCRCorrectionEnabled in
                guard let format = createMRZFormat(from: mrzLines) else { return nil }

                @Dependency(\.fieldCreator) var fieldCreator
                guard
                    let documentType = fieldCreator.createCharacterField(
                         mrzLines,
                         format,
                         .documentType,
                         isOCRCorrectionEnabled
                    ).map({ MRZCode.DocumentType(identifier: $0.value) }),
                    let issuingCountry = fieldCreator.createStringField(
                         mrzLines,
                         format,
                         .issuingCountryCode,
                         false,
                         isOCRCorrectionEnabled
                    ).map({ MRZCode.Country(identifier: $0.value) }),
                    let birthdateField = fieldCreator.createDateField(
                         mrzLines,
                         format,
                         .birth,
                         isOCRCorrectionEnabled
                    ),
                    let sexField = fieldCreator.createCharacterField(
                         mrzLines,
                         format,
                         .sex,
                         isOCRCorrectionEnabled
                    )
                else {
                    return nil
                }

                let documentSubtype = fieldCreator.createCharacterField(
                     mrzLines,
                     format,
                     .documentSubtype,
                     isOCRCorrectionEnabled
                ).map { MRZCode.DocumentSubtype(identifier: $0.value) }

                let isRussianNationalPassport = documentType == .passport && documentSubtype == .national && issuingCountry == .russia

                var optionalDataField = fieldCreator.createStringField(
                     mrzLines,
                     format,
                     .optionalData(.one),
                     isRussianNationalPassport,
                     isOCRCorrectionEnabled
                )

                guard
                    let nameField = fieldCreator.createNameField(
                         mrzLines,
                         format,
                         isRussianNationalPassport,
                         isOCRCorrectionEnabled
                    ),
                    var documentNumberField = fieldCreator.createDocumentNumberField(
                         mrzLines,
                         format,
                         isRussianNationalPassport ? optionalDataField?.value.first : nil,
                         isOCRCorrectionEnabled
                    ),
                    let nationalityField = fieldCreator.createStringField(
                         mrzLines,
                         format,
                         .nationalityCountryCode,
                         isRussianNationalPassport,
                         isOCRCorrectionEnabled
                    )
                else {
                    return nil
                }

                let expiryDateField = fieldCreator.createDateField(
                     mrzLines,
                     format,
                     .expiry,
                     isOCRCorrectionEnabled
                )

                var optionalData2Field = fieldCreator.createStringField(
                     mrzLines,
                     format,
                .optionalData(.two),
                isRussianNationalPassport,
                  isOCRCorrectionEnabled
                )

                let finalCheckDigitField = fieldCreator.createFinalCheckDigitField(
                    mrzLines,
                  format,
                    isOCRCorrectionEnabled
                )

                if let finalCheckDigitField {
                    guard let correctedFields = validateAndCorrectIfNeeded(
                        fieldsToValidate: FieldType.validateFinalCheckDigitFields(mrzFormat: format).compactMap {
                            switch $0 {
                            case .documentNumber:
                                documentNumberField
                            case .date(.birth):
                                birthdateField
                            case .date(.expiry):
                                expiryDateField ?? .init(value: .distantFuture, rawValue: "<<<<<<", checkDigit: 0, type: .date(.expiry))
                            case .optionalData(.one):
                                optionalDataField
                            case .optionalData(.two):
                                optionalData2Field
                            default:
                                fatalError("Unexpected field type")
                            }
                        },
                        isRussianNationalPassport: isRussianNationalPassport,
                        finalCheckDigit: finalCheckDigitField.value,
                        isOCRCorrectionEnabled: isOCRCorrectionEnabled
                    ) else {
                        return nil
                    }

                    correctedFields.forEach { field in
                        switch field.type {
                        case .documentNumber:
                            documentNumberField = field
                        case .optionalData(.one):
                            optionalDataField = field
                        case .optionalData(.two):
                            optionalData2Field = field
                        default:
                            assertionFailure("Unexpected field type")
                        }
                    }
                }

                let mrzKey = {
                    var mrzKeyFields: [any FieldProtocol] = [documentNumberField, birthdateField]
                    if let expiryDateField = expiryDateField {
                        mrzKeyFields.append(expiryDateField)
                    }

                    return mrzKeyFields.reduce(into: "") { result, field in
                        let rawValue = field.rawValue
                        let checkDigit = field.checkDigit.map { String($0) } ?? ""
                        result += rawValue + checkDigit
                    }
                }()

                return .init(
                    mrzKey: mrzKey,
                    format: format,
                    documentType: documentType,
                    documentSubtype: documentSubtype,
                    issuingCountry: issuingCountry,
                    name: nameField.value,
                    documentNumber: documentNumberField.value,
                    nationalityCountryCode: nationalityField.value,
                    birthdate: birthdateField.value,
                    sex: .init(identifier: sexField.value),
                    expiryDate: expiryDateField?.value,
                    optionalData: optionalDataField?.value,
                    optionalData2: optionalData2Field?.value
                )
            }
        )
    }
}

extension DependencyValues {
    var mrzCodeCreator: MRZCodeCreator {
        get { self[MRZCodeCreator.self] }
        set { self[MRZCodeCreator.self] = newValue }
    }
}

#if DEBUG
extension MRZCodeCreator: TestDependencyKey {
    static let testValue = Self(
        create: { _, _ in nil }
    )
}
#endif
