//
//  String_Extensions.swift
//
//  Created by Brendan Lau on 6/15/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

import Foundation

private let kWhitespaceAndNewlineSet = CharacterSet.whitespacesAndNewlines
private let kAlphaNumericSet = CharacterSet.alphanumerics

extension String
{
   var trimmed: String {
      return trimmingCharacters(in: kWhitespaceAndNewlineSet)
   }
   var words: [String] {
   return self.components(separatedBy: " ")
   }
   var isValidEmail: Bool {
      let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
      let emailTest = Predicate(format:"SELF MATCHES %@", emailRegEx)
      return emailTest.evaluate(with: self)
   }
//   var isValidSearchTerm: Bool {
//      //let searchTermRegEx = ""
//      //let searchTermTest =
//   }
   
   func removeSpecialCharsFromString(text: String) -> String {
      var newString = ""
      let okayChars : Set<Character> =
         Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890-".characters)
      newString = String(text.characters.filter {okayChars.contains($0) })
      newString = newString.replacingOccurrences(of: "-", with: " ")
      return newString
   }
   
   func containsNoAlphaNumericCharacters() -> Bool {
      let range = self.rangeOfCharacter(from: kAlphaNumericSet)
      if let _ = range { return false }
      return true
   }
}
