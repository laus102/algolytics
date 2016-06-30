//
//  ComputerExtension.swift
//  Algolytics
//
//  Created by Brendan Lau on 6/16/16.
//  Copyright © 2016 Incipia. All rights reserved.
//



import Foundation

enum Progress {
   case Loading
   case LoadingComplete
   case Generating
   case Computing
   case LoadingFailed
   case Complete
   
   var displayText: String {
      switch self {
      case .Loading: return "File Loading..."
      case .LoadingComplete: return "File Loading Complete.  Press The Button..."
      case .Generating: return "Phrases Being Generated..."
      case .Computing: return "Computation in Progress..."
      case .LoadingFailed: return "File Loading Failed.  Please Try Again."
      case .Complete: return ""
      }
   }
}

//var updateStatisticQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
var backgroundQueue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
var updateStatisticQueue = dispatch_queue_create("com.inicipia.algolytics.fuck", DISPATCH_QUEUE_CONCURRENT)

extension ComputerModel {
   
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
   
func wholePhraseOccursInSearchTerm( inout phrase: String, inout searchTerm: String) -> Bool {
   let separatedSearchTerm: [String] = searchTerm.characters.split(" ").map { String($0) } //searchTerm.componentsSeparatedByString(" ")
   let separatedPhrase: [String] = phrase.characters.split(" ").map { String($0) }// phrase.componentsSeparatedByString(" ")
   
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
   func dispatchSegmentUpdates(inout segments: [ [String : [Statistic : Double]] ]) {
      //let computationQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
      guard var rows = inputCSV?.rows else { return }
      parentVC!.display(Progress.Computing)
      let computationGroup = dispatch_group_create()
         for each in segments { // slice by slice of the original searchTerms array
            //print("\(each)\n")
            var emptyDict = [String : [Statistic : Double]]()
            segmentsSearchTerms.append(emptyDict)
            print("entering group")
            dispatch_group_enter(computationGroup)
            var this = each
            dispatch_async(backgroundQueue, {
               self.updateSegmentStatistics(&this, rows: &rows, dict: &emptyDict) // update stats for this row
               print("leaving group")
               dispatch_group_leave(computationGroup)
            })
         }
      
      dispatch_group_notify(computationGroup, updateStatisticQueue) {
         for dictionary in self.segmentsSearchTerms {
            print(dictionary)
            print("\n\n")
         }
         
         self.mergeSegments()
         self.parentVC!.displayDoneNotification()
         self.parentVC!.display(Progress.Complete)
      }
   }
   
   // merges the individual segments' statistics into the original searchTerms dictionary
   //*************************************************************************
   func mergeSegments() {
      print("merging")
      let stats = dataSet!.stats()
      for statsDict in segmentsSearchTerms { // unique segment's stat list
         for searchTerm in statsDict {       // each term in the segment
            for statistic in stats { // each statistic for the appropriate dataset
               if (statistic == Statistic.Frequency)
                  { continue }
               let statValue = statsDict[searchTerm.0]![statistic]!
               searchTerms[searchTerm.0]![statistic] = statValue
            }
            
         }
      }
   }
}

