//
//  ValidatorTests.swift
//  MRZParser
//
//  Created by Roman Mazeev on 17/02/2025.
//

import XCTest
@testable import MRZParser

final class ValidatorTests: XCTestCase {
    // MARK: - isCompositionValid

    func testIsCompositionValid() {
        let fields: [Field<String>] = [
            .init(value: "test", rawValue: "S123456<", checkDigit: 10, type: .documentNumber),
            .init(value: "test2", rawValue: "G<5678", checkDigit: nil, type: .names)
        ]

        XCTAssertTrue(Validator.liveValue.isCompositionValid(validatedFields: fields, finalCheckDigit: 6))
        XCTAssertFalse(Validator.liveValue.isCompositionValid(validatedFields: fields, finalCheckDigit: 0))
    }

    // MARK: - isValueValid

    func testIsValueValid() {
        let rawValue = "S12345678<"
        XCTAssertTrue(Validator.liveValue.isValueValid(rawValue: rawValue, checkDigit: 0))
        XCTAssertFalse(Validator.liveValue.isValueValid(rawValue: rawValue, checkDigit: 36))
    }

    func testIsValueValidNoCheckDigitUnexpectedScalar() {
        XCTAssertFalse(Validator.liveValue.isValueValid(rawValue: "😄", checkDigit: 0))
    }

    // MARK: - isContentTypeValid

    func testIsContentTypeValidMixed() {
        XCTAssertTrue(Validator.liveValue.isContentTypeValid(value: "123", contentType: .mixed))
        XCTAssertTrue(Validator.liveValue.isContentTypeValid(value: "abc", contentType: .mixed))
    }

    func testIsContentTypeValidLetters() {
        XCTAssertFalse(Validator.liveValue.isContentTypeValid(value: "123", contentType: .letters))
        XCTAssertTrue(Validator.liveValue.isContentTypeValid(value: "<ab<c<", contentType: .letters))
    }

    func testIsContentTypeValidDigits() {
        XCTAssertFalse(Validator.liveValue.isContentTypeValid(value: "abc", contentType: .digits))
        XCTAssertTrue(Validator.liveValue.isContentTypeValid(value: "<12<3<", contentType: .digits))
    }
}
