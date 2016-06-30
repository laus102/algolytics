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
   case campaign, matchType, searchTerm, addedExcluded, adGroup, clicks, impressions, ctr, avgCPC, cost,
        avgPosition, conversions, costConv, convRate, allConv, viewThroughConv, queries, position, keywords,
        searchScore, chance, totalApps, currentRank
   
   var stringValue: String {
      switch self {
      case .campaign: return kCampaign
      case .matchType: return kMatchType
      case .searchTerm: return kSearchTerm
      case .addedExcluded: return kAddedExcluded
      case .adGroup: return kAdGroup
      case .clicks:    return kClicks
      case .impressions: return kImpressions
      case .ctr: return kCTR
      case .avgCPC: return kAvgCPC
      case .cost: return kCost
      case .avgPosition: return kAvgPosition
      case .conversions: return kConversions
      case .costConv: return kCostConv
      case .convRate: return kConvRate
      case .allConv: return kAllConv
      case .viewThroughConv: return kViewThroughConv
      case .queries: return kQueries
      case .position: return kPosition
      case .keywords: return kKeywords
      case .searchScore: return kSearchScore
      case .chance: return kChance
      case .totalApps: return kTotalApps
      case .currentRank: return kCurrentRanks
      }
   }
}

enum Statistic {
   case frequency, clicks, impressions, cost, conversions, searchScore, position
   
   var stringValue: String {
      switch self {
         case .frequency: return kFrequency
         case .clicks:    return kClicks
         case .impressions: return kImpressions
         case .cost: return kCost
         case .conversions: return kConversions
         case .searchScore: return kSearchScore
         case .position: return kPosition
      }
   }
}

protocol GenericDataSet {
   func inputStats() -> [InputStatistic]
   func stats() -> [Statistic]
   func searchTermKey() -> String
   func EmptyStatsDict() -> [Statistic : Double]
   func generatePhrases(_ literal: String)-> [String]
}

private let kWhitespaceAndNewlineCharacterSet = CharacterSet.whitespacesAndNewlines

extension GenericDataSet {
   func EmptyStatsDict() -> [Statistic : Double] {
      var emptyStatsDict: [Statistic : Double] = [:]
      
      let stats = self.stats()
      for each in stats
      { emptyStatsDict[each] = 0.0 }
      
      return emptyStatsDict
   }
   
   func generatePhrases(_ literal: String) -> [String] {
      let phrase = literal.components(separatedBy: " ")
      var newTerms: [String] = []
      var tempString = ""
      
      for i in 0 ..< phrase.count { // for each word "i" in original literal "phrase"
         for j in i ..< phrase.count { // start at word "i" and increment through the remaining words
            tempString += "\(phrase[j]) "       // at each iteration, add the new word "j" to the temp string
            newTerms.append(tempString.trimmingCharacters(
               in: kWhitespaceAndNewlineCharacterSet))   // add this new permutation to the array of generated phrases
         }
         tempString = "" // reset the temp String after generating terms for each iteration of word "i"
      }
      return newTerms
   }
}


class PPC: GenericDataSet {
   
   let PPCInputStats: [InputStatistic] = [.campaign, .matchType, .searchTerm, .addedExcluded, .adGroup,
                        .clicks, .impressions, .ctr, .avgCPC, .cost, .avgPosition,
                        .conversions, .costConv, .convRate, .allConv, .viewThroughConv]
   let PPCStats: [Statistic] = [.frequency, .clicks, .impressions, .cost, .conversions]
   
   func inputStats() -> [InputStatistic] {
        return PPCInputStats }
   func stats() -> [Statistic]
      { return PPCStats }
   func searchTermKey() -> String
      { return kSearchTerm }
}

class SEO: GenericDataSet {
   func inputStats() -> [InputStatistic]
      { return [.queries, .clicks, .impressions, .ctr, .position] }
   func stats() -> [Statistic]
      { return [.frequency, .clicks, .impressions, .position] }
   func searchTermKey() -> String
      { return kQueries }
}

class ASOKeywords: GenericDataSet {
   func inputStats() -> [InputStatistic]
      { return [.keywords, .searchScore, .chance, .totalApps, .currentRank] }
   func stats() -> [Statistic]
      { return [.frequency, .searchScore] }
   func searchTermKey() -> String
      { return kKeywords }
}

class ASODescription: GenericDataSet {
   func inputStats() -> [InputStatistic]
      { return [] }
   func stats() -> [Statistic]
      { return [.frequency] }
   func generatePhrases(_ literal: String) -> [String]
      { return generateASODescriptionPhrases(literal) }
   func searchTermKey() -> String
      { return kEmptyString }

}



func isPPC(_ inHeader: [String]) -> Bool {
   if (headersAreEqual(inHeader, comparisonHeader: ppcHeader)) { return true }
   return false
}

func isSEO(_ inHeader: [String]) -> Bool {
   if (headersAreEqual(inHeader, comparisonHeader: seoHeader)) { return true }
   return false
}

func isASO(_ inHeader: [String]) -> Bool {
   if (headersAreEqual(inHeader, comparisonHeader: asoHeader)) { return true }
   return false
}

func isASODescription(_ inHeader: [String]) -> Bool {
   if (inHeader.count == 1) { return true }
   return false
}


func headersAreEqual(_ inputHeader: [String], comparisonHeader: [String]) -> Bool {
   var seenStat: Bool = false
   for stat in inputHeader {
      for comparisonStat in comparisonHeader {
         if stat == comparisonStat {seenStat = true}
      }
      if !seenStat {return false}
   }
   return true
}


func factoryData(_ header: [String]) -> GenericDataSet? {
   if (isPPC(header))               { return PPC() }
   else if isSEO(header)            { return SEO() }
   else if isASO(header)            { return ASOKeywords() }
   else if isASODescription(header) { return ASODescription() }
   else { print("error matching stat type")
         return nil }
}
