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

let kCampaign = "Campaign"
let kMatchType = "Match type"
let kSearchTerm = "Search term"
let kAddedExcluded = "Added/Excluded"
let kAdGroup = "Ad group"
let kClicks = "Clicks"
let kImpressions = "Impressions"
let kCTR = "CTR"
let kAvgCPC = "Avg. CPC"
let kCost = "Cost"
let kAvgPosition = "Avg. position"
let kConversions = "Conversions"
let kCostConv = "Cost / conv."
let kConvRate = "Conv. rate"
let kAllConv = "All conv."
let kViewThroughConv = "View-through conv."
let kQueries = "Queries"
let kPosition = "Position"
let kKeywords = "Keywords"
let kSearchScore = "Search Score"
let kChance = "Chance"
let kTotalApps = "Total Apps"
let kCurrentRanks = "Current Ranks"

let kFrequency = "Frequency"
let kEmptyString = ""


//*************************************************************************

enum InputStatistic {
   case Campaign, MatchType, SearchTerm, AddedExcluded, AdGroup, Clicks, Impressions, CTR, AvgCPC, Cost,
        AvgPosition, Conversions, CostConv, ConvRate, AllConv, ViewThroughConv, Queries, Position, Keywords,
        SearchScore, Chance, TotalApps, CurrentRank
   
   var stringValue: String {
      switch self {
      case .Campaign: return kCampaign
      case .MatchType: return kMatchType
      case .SearchTerm: return kSearchTerm
      case .AddedExcluded: return kAddedExcluded
      case .AdGroup: return kAdGroup
      case .Clicks:    return kClicks
      case .Impressions: return kImpressions
      case .CTR: return kCTR
      case .AvgCPC: return kAvgCPC
      case .Cost: return kCost
      case .AvgPosition: return kAvgPosition
      case .Conversions: return kConversions
      case .CostConv: return kCostConv
      case .ConvRate: return kConvRate
      case .AllConv: return kAllConv
      case .ViewThroughConv: return kViewThroughConv
      case .Queries: return kQueries
      case .Position: return kPosition
      case .Keywords: return kKeywords
      case .SearchScore: return kSearchScore
      case .Chance: return kChance
      case .TotalApps: return kTotalApps
      case .CurrentRank: return kCurrentRanks
      }
   }
}

enum Statistic {
   case Frequency, Clicks, Impressions, Cost, Conversions, SearchScore, Position
   
   var stringValue: String {
      switch self {
         case .Frequency: return kFrequency
         case .Clicks:    return kClicks
         case .Impressions: return kImpressions
         case .Cost: return kCost
         case .Conversions: return kConversions
         case .SearchScore: return kSearchScore
         case .Position: return kPosition
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

private let kWhitespaceAndNewlineCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

extension GenericDataSet {
   func EmptyStatsDict() -> [Statistic : Double] {
      var emptyStatsDict: [Statistic : Double] = [:]
      
      let stats = self.stats()
      for each in stats
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
               kWhitespaceAndNewlineCharacterSet))   // add this new permutation to the array of generated phrases
         }
         tempString = "" // reset the temp String after generating terms for each iteration of word "i"
      }
      return newTerms
   }
}


class PPC: GenericDataSet {
   
   let PPCInputStats: [InputStatistic] = [.Campaign, .MatchType, .SearchTerm, .AddedExcluded, .AdGroup,
                        .Clicks, .Impressions, .CTR, .AvgCPC, .Cost, .AvgPosition,
                        .Conversions, .CostConv, .ConvRate, .AllConv, .ViewThroughConv]
   let PPCStats: [Statistic] = [.Frequency, .Clicks, .Impressions, .Cost, .Conversions]
   
   func inputStats() -> [InputStatistic] {
        return PPCInputStats }
   func stats() -> [Statistic]
      { return PPCStats }
   func searchTermKey() -> String
      { return kSearchTerm }
}

class SEO: GenericDataSet {
   func inputStats() -> [InputStatistic]
      { return [.Queries, .Clicks, .Impressions, .CTR, .Position] }
   func stats() -> [Statistic]
      { return [.Frequency, .Clicks, .Impressions, .Position] }
   func searchTermKey() -> String
      { return kQueries }
}

class ASOKeywords: GenericDataSet {
   func inputStats() -> [InputStatistic]
      { return [.Keywords, .SearchScore, .Chance, .TotalApps, .CurrentRank] }
   func stats() -> [Statistic]
      { return [.Frequency, .SearchScore] }
   func searchTermKey() -> String
      { return kKeywords }
}

class ASODescription: GenericDataSet {
   func inputStats() -> [InputStatistic]
      { return [] }
   func stats() -> [Statistic]
      { return [.Frequency] }
   func generatePhrases(literal: String) -> [String]
      { return generateASODescriptionPhrases(literal) }
   func searchTermKey() -> String
      { return kEmptyString }

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
   }
   return seenStat
}

func factoryData(header: [String]) -> GenericDataSet? {
   if (isPPC(header))               { return PPC() }
   else if isSEO(header)            { return SEO() }
   else if isASO(header)            { return ASOKeywords() }
   else if isASODescription(header) { return ASODescription() }
   else { print("error matching stat type")
         return nil }
}
