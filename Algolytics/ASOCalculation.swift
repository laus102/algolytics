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
   private var _descriptions =  [String]()
   
   init(inputCSV: CSV?) {
      if let inCSV = inputCSV {
         let searchTermKey = inCSV.header[0] // dict key for the descriptions, (known to SwiftCSV as the header)
         
         _descriptions.append(searchTermKey) // add the very first description
         for row in inCSV.rows {
            if let thisDescription = row[searchTermKey] {
               if (thisDescription == "")
                  { continue }
               else
                  { _descriptions.append(thisDescription) }
            }
         }
      }
   }
   
   // ******************************
   func printDescriptions() -> () {
      for each in _descriptions
      { print("\(each)\n") }
   }
   
   // ******************************
   var descriptions: [String]
      { return _descriptions }
   
   // assumes that we've already opened a file and imported
   // and that the input CSV is of data type ASO Description
   // *****************************************************
   func cleanASODescription() -> () {
      var newDescriptions = [String]()
      var newDescription = ""
      
      for description in _descriptions {  // for each description
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
   
   // *******************************************************
   // just returns a CSV object given an ASODescriptionObject
   func csvEncoder() -> CSV? {
      var csvString = "Description\r"
      for description in _descriptions
         { csvString += description + "\r" }
      csvString = csvString.trimmed
      
      let newCSV = CSV(string: csvString, loadColumns: false)
      return newCSV
   }
}


