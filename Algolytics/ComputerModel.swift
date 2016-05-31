//
//  ComputerModel.swift
//  Algolytics
//
//  Created by Brendan Lau on 5/12/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

import Foundation
import SwiftCSV

enum PBCStatistic: String {
   case Frequency = "Frequency"
   case Clicks = "Clicks"
   case Impressions = "Impressions"
   case Cost = "Cost"
   case Conversions = "Conversions"
   
   static var all: [PBCStatistic] {
      return [.Frequency, .Clicks, .Impressions, .Cost, .Conversions]
   }
}

enum SEOStatistic: String {
   case Frequency = "Frequency"
   case Clicks = "Clicks"
   case Impressions = "Impressions"
   case Position = "Position"
   
   static var all: [SEOStatistic] {
      return [.Frequency, .Clicks, .Impressions, .Position]
   }
}


class ComputerModel: NSObject {
   
   let inputCSV: CSV?
   var outputCSV = "Search Term,Frequency,Clicks,Impressions,Cost,Conversions\n"
   
   //                 keyword   statistic   frequency
   var searchTerms = [String : [PBCStatistic : Double]]()
   
   init(inputCSV: CSV!) {
      self.inputCSV = inputCSV
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
   
   // searchTerm   statistic   statvalue
   // searchTerms ... [String : [Statistic : Double]]
   //*******************************************************
   func generateOuputCSV() -> String {
      for searchTerm in searchTerms {
         outputCSV += "\(searchTerm.0),"
         for stat in PBCStatistic.all {
            outputCSV += "\(searchTerm.1[stat]!),"
         }
         outputCSV = String(outputCSV.characters.dropLast()) + "\n"
      }
      return outputCSV
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
   //*******************************************************
   func updateSearchTerms(newGeneratedPhrases: [String]) {
       for newPhrase in newGeneratedPhrases {
         if (!literalAlreadySeen(newPhrase, searchTerms: self.searchTerms)) { //if this is the first time seeing it
            self.searchTerms[newPhrase] = [.Frequency : 0.0,
                                           .Clicks : 0.0,
                                           .Impressions : 0.0,
                                           .Cost : 0.0,
                                           .Conversions : 0.0] // create an entry for it in searchTerms[[]]
            
         }
         updateFrequency(newPhrase)
         
         for row in inputCSV!.rows {
            if (phraseOccursInSearchTerm(newPhrase, searchTerm: row["Search term"]!)) {
               for each in PBCStatistic.all {
                  guard let doubleStatValue = rowStatisticValue(row, statistic: each) else {
                     continue
                  }
                  updateStatistic(each, phrase: newPhrase, rowValue: doubleStatValue)
               }
            }
         }
       }
   }
   
   
   // returns the Double value of the specified statistic
   // (SwiftCSV provides the stat as a String, we must convert it)
   //*******************************************************
   func rowStatisticValue(row: [String : String], statistic: PBCStatistic) -> Double? {
      guard let stringValue = row[statistic.rawValue] else {
         return nil
      }
      return Double(stringValue)
   }
   
   
   // returns if we've seen the literal in question yet or not
   //*******************************************************
   func literalAlreadySeen(literal: String, searchTerms: [String : [PBCStatistic : Double]]) -> Bool {
      if (searchTerms[literal]?[.Frequency] > 0) {
         return true
      }
      else {
         return false
      }
   }
   
   // lets us know whether or not the given phrase occurs within the given searchTerm
   //*******************************************************
   func phraseOccursInSearchTerm(phrase: String, searchTerm: String) -> Bool {
      if (searchTerm.rangeOfString(phrase) != nil)
         { return true }
      return false
   }
   
   
   // updates the frequency of the given phrase
   // 1) adds unique phrases to 'searchTerms'
   // 2) updates the frequency for phrases already present in 'searchTerms'
   // NB : After this, all unique search terms will be present in searchTerms[String : [ String : Double]]
   //*******************************************************
   func updateFrequency(phrase: String) -> () {
      self.searchTerms[phrase]![.Frequency]! += 1.0
   }
   
   
   //
   //*******************************************************
   func updateStatistic(statistic: PBCStatistic, phrase: String, rowValue: Double) -> () {
      switch statistic {
         case .Frequency:   break
         case .Clicks:      self.searchTerms[phrase]![.Clicks]! += rowValue
         case .Impressions: self.searchTerms[phrase]![.Impressions]! += rowValue
         case .Cost:        self.searchTerms[phrase]![.Cost]! += rowValue
         case .Conversions: self.searchTerms[phrase]![.Conversions]! += rowValue
      // default: print("Error: No correct Statistic Type Suppied")
      }
   }
}