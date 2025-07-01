//
//  OCRCorrector.swift
//  MRZParser
//
//  Created by Roman Mazeev on 17/02/2025.
//

import Dependencies


//@DependencyClient
//struct OCRCorrector: Sendable {
//    var correct: @Sendable (_ string: String, _ contentType: FieldType.ContentType) -> String = { _, _ in "" }
//    var findMatchingStrings: @Sendable (_ strings: [String], _ isCorrectCombination: @Sendable ([String]) -> Bool) -> [String]?
//}

struct OCRCorrector: Sendable {
    let correct: @Sendable (_ string: String, _ contentType: FieldType.ContentType) -> String
    let findMatchingStrings: @Sendable (_ strings: [String], _ isCorrectCombination: @Sendable ([String]) -> Bool) -> [String]?

    init(
        correct: @escaping @Sendable (_ string: String, _ contentType: FieldType.ContentType) -> String = { _, _ in "" },
        findMatchingStrings: @escaping @Sendable (_ strings: [String], _ isCorrectCombination: @Sendable ([String]) -> Bool) -> [String]?
    ) {
        self.correct = correct
        self.findMatchingStrings = findMatchingStrings
    }
}

extension OCRCorrector: DependencyKey {
    static var liveValue: Self {
        @Sendable
        func correct(string: String, contentType: FieldType.ContentType) -> String {
            print("MRZ Parser: Correcting string: \(string)  type \(contentType)")
            var correctString: String = string
            switch contentType {
            case .digits:
                correctString = correctString
                    .replace("O", with: "0")
                    .replace("Q", with: "0")
                    .replace("U", with: "0")
                    .replace("D", with: "0")
                    .replace("I", with: "1")
                    .replace("Z", with: "2")
                    .replace("B", with: "8")
            case .letters:
                correctString =  correctString
                    .replace("0", with: "O")
                    .replace("1", with: "I")
                    .replace("2", with: "Z")
                    .replace("8", with: "B")
            case .sex:
                correctString = correctString
                    .replace("P", with: "F")
            case .mixed:
                correctString 
            }
            print("MRZ Parser: Corrected \(correctString)")
            return correctString;
        }

        return .init(
            correct: { string, contentType in
                correct(string: string, contentType: contentType)
            },
            findMatchingStrings: { strings, isCorrectCombination in
                
                var result: [String]?
                var stringsArray = strings.map { Array($0) }
                print("MRZ Parser: findMatchingStrings: strings\(strings) stringsArray\(stringsArray)")
                let getTransformedCharacters: (Character) -> [Character] = {
                    let digitsReplacedCharacter = Character(correct(string: String($0), contentType: .digits))
                    let lettersReplacedCharacter = Character(correct(string: String($0), contentType: .letters))
                    return [$0, digitsReplacedCharacter, lettersReplacedCharacter]
                }

                func dfs(index: Int) -> Bool {
                    print("MRZ Parser: dfs: index \(index) ")
                    if index == stringsArray.count {
                        // If we've modified all strings, check the combination
                        let currentCombination = stringsArray.map { String($0) }
         
                        if isCorrectCombination(currentCombination) {
                            result = currentCombination
                            print("MRZ Parser: findMatchingStrings  TRUE result \(currentCombination) ")
                            return true
                        }
                        print("MRZ Parser: findMatchingStrings result FALSE")
                        return false
                    }

                    // Iterate over every character position in the current string
                    for i in 0..<stringsArray[index].count {
                        let originalChar = stringsArray[index][i]

                        // Generate replacements for the current character
                        let replacements = getTransformedCharacters(originalChar)
                        print("MRZ Parser:  replacments \(replacements) result")
                        // Try each replacement character
                        for char in replacements {
                            stringsArray[index][i] = char
                            if dfs(index: index + 1) { // Recurse for the next string
                                return true
                            }
                        }

                        // Restore the original character before moving to the next position
                        stringsArray[index][i] = originalChar
                    }

                    return false
                }
                

                return dfs(index: 0) ? result : nil
            }
        )
    }
}

extension DependencyValues {
    var ocrCorrector: OCRCorrector {
        get { self[OCRCorrector.self] }
        set { self[OCRCorrector.self] = newValue }
    }
}

#if DEBUG
extension OCRCorrector: TestDependencyKey {
    static let testValue = Self(
        correct: { _, _ in "" },
        findMatchingStrings: { _, _ in nil }
    )
}
#endif
