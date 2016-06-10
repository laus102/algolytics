//
//  Statistics.swift
//  Algolytics
//
//  Created by Brendan Lau on 5/31/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

import Foundation
import SwiftCSV

let ppcHeader = ["Campaign", "Match type", "Search term", "Added/Excluded", "Ad group", "Clicks", "Impressions", "CTR", "Avg. CPC", "Cost", "Avg. position", "Conversions", "Cost / conv.", "Conv. rate", "All conv.", "View-through conv."]

let seoHeader = ["Queries", "Clicks", "Impressions", "CTR", "Position"]
let asoHeader = ["Keywords", "Search Score", "Chance", "Total Apps", "Current Rank"]


//*************************************************************************

enum InputStatistic {
   case Campaign, MatchType, SearchTerm, AddedExcluded, AdGroup, Clicks, Impressions, CTR, AvgCPC, Cost,
        AvgPosition, Conversions, CostConv, ConvRate, AllConv, ViewThroughConv, Queries, Position, Keywords,
        SearchScore, Chance, TotalApps, CurrentRank
   
   var stringValue: String {
      switch self {
      case .Campaign: return "Campaign"
      case .MatchType: return "Match type"
      case .SearchTerm: return "Search term"
      case .AddedExcluded: return "Added/Excluded"
      case .AdGroup: return "Ad group"
      case .Clicks:    return "Clicks"
      case .Impressions: return "Impressions"
      case .CTR: return "CTR"
      case .AvgCPC: return "Avg. CPC"
      case .Cost: return "Cost"
      case .AvgPosition: return "Avg. position"
      case .Conversions: return "Conversions"
      case .CostConv: return "Cost / conv."
      case .ConvRate: return "Conv. rate"
      case .AllConv: return "All conv."
      case .ViewThroughConv: return "View-through conv."
      case .Queries: return "Queries"
      case .Position: return "Position"
      case .Keywords: return "Keywords"
      case .SearchScore: return "Search Score"
      case .Chance: return "Chance"
      case .TotalApps: return "Total Apps"
      case .CurrentRank: return "Current Ranks"
      }
   }
}

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
   func inputStats() -> [InputStatistic]
   func stats() -> [Statistic]
   func searchTermKey() -> String
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


class PPC: GenericDataSet {
   func inputStats() -> [InputStatistic] {
        return [.Campaign, .MatchType, .SearchTerm, .AddedExcluded, .AdGroup,
                .Clicks, .Impressions, .CTR, .AvgCPC, .Cost, .AvgPosition,
                .Conversions, .CostConv, .ConvRate, .AllConv, .ViewThroughConv] }
   func stats() -> [Statistic]
      { return [.Frequency, .Clicks, .Impressions, .Cost, .Conversions] }
   func searchTermKey() -> String
      { return "Search term" }
}

class SEO: GenericDataSet {
   func inputStats() -> [InputStatistic]
      { return [.Queries, .Clicks, .Impressions, .CTR, .Position] }
   func stats() -> [Statistic]
      { return [.Frequency, .Clicks, .Impressions, .Position] }
   func searchTermKey() -> String
      { return "Queries" }
}

class ASOKeywords: GenericDataSet {
   func inputStats() -> [InputStatistic]
      { return [.Keywords, .SearchScore, .Chance, .TotalApps, .CurrentRank] }
   func stats() -> [Statistic]
      { return [.Frequency, .SearchScore] }
   func searchTermKey() -> String
      { return "Keywords" }
}

class ASODescription: GenericDataSet {
   func inputStats() -> [InputStatistic]
      { return [] }
   func stats() -> [Statistic]
      { return [.Frequency] }
   func generatePhrases(literal: String) -> [String]
      { return generateASODescriptionPhrases(literal) }
   func searchTermKey() -> String
      { return "" }

}



func isPPC(inHeader: [String]) -> Bool {
   if (headersAreEqual(inHeader, comparisonHeader: ppcHeader)) { return true }
   return false
}

func isSEO(inHeader: [String]) -> Bool {
   if (headersAreEqual(inHeader, comparisonHeader: seoHeader)) { return true }
   return false
}

func isASO(inHeader: [String]) -> Bool {
   if (headersAreEqual(inHeader, comparisonHeader: asoHeader)) { return true }
   return false
}

func isASODescription(inHeader: [String]) -> Bool {
   if (inHeader.count == 1) { return true }
   return false
}

func headersAreEqual(inputHeader: [String], comparisonHeader: [String]) -> Bool {
   var seenStat: Bool = false
   for comparisonStat in comparisonHeader {
      for stat in inputHeader {
         if stat == comparisonStat {seenStat = true}
      }
      if !seenStat {return false}
   }
   return true
}

func factoryData(header: [String]) -> GenericDataSet? {
   if (isPPC(header))               { return PPC() }
   else if isSEO(header)            { return SEO() }
   else if isASO(header)            { return ASOKeywords() }
   else if isASODescription(header) { return ASODescription() }
   else { print("error matching stat type")
         return nil }
}
