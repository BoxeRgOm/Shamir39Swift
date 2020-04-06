# Shamir39Swift

[![CI Status](https://img.shields.io/travis/boxergom/Shamir39Swift.svg?style=flat)](https://travis-ci.org/boxergom/Shamir39Swift)
[![Version](https://img.shields.io/cocoapods/v/Shamir39Swift.svg?style=flat)](https://cocoapods.org/pods/Shamir39Swift)
[![License](https://img.shields.io/cocoapods/l/Shamir39Swift.svg?style=flat)](https://cocoapods.org/pods/Shamir39Swift)
[![Platform](https://img.shields.io/cocoapods/p/Shamir39Swift.svg?style=flat)](https://cocoapods.org/pods/Shamir39Swift)

This is for converting BIP39 mnemonic phrases to shamir secret sharing scheme parts whilst retaining the benefit of mnemonics on iOS.

# Bip39
https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
https://iancoleman.io/bip39/

# Shamir39
https://github.com/iancoleman/shamir39/blob/master/specification.md
https://github.com/iancoleman/shamir39/
https://iancoleman.io/shamir39/

# Usage
Copy my swift files and paste on your iOS project.

Split :

```Swift
try shamir.splits(bip39MnemonicWords: <your mnemonic>
                                   m: <need split count>, 
                                   n: <all split count>)
```

Combine: 

```Swift
try shamir.combine(parts: <splited parts>)
```

## Installation

Shamir39Swift is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Shamir39Swift', '~> 0.2.8'
```

## Author

boxergom, ms.kang@bono.tech

## License

Shamir39Swift is available under the MIT license. See the LICENSE file for more info.
