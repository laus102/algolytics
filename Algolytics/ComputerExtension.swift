//
//  ComputerExtension.swift
//  Algolytics
//
//  Created by Brendan Lau on 6/16/16.
//  Copyright © 2016 Incipia. All rights reserved.
//



import Foundation
import SwiftCSV

enum Progress {
   case loading
   case loadingComplete
   case generating
   case computing
   case loadingFailed
   case complete
   
   var displayText: String {
      switch self {
      case .loading: return "File Loading..."
      case .loadingComplete: return "File Loading Complete.  Press The Button..."
      case .generating: return "Phrases Being Generated..."
      case .computing: return "Computation in Progress..."
      case .loadingFailed: return "File Loading Failed.  Please Try Again."
      case .complete: return ""
      }
   }
}

//var updateStatisticQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
//var backgroundQueue = DispatchQueue.global(Int(UInt64(DispatchQueueAttributes.qosUserInitiated.rawValue)), 0)
var backgroundQueue = DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosUserInitiated)
var updateStatisticQueue = DispatchQueue(label: "com.inicipia.algolytics.fuck", attributes: DispatchQueueAttributes.concurrent)

extension ComputerModel {
   
   //************************************************************************
   func splitPhraseList () -> ([ [String : [Statistic : Double]] ]) {
      let uniquePhrases = self.searchTerms
      let numUniquePhrases = Double(uniquePhrases.count)
//      let numberOfQueues = ceil(numUniquePhrases / 1500.0)
      let numberOfSegments = ceil(numUniquePhrases / 3000.0)
      let numberOfPhrasesPerSegment = floor(numUniquePhrases/numberOfSegments)
      var phraseCounter: Int = 0
      var segmentCounter: Int = 0
      var segments: [ [String : [Statistic : Double]] ] = []
      
      for _ in 0..<Int(numberOfSegments) // make NoQ # empty dict entries so we don't access bad indices
         { segments.append([:]) }
      
      for each in uniquePhrases { // for all the unique phrases
         let phrase = each.1
         
         if (phraseCounter <= Int(numberOfPhrasesPerSegment)) // while we are under the 1459 mark
            { phraseCounter += 1 }
         else {
            segmentCounter += 1
            phraseCounter = 0
         }
         segments[segmentCounter][each.0] = phrase
      }
      return segments
   }


// lets us know whether or not the given phrase occurs within the given searchTerm
//  *** ONLY COUNTS WHOLE OCCURENCES OF INPUT PHRASE (I.E. SEPARATED BY WHTIE SPACE)
//     e.x. -->  "PIC" in "PICture" will NOT be counted
//*******************************************************
   
func wholePhraseOccursInSearchTerm( _ phrase: inout String, searchTerm: inout String) -> Bool {
   let separatedSearchTerm: [String] = searchTerm.characters.split(separator: " ").map { String($0) } //searchTerm.componentsSeparatedByString(" ")
   let separatedPhrase: [String] = phrase.characters.split(separator: " ").map { String($0) }// phrase.componentsSeparatedByString(" ")
   
   let separatedPhraseCount = separatedPhrase.count
   let separatedSearchTermCount = separatedSearchTerm.count
   
   if separatedPhraseCount > 1 { //phrase is more than one word
      for i in 0..<separatedSearchTermCount {
         
         var comparisonString = ""
         let suspensionDifferential = separatedSearchTermCount - (i + separatedPhraseCount)
         if (suspensionDifferential >= 0) {
            var counter = i
            for _ in separatedPhrase {
               comparisonString += separatedSearchTerm[counter] + " "
               counter += 1
            }
            
            comparisonString = comparisonString.trimmed
            
            let originalPhrase = phrase.trimmed
            if comparisonString == originalPhrase {
               return true
            }
         }
      }
   }
      
   else { // phrase is only one word
      for j in 0..<separatedSearchTermCount {
         if separatedSearchTerm[j] == phrase
            { return true }
      }
   }
   return false
}
   
   
   //*************************************************************************
   func dispatchSegmentUpdates(_ segments: inout [ [String : [Statistic : Double]] ]) {
      //let computationQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
      guard var rows = inputCSV?.rows else { return }
      parentVC!.display(Progress.computing)
      let computationGroup = DispatchGroup()
         for each in segments { // slice by slice of the original searchTerms array
            var emptyDict = [String : [Statistic : Double]]()
            //segmentsSearchTerms.append(emptyDict)
            print("entering group")
            computationGroup.enter()
            var this = each
            backgroundQueue.async(execute: {
               self.updateSegmentStatistics(&this, rows: &rows, dict: &emptyDict) // update stats for this row
               self.segmentsSearchTerms.append(emptyDict)
               print("leaving group")
               computationGroup.leave()
            })
         }
      
      computationGroup.notify(queue: updateStatisticQueue) {
         self.mergeSegments()
         self.parentVC!.displayDoneNotification()
         self.parentVC!.display(Progress.complete)
      }
   }
   
   // merges the individual segments' statistics into the original searchTerms dictionary
   //*************************************************************************
   func mergeSegments() {
      print("merging")
      let stats = dataSet!.stats()
      for segment in segmentsSearchTerms { // unique segment's stat list
         var segmentCounter = 0
         for searchTerm in segment {       // each term in the segment
            for statistic in stats { // each statistic for the appropriate dataset
               if (statistic == Statistic.frequency)
                  { continue }
               if let statValue = segment[searchTerm.key]?[statistic] {
                  searchTerms[searchTerm.key]![statistic] = statValue
               } else {
                  print("statistic: \(statistic)")
                  print("searchTerm: \(searchTerm.key)")
                  print("segment[searchTerm.key]: \(segment[searchTerm.key])")
                  print("segmentCounter: \(segmentCounter)\n\n")
               }
            }
            segmentCounter += 1
         }
      }
   }
}

