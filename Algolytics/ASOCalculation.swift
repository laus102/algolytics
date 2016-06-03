//
//  ASOCalculation.swift
//  Algolytics
//
//  Created by Brendan Lau on 6/1/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

import Foundation



// a smart phrase generator..
// assumes a non-empty literal input (some rows in the input CSV will be empty..check before calling this func)
// analyzes an app's store description and generates smart phrases
// 'smart phrase' ex: 
//
//  "Be prepared. Know Before™. Download the best weather app for free!”
//
//  We care about "best weather app" ... not "Be prepared. Know Before™. Download the"
//
//  Accounts for oddball non-ASCII characters in the description
//
func generateASODescriptionPhrases(literal: String) -> [String] {
   // takes a phrase in, removes all non AlphaN characters, separates the resulting string into separate indv. words
   
   let charsToBeRemoved = NSCharacterSet.alphanumericCharacterSet().invertedSet
   let alphaNumLiteral = literal.componentsSeparatedByCharactersInSet(charsToBeRemoved).joinWithSeparator(" ")
   let phrase = alphaNumLiteral.componentsSeparatedByString(" ")
   var newTerms: [String] = []
   var tempString = ""
   
   for i in 0 ..< phrase.count { // for each word "i" in original literal "phrase"
      for j in i ..< phrase.count { // start at word "i" and increment through the remaining words
         tempString += "\(phrase[j]) "       // at each iteration, add the new word "j" to the temp string
         newTerms.append(tempString.stringByTrimmingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet()))   // add this new permutation to the array of generated phrases
      }
      tempString = "" // reset the temp String after generating terms for each iteration of word "i"
   }
   return newTerms
}