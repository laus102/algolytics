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
enum Statistic {
   case Frequency, Clicks, Impressions, Cost, Conversions, SearchScore, Position
   
   var stringValue: String {
      switch self {
         case .Frequency: return "Frequency"
         case .Clicks:    return "Clicks"
         case .Impressions: return "Impressions"
         case .Cost: return "Cost"
         case .Conversions: return "Conversions"
         case .SearchScore: return "Search Score"
         case .Position: return "Position"
      }
   }
}

protocol GenericDataSet {
   func stats() -> [Statistic]
   func EmptyStatsDict() -> [Statistic : Double]
   func generatePhrases(literal: String)-> [String]
}

extension GenericDataSet {
   func EmptyStatsDict() -> [Statistic : Double] {
      var emptyStatsDict: [Statistic : Double] = [:]
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
   func stats() -> [Statistic] {
      return [.Frequency, .Clicks, .Impressions, .Cost, .Conversions]
   }
   
}

class SEO: GenericDataSet {
   func stats() -> [Statistic] {
      return [.Frequency, .Clicks, .Impressions, .Position]
   }
}

class ASOKeywords: GenericDataSet {
   func stats() -> [Statistic] {
      return [.Frequency, .SearchScore]
   }
}

class ASODescription: GenericDataSet {
   func stats() -> [Statistic] {
      return [.Frequency]
   }
   func generatePhrases(literal: String) -> [String] {
      return generateASODescriptionPhrases(literal)
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
