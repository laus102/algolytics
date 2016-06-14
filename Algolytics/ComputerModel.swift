//
//  ComputerModel.swift
//  Algolytics
//
//  Created by Brendan Lau on 5/12/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

import Foundation
import SwiftCSV

extension String {
   func containsNoAlphaNumericCharacters() -> Bool {
      let range = self.rangeOfCharacterFromSet(NSCharacterSet.alphanumericCharacterSet())
      if let _ = range { return false }
      return true
   }
}

class ComputerModel: NSObject {
   
   var inputCSV: CSV?
   var outputCSV = ""
   var dataSet: GenericDataSet?
   
   
   //                 keyword   statistic   (frequency)
   //var searchTerms = [String : [String : StatisticTuple]]()
   var searchTerms = [String : [Statistic : Double]]()
   //var searchTerms = [String : [String : (Bool, Double)]]()
   
   init(inputCSV: CSV!) {
      self.inputCSV = inputCSV
      self.dataSet = factoryData(inputCSV.header)
      outputCSV += self.dataSet!.searchTermKey() + ","
      for outputStat in self.dataSet!.stats() {
         outputCSV += outputStat.stringValue + ","
      }
      outputCSV.removeAtIndex(outputCSV.endIndex.predecessor())
      outputCSV += "\n"
   }
   
   // cleans the input CSV of any junk data
   //*******************************************************
   func cleanCSV() {
      var cleanedText: String = ""
      let charsToBeRemoved = NSCharacterSet.alphanumericCharacterSet().invertedSet
      
      if isASODescription(inputCSV!.header) {
         for row in inputCSV!.rows {
            //let literal = row
            // clean ASO style
         }
         
      }
      else { // PPC, SEO, or ASOKeywords
         for row in inputCSV!.rows {
            let searchTerm: String = row[self.dataSet!.searchTermKey()]!
            if searchTerm.containsNoAlphaNumericCharacters()
               { print("non alphanumeric searchTerm: \(searchTerm)")
                  continue} // if the original term has no AlphNum, we can immediately discard
            let alphaNumLiteral = searchTerm.componentsSeparatedByCharactersInSet(charsToBeRemoved).joinWithSeparator(" ")
            cleanedText += alphaNumLiteral + "," // add the cleaned search term
            
            let statsArray = self.dataSet!.inputStats()
            for inputStat in statsArray
               { cleanedText += row[inputStat.stringValue]! + "," } // add each inputstat's "cellValue,"
            cleanedText.removeAtIndex(cleanedText.endIndex.predecessor()) //remove the very last comma
            cleanedText += "\n"
         }
      }
      
      
      self.inputCSV! = CSV(string: cleanedText, delimiter: " ", loadColumns: true)
   }
   
   // This method computes the output
   //*******************************************************
   func compute() {
      for entry in inputCSV!.rows { // for each row
         let generatedPhrases = dataSet!.generatePhrases(entry[dataSet!.searchTermKey()]!) // generate all possible phrases
         self.updateSearchTerms(generatedPhrases) // update 'searchTerms' array
      }
      self.updateStatistics()
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
   
   // 1) given a set of a possible combinations of the words in a single row's searchTerm entry
   // 2) goes through each combination 
   //      if this particular comb. has already been seen
   //              1) update the freq (don't add another dict. entry)
   //      else
   //              1) add a blank dict. entry
   //              2) update the freq
   //*******************************************************
   func updateSearchTerms(newGeneratedPhrases: [String]) {  // called on each row from .csv... each set of gen. phrases
       for newPhrase in newGeneratedPhrases {  // NEW PHRASE CAN AND WILL CONTAIN DUPLICATES
         if (!literalAlreadySeen(newPhrase))  //if this is the first time seeing it
            { self.searchTerms[newPhrase] = self.dataSet!.EmptyStatsDict() } // create an (empty) entry for it in searchTerms[[]]
         updateFrequency(newPhrase)
       }
   }
   
   // goes through all of the aggregated unqiue phrases
   // looks in each row of the input CSV
   //       if this unique phrase exists within the row's searchTerm
   //                aggregate the appropriate statistic for the dataSet
   //*******************************************************
   func updateStatistics() {
//      for each in self.searchTerms {
//         print(each.0)
//      }
      for term in self.searchTerms {
         for row in inputCSV!.rows { // go through the original search terms
            if (wholePhraseOccursInSearchTerm(term.0, searchTerm: row[self.dataSet!.searchTermKey()]!)) { //if we see our new gen. phrase in the orig.
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
   func rowStatisticValue(row: [String : String], statistic: Statistic) -> Double? {
      guard let stringValue = row[statistic.stringValue] else {
         return nil
      }
      return Double(stringValue)
   }
   
   
   // returns if we've seen the literal in question yet or not
   //*******************************************************
   func literalAlreadySeen(literal: String) -> Bool {
      if let literalFreq = self.searchTerms[literal]?[.Frequency] {
         if literalFreq > 0
            { return true }
      }
      return false
   }
   
   // lets us know whether or not the given phrase occurs within the given searchTerm
   //  *** ONLY COUNTS WHOLE OCCURENCES OF INPUT PHRASE (I.E. SEPARATED BY WHTIE SPACE)
   //     e.x. -->  "PIC" in "PICture" will NOT be counted
   //*******************************************************
   func wholePhraseOccursInSearchTerm(phrase: String, searchTerm: String) -> Bool {
      let separatedSearchTerm: [String] = searchTerm.componentsSeparatedByString(" ")
      let separatedPhrase: [String] = phrase.componentsSeparatedByString(" ")
      
      if separatedPhrase.count > 1 { //phrase is more than one word
         for i in 0..<separatedSearchTerm.count {
            var comparisonString = ""
            let suspensionDifferential = separatedSearchTerm.count - (i + separatedPhrase.count)
            
            if (suspensionDifferential >= 0) {
               var counter = i
               for _ in separatedPhrase {
                  comparisonString += separatedSearchTerm[counter] + " "
                  counter += 1
               }
               
               comparisonString = comparisonString.stringByTrimmingCharactersInSet(
                  NSCharacterSet.whitespaceAndNewlineCharacterSet())
               let originalPhrase = phrase.stringByTrimmingCharactersInSet(
                  NSCharacterSet.whitespaceAndNewlineCharacterSet())
               if comparisonString == originalPhrase
                  {return true}
            }
         }
      }
         
      else { // phrase is only one word
         for j in 0..<separatedSearchTerm.count {
            if separatedSearchTerm[j] == phrase
            { return true }
         }
      }
      return false
   }
   
   // updates the frequency of the given phrase
   // updates the frequency for phrases already present in 'searchTerms'
   //*******************************************************
   func updateFrequency(phrase: String) -> ()
      { self.searchTerms[phrase]![.Frequency]! += 1.0 }
   
   
   // updates the necessary statistic
   //*******************************************************
   func updateStatistic(statistic: Statistic, phrase: String, rowValue: Double) -> () {
      switch statistic {
         case .Frequency: break
         default:
            self.searchTerms[phrase]![statistic]! += rowValue
      }
   }
}