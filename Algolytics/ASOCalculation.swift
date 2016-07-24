//
//  ASOCalculation.swift
//  Algolytics
//
//  Created by Brendan Lau on 6/1/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

import Foundation
import SwiftCSV

class ASODescriptionObject {
   private var _descriptions: [String]?
   // only used if ASODescription is permutation type
   private var _appTitleWords: [String]?
   private var _keywords: [String]?
   var isPermutationType = false
   
   init(inputCSV: CSV?) {
      if let inCSV = inputCSV {
         if inCSV.rows.count == 1 { // is of type permutation
            _appTitleWords = inCSV.header[0].components(separatedBy: " ")
            _keywords = inCSV.rows[0][inCSV.header[0]]?.components(separatedBy: ",")
            isPermutationType = true
            return
         }
         
         let searchTermKey = inCSV.header[0] // dict key for the descriptions, (known to SwiftCSV as the header)
         _descriptions = [String]()
         _descriptions?.append(searchTermKey) // add the very first description
         for row in inCSV.rows {
            if let thisDescription = row[searchTermKey] {
               if (thisDescription == "")
                  { continue }
               else
                  { _descriptions?.append(thisDescription) }
            }
         }
      }
   }
   
   // ******************************
   func printDescriptions() -> () {
      if let descriptions = _descriptions {
         for each in descriptions
         { print("\(each)\n") }
      }
   }
   
   // ******************************
   var descriptions: [String]? {
      if let descriptions = _descriptions { return descriptions }
      else { return nil }
   }
      
   
   // assumes that we've already opened a file and imported
   // and that the input CSV is of data type ASO Description
   // *****************************************************
   func cleanASODescription() -> () {
      if isPermutationType {
         _cleanASOPermutation()
         return
      }
      
      var newDescriptions = [String]()
      var newDescription = ""
      guard let descriptions = _descriptions else { return }
      
      for description in descriptions {  // for each description
         let separatedWords = description.components(separatedBy: " ") //separated into individual words
         
         for word in separatedWords { // clean each word
            let newWord = word.removeSpecialCharsFromString(text: word).lowercased()
            newDescription += newWord + " " // add to original description
         }
         
         newDescription = newDescription.trimmed // trim trailing white space
         newDescriptions.append(newDescription)
         newDescription = ""
      }
      _descriptions = newDescriptions
   }
   
   // ******************************************************
   private func _cleanASOPermutation() -> ()  {
      var newAppTitleWords = [String]()
      var newKeywords = [String]()
      
      if let appTitleWords = _appTitleWords {
         for titleWord in appTitleWords {
            let newTitleWord = titleWord.removeSpecialCharsFromString(text: titleWord).lowercased()
            newAppTitleWords.append(newTitleWord)
         }
      } else { return }
      
      if let keywords = _keywords {
         for keyword in keywords {
            let newKeyword = keyword.removeSpecialCharsFromString(text: keyword).lowercased()
            newKeywords.append(newKeyword)
         }
      } else { return }
      
      _appTitleWords = newAppTitleWords
      _keywords = newKeywords
   }
   
   // *******************************************************
   func generateASOPermutationPhrases() -> [String : [Statistic : Double]] {
      if let titleWords = _appTitleWords {
         for titleWord in titleWords {
            
         }
      }
   }
   
   // *******************************************************
   // just returns a CSV object given an ASODescriptionObject
   func csvEncoder() -> CSV? {
      var csvString = "Description\r"
      guard let descriptions = _descriptions else { return nil }
      
      for description in descriptions
         { csvString += description + "\r" }
      csvString = csvString.trimmed
      
      let newCSV = CSV(string: csvString, loadColumns: false)
      return newCSV
   }
}


