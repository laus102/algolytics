//
//  ComputerModel.swift
//  Algolytics
//
//  Created by Brendan Lau on 5/12/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

import Foundation
import SwiftCSV

class ComputerModel: NSObject {
   let inputCSV: CSV?
   var outputCSV = CSV(string: "")
   //                 keyword :  frequency
   var searchTerms = [String : Double]()  
   
   init(inputCSV: CSV!) {
      self.inputCSV = inputCSV
      outputCSV.header = ["Search Term:", "Frequency:", "Clicks:", "Impressions:", "Cost:", "Conversions:"]
      self.outputCSV = self.inputCSV!
   }
   
   
   // This method computes the output
   //*******************************************************
   func compute() {
      print("computing...")
      for entry in inputCSV!.rows { // for each row
         let generatedPhrases = generatePhrases(entry["Search term"]!) // generate all possible phrases
         self.updateSearchTerms(generatedPhrases) // update 'searchTerms' array
      }
      print("\nprinting searchTerms now\n")
      for each in self.searchTerms {
            print(each)
      }
      
   }
   
   // returns an array of all possible ordered combinations of words
   // ..in the given literal
   //*******************************************************
   func generatePhrases(literal: String) -> [String] {
      let phrase = literal.componentsSeparatedByString(" ")
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
   
   // updates the searchTerms...
   // 1) adds unique phrases to 'searchTerms'
   // 2) updates the count for phrases already present in 'searchTerms'
   //*******************************************************
   func updateSearchTerms(newGeneratedPhrases: [String]) {
       for newPhrase in newGeneratedPhrases {
         if (!literalAlreadySeen(newPhrase, searchTerms: self.searchTerms)) {
            self.searchTerms[newPhrase] = 0.0
         }
         self.searchTerms[newPhrase]! += 1.0
      }
   }
   //func aggregateStatistics(data)
   
   // returns if we've seen the literal in question yet or not
   //*******************************************************
   func literalAlreadySeen(literal: String, searchTerms: [String : Double]) -> Bool {
      if (searchTerms[literal] > 0) {
         return true
      }
      else {
         return false
      }
   }
   


}