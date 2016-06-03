//
//  Statistics.swift
//  Algolytics
//
//  Created by Brendan Lau on 5/31/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

import Foundation
import SwiftCSV

let pbcHeader = ["Campaign", "Match type", "Search term", "Added/Excluded", "Ad group", "Clicks", "Impressions", "CTR", "Avg. CPC", "Cost", "Avg. position", "Conversions", "Cost / conv.", "Conv. rate", "All conv.", "View-through conv."]

let seoHeader = ["Queries", "Clicks", "Impressions", "CTR", "Position"]
let asoHeader = ["Keywords", "Search Score", "Chance", "Total Apps", "Current Rank"]


//*************************************************************************
protocol GenericDataSet {
   func stats() -> [String]
   func EmptyStatsDict() -> [String : Double]
   func generatePhrases(literal: String)-> [String]
}

extension GenericDataSet {
   func EmptyStatsDict() -> [String : Double] {
      var emptyStatsDict: [String : Double] = [:]
      for each in self.stats()
      { emptyStatsDict[each] = 0.0 }
      return emptyStatsDict
   }
   
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
}


class PBC: GenericDataSet {
   func stats() -> [String] {
      return ["Frequency", "Clicks", "Impressions", "Cost", "Conversions"]
   }
   
}

class SEO: GenericDataSet {
   func stats() -> [String] {
      return ["Frequency", "Clicks", "Impressions", "Position"]
   }
}

class ASOKeywords: GenericDataSet {
   func stats() -> [String] {
      return ["Frequency", "Search Score"]
   }
}

class ASODescription: GenericDataSet {
   func stats() -> [String] {
      return ["Frequency"]
   }
   func generatePhrases(literal: String) -> [String] {
      return generateASODescriptionPhrases(literal)
   }
}

class StatisticTuple {
   var aggregated: Bool?
   var statValue: Double?
   
   func alreadyAggregated () -> Bool {
      return aggregated!
   }
   func value() -> Double {
      return self.statValue!
   }
}


func factoryData(header: [String]) -> GenericDataSet? {
   if (header == pbcHeader)      { return PBC() }
   else if (header == seoHeader) { return SEO() }
   else if (header == asoHeader) { return ASOKeywords() }
   else if (header.count == 1)   { return ASODescription() }
   else { print("error matching stat type")
         return nil }
}
