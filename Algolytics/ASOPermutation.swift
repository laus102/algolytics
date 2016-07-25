//
//  ASOPermutation.swift
//  Algolytics
//
//  Created by Brendan Lau on 7/25/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

import Foundation

struct Stack<Element> {
   var items = [Element]()
   mutating func push(item: Element) {
      items.append(item)
   }
   mutating func pop() -> Element {
      return items.removeLast()
   }
   mutating func rearrange() {
      items.remove(at: 1)
   }
   mutating func newStackWithElementAtFront(ofIndex: Int) {
      let futureFrontItem = items.remove(at: ofIndex)
      items.insert(futureFrontItem, at: items.startIndex)
   }
}


struct Queue<Element> {
   var items = [Element]()
   mutating func push(item: Element) {
      items.append(item)
   }
   mutating func pop() -> Element {
      return items.removeFirst()
   }
}

extension ASODescriptionObject {
   
   //**********************************************************
   func stackGenerator(index: Int, strings: [String] ) -> Stack<String> {
      var newStack = Stack<String>()
      
      for i in (0...strings.count-1).reversed() {
         if i == index { continue }
         newStack.push(item: strings[i])
      }
      newStack.push(item: strings[index])
      return newStack
   }
   
   //**********************************************************
   func queueGenerator(index: Int, strings: [String] ) -> Queue<String> {
      var newQueue = Queue<String>()
      
      for i in (0...strings.count-1).reversed() {
         if i == index { continue }
         newQueue.push(item: strings[i])
      }
      newQueue.push(item: strings[index])
      return newQueue
   }
   
   
   //**********************************************************
   func genPerms(words: [String]) -> [String] {
      var permutations = [String]()
      for word in words { permutations.append(word) } // add the singletons
      
      for i in 0...words.count-1 {
         let newStack = stackGenerator(index: i, strings: words)
         for length in 2...3
         { permutations += generatePermutations(ofPermLength: length, stack: newStack) }
      }
      return permutations
   }
   
   //**********************************************************
   func generatePermutations(ofPermLength: Int, stack: Stack<String>) -> [String] {
      var permutations = [String]()
      var newStack = stack
      var numSwaps = Int()
      
      if ofPermLength == 1 { return stack.items }
      
      for i in 0...stack.items.count - 1 { // generate permutations for each member of the stack
         var digitStack = Stack<String>()
         newStack.newStackWithElementAtFront(ofIndex: i)
         digitStack.items = newStack.items //      1 2 3 4 5 ---> 2 1 3 4 5
         
         if ofPermLength == 2 {
            for k in 1...newStack.items.count - 1 {
               let newString = newStack.items[0] + " " + newStack.items[k]
               permutations.append(newString)
            }
            continue
         }
         
         numSwaps = (newStack.items.count - 2) * 2
         let MAXSPAN = (newStack.items.count - 1) - 2 // the max number of indices we will have to span
         for SPAN in 0...MAXSPAN { // start with 0 span, all the way to MAX
            if (1+SPAN <= newStack.items.count - 1) { // span is still in bounds
               
               for j in 0..<numSwaps { // generates all permutations for the first number in given newStack
                  let operationIndex = newStack.items.index(after: newStack.items.startIndex) //start at 2nd index
                  let swapIndex = newStack.items.index(operationIndex, offsetBy: SPAN + 1)
                  
                  if swapIndex <= newStack.items.count - 1 {
                     if j % 2 != 0 { // odd index
                        addNewPermutationOf(length: ofPermLength, span: SPAN, array: newStack.items, permutations: &permutations)
                        swap(&newStack.items[operationIndex], &newStack.items[swapIndex])
                        newStack.rearrange()
                     }
                     else {         // even index
                        addNewPermutationOf(length: ofPermLength, span: SPAN, array: newStack.items, permutations: &permutations)
                        swap(&newStack.items[operationIndex], &newStack.items[swapIndex])
                     }
                  }
                  else { break }
               }
            }
            numSwaps -= 2
            newStack = digitStack
         }
      }
      return permutations
   }
   
   //**********************************************************
   func addNewPermutationOf(length: Int, span: Int, array: [String], permutations: inout [String]) {
      var permString = ""
      for i in 0...length-1  {
         if length > 2 && i == 2 {
            permString += array[i + span] + " "
         }
         else { permString += array[i] + " " }
      }
      permutations.append(permString.trimmed)
   }
}
