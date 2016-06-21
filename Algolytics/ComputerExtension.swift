//
//  ComputerExtension.swift
//  Algolytics
//
//  Created by Brendan Lau on 6/16/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

import Foundation

//var updateStatisticQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
var backgroundQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
var updateStatisticQueue = dispatch_queue_create("com.inicipia.algolytics.fuck", DISPATCH_QUEUE_CONCURRENT)

extension ComputerModel {
   
   func splitPhraseList () -> [ [String : [Statistic : Double]] ] {
      let uniquePhrases = self.searchTerms
      let numUniquePhrases = Double(uniquePhrases.count)
      let numberOfQueues = ceil(numUniquePhrases / 1500.0) // 15
      let numberOfPhrasesPerQueue = floor(numUniquePhrases/numberOfQueues) // 1459
      var phraseCounter: Int = 0
      var queueCounter: Int = 0
      var queues: [ [String : [Statistic : Double]] ] = []
      
      for _ in 0..<Int(numberOfQueues) // make NoQ # empty dict entries so we don't access bad indices
         { queues.append([:]) }
      
      for each in uniquePhrases { // for all the unique phrases // 21,894
         let phrase = each.1
         
         if (phraseCounter <= Int(numberOfPhrasesPerQueue)) // while we are under the 1459 mark
            { phraseCounter += 1 }
         else {
            queueCounter += 1
            phraseCounter = 0
         }
         
         queues[queueCounter][each.0] = phrase
         
      }
      return queues
   }



// lets us know whether or not the given phrase occurs within the given searchTerm
//  *** ONLY COUNTS WHOLE OCCURENCES OF INPUT PHRASE (I.E. SEPARATED BY WHTIE SPACE)
//     e.x. -->  "PIC" in "PICture" will NOT be counted
//*******************************************************
   
func wholePhraseOccursInSearchTerm(inout phrase: String, inout searchTerm: String) -> Bool {
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
   
   // FIX ME:
   // 1) MEMORY STILL LEAKS AFTER COMPUTATION IS DONE
   // 2) STATS ARE WRONG / NOT BEING COPIED BACK UP THROUGH THE CHAIN
   
   
   func dispatchSegmentUpdates(inout segments: [ [String : [Statistic : Double]] ]) {
      //let computationQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
      
      guard var rows = inputCSV?.rows else { return }
      
      let computationGroup = dispatch_group_create()
   
      
         for each in segments {
            print("entering group")
            dispatch_group_enter(computationGroup)
            var this = each
               //self.updateSegmentStatistics(&this, queue: computationQueue)
               dispatch_async(backgroundQueue, {
                  self.updateSegmentStatistics(&this, rows: &rows)
                  print("leaving group")
                  dispatch_group_leave(computationGroup)
               })
         }
      
      dispatch_group_notify(computationGroup, updateStatisticQueue) {
         print("you're not done unless you're in the oven")
         return
      }
   }
   
      
      //
      //      for each in segments {
      //         var this = each
      //         dispatch_async(computationQueue) {
      //            dispatch_group_enter(computationGroup)
      //            self.updateSegmentStatistics(&this, queue: computationQueue)
      //            dispatch_group_leave(computationGroup)
      //         }
      //      }
      //      dispatch_group_notify(computationGroup, dispatch_get_main_queue()) {
      //         return
      //      }
      
   }

