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
   
   var asoDescriptionObject: ASODescriptionObject?
   
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
      
      outputCSV.remove(at: outputCSV.index(before: outputCSV.endIndex))
      outputCSV += "\n"
      
      if let inCSV = self.inputCSV {
         if (isASODescription(inCSV.header)) {
            asoDescriptionObject = ASODescriptionObject(inputCSV: inputCSV)
            asoDescriptionObject?.cleanASODescription()
            
            asoDescriptionObject?.printDescriptions()
            let newCSV = asoDescriptionObject!.csvEncoder()
            self.inputCSV = asoDescriptionObject!.csvEncoder()
         
            print("Printing new csv rows")
            for row in inputCSV!.rows {
               print("\(row[dataSet!.searchTermKey()])")
            }
         }
      }
   }
   
   
   // This method computes the output
   //*******************************************************
   func compute() {
      guard let rows = inputCSV?.rows else { return }
      parentVC!.display(Progress.generating)
      for entry in rows { // for each row
         let generatedPhrases = dataSet!.generatePhrases(entry[dataSet!.searchTermKey()]!) // generate all possible phrases
         updateSearchTerms(generatedPhrases) // update 'searchTerms' array .. just AGGs freq and gives an empty stats dict
      }
      
      var segments = splitPhraseList()
//      for segment in segments {
//         for term in segment {
//            print(term.key)
//         }
//      }
      dispatchSegmentUpdates(&segments) // concurrently aggregates the asynchronous chunks
   }

   
   // cleans the input CSV of any junk data
   //*******************************************************
//   func cleanCSV() {
//      var cleanedText: String = ""
//      let charsToBeRemoved = CharacterSet.alphanumerics.inverted
//      
//      if isASODescription(inputCSV!.header) {
////         for row in inputCSV!.rows {
////              let literal = row
////             clean ASO style
////         }
//         
//      }
//         
//      else { // PPC, SEO, or ASOKeywords
//         for row in inputCSV!.rows {
//            let searchTerm: String = row[dataSet!.searchTermKey()]!
//            if searchTerm.containsNoAlphaNumericCharacters()
//               { print("non alphanumeric searchTerm: \(searchTerm)")
//                  continue} // if the original term has no AlphNum, we can immediately discard
//            let alphaNumLiteral = searchTerm.components(separatedBy: charsToBeRemoved).joined(separator: " ")
//            cleanedText += alphaNumLiteral + "," // add the cleaned search term
//            
//            let statsArray = dataSet!.inputStats()
//            for inputStat in statsArray
//               { cleanedText += row[inputStat.stringValue]! + "," } // add each inputstat's "cellValue,"
//            cleanedText.remove(at: cleanedText.index(before: cleanedText.endIndex)) //remove the very last comma
//            cleanedText += "\n"
//         }
//      }
//      inputCSV! = CSV(string: cleanedText, delimiter: " ", loadColumns: true)
//   }
   
   // searchTerm   statistic   statvalue
   // searchTerms ... [String : [Statistic : Double]]
   //*******************************************************
   func generateOuputCSV() -> String {
      for searchTerm in searchTerms {
         outputCSV += "\(searchTerm.key),"
         for stat in dataSet!.stats() {
            outputCSV += "\(searchTerm.value[stat]!),"
         }
         outputCSV = String(outputCSV.characters.dropLast()) + "\n"
      }
      return outputCSV
   }
   
   
   // returns an array of all possible ordered combinations of words
   // ..in the given literal
   //*******************************************************
   func generatePhrases(_ literal: String) -> [String] {
      let phrase = literal.components(separatedBy: " ")
      var newTerms: [String] = []
      var tempString = ""
      
      for i in 0 ..< phrase.count { // for each word "i" in original literal "phrase"
         for j in i ..< phrase.count { // start at word "i" and increment through the remaining words
            tempString += "\(phrase[j]) "       // at each iteration, add the new word "j" to the temp string
            newTerms.append(tempString.trimmingCharacters(
               in: CharacterSet.whitespacesAndNewlines))  // add this new permutation to the array of generated phrases
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
   func updateSearchTerms(_ newGeneratedPhrases: [String]) {  // called on each row from .csv... each set of gen. phrases
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
   func updateSegmentStatistics( _ segment: inout [String : [Statistic : Double]], rows: inout [[String: String]], dict: inout [String : [Statistic : Double]]) -> () {
      guard let searchTermKey = dataSet?.searchTermKey() else { return }
      guard let stats = dataSet?.stats() else { return }
      
      for var term in segment { // the unique phrase that we're interested in
         for var row in rows { // the input searchTerm we're analyzing
            autoreleasepool({
               if (wholePhraseOccursInSearchTerm(&term.key, searchTerm: &row[searchTermKey]!)) {
                  if let _ = dict[term.key] { // dictionary exists for this unique phrase
                     for var each in stats {
                        if var doubleStatValue = rowStatisticValue(&row, statistic: &each) { //if there is a valid value for this stat
                           updateStatistic(&each, phrase: &term.key, rowValue: &doubleStatValue, dict: &dict)
                        }
                     }
                  }
                  else { // dictionary does not yet exist

                     var emptyDict = [Statistic : Double]() // create new dictionary
                     for var each in stats {
                        emptyDict[each] = rowStatisticValue(&row, statistic: &each) // copy the stats
                     }
                     dict[term.key] = emptyDict
                  }
               }
            })
         }
      }
   }
   
   
   // returns the Double value of the specified statistic
   // (SwiftCSV provides the stat as a String, we must convert it)
   //*******************************************************
   func rowStatisticValue( _ row: inout [String : String], statistic: inout Statistic) -> Double? {
      guard let stringValue = row[statistic.stringValue] else {
         return nil
      }
      return Double(stringValue)
   }
   
   
   // returns if we've seen the literal in question yet or not
   //*******************************************************
   func literalAlreadySeen(_ literal: String) -> Bool {
      if let literalFreq = searchTerms[literal]?[.frequency] {
         if literalFreq > 0
            { return true }
      }
      return false
   }
   
   // updates the frequency of the given phrase
   // updates the frequency for phrases already present in 'searchTerms'
   //*******************************************************
   func updateFrequency(_ phrase: String) -> ()
      { searchTerms[phrase]![.frequency]! += 1.0 }
   
   
   // updates the necessary statistic
   //*******************************************************
   func updateStatistic(_ statistic: inout Statistic, phrase: inout String, rowValue: inout Double,
                         dict: inout [String : [Statistic : Double]]) -> () {
      switch statistic {
         case .frequency: break
         default:
               dict[phrase]![statistic]! += rowValue
               self.statsUpdateCounter += 1
      }
   }
}


