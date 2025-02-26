[![Build and test](https://github.com/romanmazeev/MRZParser/actions/workflows/Build%20and%20test.yml/badge.svg)](https://github.com/romanmazeev/MRZParser/actions/workflows/Build%20and%20test.yml)
[![spm](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://github.com/romanmazeev/MRZParser/blob/develop/Package.swift)

# MRZParser
[MRZ](https://en.wikipedia.org/wiki/Machine-readable_passport) code parser for TD1(ID cards), TD2, TD3 (Passports), MRVA (Visas type A), MRVB (Visas type B) types.

## Fields Distribution of Official Travel Documents:
![image](https://raw.githubusercontent.com/romanmazeev/MRZParser/master/docs/img/Fields_Distribution.png)
#### Fields description
Field | TD1 description | TD2 description | TD3 description | MRVA description | MRVB description
----- | --------------- | --------------- | --------------- | ---------------- | ----------------
Document type | The first letter shall be 'I', 'A' or 'C' |  <- | Normally 'P' for passport | The First letter must be 'V' | <- |
Country code | 3 letters code (ISO 3166-1) or country name (in English) | <- | <- | <- | <- |
Document number | Document number | <- | <- | <- | <- |
Birth date | Format: YYMMDD | <- | <- | <- | <- |
Sex | Genre. Male: 'M', Female: 'F' or Undefined: 'X', "<" or nil| <- | <- | <- | <- |
Expiry date  | Format: YYMMDD | <- | <- | <- | <- |
Nationality | 3 letters code (ISO 3166-1) or country name (in English) | <- | <- | <- | <- |
Surname | Holder primary identifier(s) | <- | Primary identifier(s) | <- | <- |
Given names | Holder secondary identifier(s) | <- | Secondary identifier(s) | <- | <- |
Optional data | Optional personal data at the discretion of the issuing State. Non-mandatory field. | <- | Personal number. In some countries non-mandatory field. | Optional personal data at the discretion of the issuing State. Non-mandatory field. | <- |
Optional data 2 | Optional personal data at the discretion of the issuing State. Non-mandatory field. | X | X | X | X |

## Installation guide
### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/romanmazeev/MRZParser.git", .upToNextMajor(from: "1.3.1"))
]
```
## Usage
To parse MRZ string use `MRZCode` initialiser.
```swift
MRZCode(mrzString: mrzString, isOCRCorrectionEnabled: false)
```
## Example
### TD1 (ID card)
#### Input
```
I<UTOD231458907<<<<<<<<<<<<<<<
7408122F1204159UTO<<<<<<<<<<<6
ERIKSSON<<ANNA<MARIA<<<<<<<<<<
```
#### Output
Field | Value
----- | -----
Document type | I
Country code | UTO
Document number | D23145890
Birth date | 1974.08.12
Sex | FEMALE
Expiry date  | 2012.04.15
Nationality | UTO
Surname | ERIKSSON
Given names | ANNA MARIA
Optional data | nil
Optional data 2 | nil

### TD2
#### Input
```
I<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<
D231458907UTO7408122F1204159<<<<<<<6
```
#### Output
Field | Value
----- | -----
Document type | I
Country code | UTO
Document number | D23145890
Birth date | 1974.08.12
Sex | FEMALE
Expiry date  | 2012.04.15
Nationality | UTO
Surname | ERIKSSON
Given names | ANNA MARIA
Optional data | nil

### TD3 (Passport)
#### Input
```
P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<
L898902C36UTO7408122F1204159ZE184226B<<<<<10
```
#### Output
Field | Value
----- | -----
Document type | P
Country code | UTO
Document number | L898902C3
Birth date | 1974.08.12
Sex | FEMALE
Expiry date  | 2012.04.15
Nationality | UTO
Surname | ERIKSSON
Given names | ANNA MARIA
Optional data | ZE184226B

### MRVA (Visa type A)
#### Input
```
V<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<
L8988901C4XXX4009078F96121096ZE184226B<<<<<<
```
#### Output
Field | Value
----- | -----
Document type | V
Country code | UTO
Document number | L8988901C
Birth date | 1940.09.07
Sex | FEMALE
Expiry date  | 1996.12.10
Nationality | XXX
Surname | ERIKSSON
Given names | ANNA MARIA
Optional data | 6ZE184226B

### MRVB (Visa type B)
#### Input
```
V<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<
L8988901C4XXX4009078F9612109<<<<<<<<
```
#### Output
Field | Value
----- | -----
Document type | V
Country code | UTO
Document number | L8988901C
Birth date | 1940.09.07
Sex | FEMALE
Expiry date  | 1996.12.10
Nationality | XXX
Surname | ERIKSSON
Given names | ANNA MARIA
Optional data | nil

## Credits

The project started as a fork of the [public repository](https://github.com/appintheair/MRZParser) which I created when was working in [App In The Air](https://github.com/appintheair).

## License

The library is distributed under the MIT [LICENSE](https://opensource.org/licenses/MIT).
