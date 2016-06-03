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
   var outputCSV = "Search Term,Frequency,Clicks,Impressions,Cost,Conversions\n"
   var dataSet: GenericDataSet?
   
   
   //                 keyword   statistic   (frequency)
   //var searchTerms = [String : [String : StatisticTuple]]()
   var searchTerms = [String : [String : Double]]()
   //var searchTerms = [String : [String : (Bool, Double)]]()
   
   init(inputCSV: CSV!) {
      self.inputCSV = inputCSV
      self.dataSet = factoryData(inputCSV.header)
   }
   
   // This method computes the output
   //*******************************************************
   func compute() {
      for entry in inputCSV!.rows { // for each row
         let generatedPhrases = dataSet!.generatePhrases(entry["Search term"]!) // generate all possible phrases
         self.updateSearchTerms(generatedPhrases) // update 'searchTerms' array
      }
      
      //
   }
   
   // searchTerm   statistic   statvalue
   // searchTerms ... [String : [Statistic : Double]]
   //*******************************************************
   func generateOuputCSV() -> String {
      for searchTerm in searchTerms {
         outputCSV += "\(searchTerm.0),"
         for stat in self.dataSet!.stats() {
            outputCSV += "\(searchTerm.1[ stat]!),"
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
   func updateSearchTerms(newGeneratedPhrases: [String]) {  // called on each row from .csv... each set of gen. phrases
       for newPhrase in newGeneratedPhrases {  // NEW PHRASE CAN AND WILL CONTAIN DUPLICATES
         if (!literalAlreadySeen(newPhrase, searchTerms: self.searchTerms))  //if this is the first time seeing it
            { self.searchTerms[newPhrase] = self.dataSet!.EmptyStatsDict() } // create an (empty) entry for it in searchTerms[[]]
         updateFrequency(newPhrase)
       }
      
       for term in self.searchTerms {
         for row in inputCSV!.rows { // go through the original search terms
            if (phraseOccursInSearchTerm(term.0, searchTerm: row["Search term"]!)) { //if we see our new gen. phrase in the orig.
               for each in self.dataSet!.stats() {                      // for each of our generated phrase's output statistics
                  if let doubleStatValue = rowStatisticValue(row, statistic: each) { //if there is a valid value for this stat
                     updateStatistic(each, phrase: term.0, rowValue: doubleStatValue)
                  }
               }
            }
         }
       }
   }
   
   
   // returns the Double value of the specified statistic
   // (SwiftCSV provides the stat as a String, we must convert it)
   //*******************************************************
   func rowStatisticValue(row: [String : String], statistic: String) -> Double? {
      guard let stringValue = row[statistic] else {
         return nil
      }
      return Double(stringValue)
   }
   
   
   // returns if we've seen the literal in question yet or not
   //*******************************************************
   func literalAlreadySeen(literal: String, searchTerms: [String : [String : Double]]) -> Bool {
      if let literalFreq = searchTerms[literal]?["Frequency"] {
         if literalFreq > 0
            { return true }
      }
      return false
   }
   
   // lets us know whether or not the given phrase occurs within the given searchTerm
   //*******************************************************
   func phraseOccursInSearchTerm(phrase: String, searchTerm: String) -> Bool {
      if (searchTerm.rangeOfString(phrase) != nil)
         { return true }
      return false
   }
   
   // updates the frequency of the given phrase
   // updates the frequency for phrases already present in 'searchTerms'
   //*******************************************************
   func updateFrequency(phrase: String) -> ()
      { self.searchTerms[phrase]!["Frequency"]! += 1.0 }
   
   
   // updates the necessary statistic
   //*******************************************************
   func updateStatistic(statistic: String, phrase: String, rowValue: Double) -> () {
      switch statistic {
      case "Frequency":    break
      default:
         //print("\(phrase)_\(statistic): \(self.searchTerms[phrase]![statistic]!)")
         self.searchTerms[phrase]![statistic]! += rowValue
         //print("\(phrase)_\(statistic): \(self.searchTerms[phrase]![statistic]!)")
      }
   }
}