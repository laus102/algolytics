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
   
   var inputCSV: CSV?
   var outputCSV = ""
   var dataSet: GenericDataSet?
   var statsUpdateCounter = 0
   var parentVC: ViewController?
   
   //                 keyword   statistic  (frequency)
   var searchTerms = [String : [Statistic : Double]]()  // unique phrase list
   var segments = [ [String : [Statistic : Double]] ]() // reduces memory-intensive computation
                                                        // phrase list is broken into several smaller bits
                                                        // easier for GCD to handle...
   var segmentsSearchTerms = [ [String : [Statistic : Double]] ]() // searchTerm array for each indv. segment to 
                                                                   // update to
   //*******************************************************
   init(inputCSV: CSV!, viewController: ViewController) {
      parentVC = viewController
      self.inputCSV = inputCSV
      dataSet = factoryData(inputCSV.header)
      outputCSV += dataSet!.searchTermKey() + ","
      
      guard let stats = dataSet?.stats() else { return }
      for outputStat in stats {
         outputCSV += outputStat.stringValue + ","
      }
      
      outputCSV.removeAtIndex(outputCSV.endIndex.predecessor())
      outputCSV += "\n"
   }
   
   
   
   // This method computes the output
   //*******************************************************
   func compute() {
      guard let rows = inputCSV?.rows else { return }
      parentVC!.display(Progress.Generating)
      for entry in rows { // for each row
         let generatedPhrases = dataSet!.generatePhrases(entry[dataSet!.searchTermKey()]!) // generate all possible phrases
         updateSearchTerms(generatedPhrases) // update 'searchTerms' array .. just AGGs freq and gives an empty stats dict
      }
      
      var segments = splitPhraseList()
      dispatchSegmentUpdates(&segments) // concurrently aggregates the asynchronous chunks
   }

   
   // cleans the input CSV of any junk data
   //*******************************************************
   func cleanCSV() {
      var cleanedText: String = ""
      let charsToBeRemoved = NSCharacterSet.alphanumericCharacterSet().invertedSet
      
      if isASODescription(inputCSV!.header) {
//         for row in inputCSV!.rows {
//              let literal = row
//             clean ASO style
//         }
         
      }
         
      else { // PPC, SEO, or ASOKeywords
         for row in inputCSV!.rows {
            let searchTerm: String = row[dataSet!.searchTermKey()]!
            if searchTerm.containsNoAlphaNumericCharacters()
               { print("non alphanumeric searchTerm: \(searchTerm)")
                  continue} // if the original term has no AlphNum, we can immediately discard
            let alphaNumLiteral = searchTerm.componentsSeparatedByCharactersInSet(charsToBeRemoved).joinWithSeparator(" ")
            cleanedText += alphaNumLiteral + "," // add the cleaned search term
            
            let statsArray = dataSet!.inputStats()
            for inputStat in statsArray
               { cleanedText += row[inputStat.stringValue]! + "," } // add each inputstat's "cellValue,"
            cleanedText.removeAtIndex(cleanedText.endIndex.predecessor()) //remove the very last comma
            cleanedText += "\n"
         }
      }
      inputCSV! = CSV(string: cleanedText, delimiter: " ", loadColumns: true)
   }
   
   // searchTerm   statistic   statvalue
   // searchTerms ... [String : [Statistic : Double]]
   //*******************************************************
   func generateOuputCSV() -> String {
      for searchTerm in searchTerms {
         outputCSV += "\(searchTerm.0),"
         for stat in dataSet!.stats() {
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
            { searchTerms[newPhrase] = dataSet!.EmptyStatsDict() } // create an (empty) entry for it in searchTerms[[]]
         updateFrequency(newPhrase)
       }
   }
   
   // goes through all of the aggregated unique phrases of this particular queue (approx. 1459 values)
   // looks in each row of the input CSV
   //       if this unique phrase exists within the row's searchTerm
   //                aggregate the appropriate statistic for the dataSet
   //************************************************************************************************
   func updateSegmentStatistics( inout segment: [String : [Statistic : Double]], inout rows: [[String: String]], inout dict: [String : [Statistic : Double]]) -> () {
      guard let searchTermKey = dataSet?.searchTermKey() else { return }
      guard let stats = dataSet?.stats() else { return }
      
      for var term in segment { // the unique phrase that we're interested in
         for var row in rows { // the input searchTerm we're analyzing
            autoreleasepool({
               if (wholePhraseOccursInSearchTerm(&term.0, searchTerm: &row[searchTermKey]!)) {
                  if let _ = dict[term.0] { // dictionary exists for this unique phrase
                     print("dictionary exists: \(dict[term.0])")
                     for var each in stats {
                        if var doubleStatValue = rowStatisticValue(&row, statistic: &each) { //if there is a valid value for this stat
                           updateStatistic(&each, phrase: &term.0, rowValue: &doubleStatValue, dict: &dict)
                        }
                     }
                  }
                  else { // dictionary does not yet exist
                     print("dict does not exist")
                     var emptyDict = [Statistic : Double]() // create new dictionary
                     for var each in stats {
                        emptyDict[each] = rowStatisticValue(&row, statistic: &each) // copy the stats
                     }
                     dict[term.0] = emptyDict
                     print("new dict: \(emptyDict)")
                  }
               }
            })
         }
      }
   }
   
   
   // returns the Double value of the specified statistic
   // (SwiftCSV provides the stat as a String, we must convert it)
   //*******************************************************
   func rowStatisticValue( inout row: [String : String], inout statistic: Statistic) -> Double? {
      guard let stringValue = row[statistic.stringValue] else {
         return nil
      }
      return Double(stringValue)
   }
   
   
   // returns if we've seen the literal in question yet or not
   //*******************************************************
   func literalAlreadySeen(literal: String) -> Bool {
      if let literalFreq = searchTerms[literal]?[.Frequency] {
         if literalFreq > 0
            { return true }
      }
      return false
   }
   
   // updates the frequency of the given phrase
   // updates the frequency for phrases already present in 'searchTerms'
   //*******************************************************
   func updateFrequency(phrase: String) -> ()
      { searchTerms[phrase]![.Frequency]! += 1.0 }
   
   
   // updates the necessary statistic
   //*******************************************************
   func updateStatistic(inout statistic: Statistic, inout phrase: String, inout rowValue: Double,
                         inout dict: [String : [Statistic : Double]]) -> () {
      switch statistic {
         case .Frequency: break
         default:
               dict[phrase]![statistic]! += rowValue
               self.statsUpdateCounter += 1
      }
   }
}


