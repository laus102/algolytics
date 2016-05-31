//
//  DraggableView.swift
//  Algolytics-Prototype
//
//  Created by Gregory Klein on 9/15/15.
//  Copyright (c) 2015 Sparkhouse. All rights reserved.
//

import Cocoa


class DraggableView: NSView
{
   var draggingDelegate: FileDraggingProtocol!
   
   required init?(coder: NSCoder)
   {
      super.init(coder: coder)
      self.registerForDraggedTypes([NSFilenamesPboardType])
   }
   
   override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation
   {
      return .Copy
   }
   
   override func performDragOperation(sender: NSDraggingInfo) -> Bool
   {
      var performDragOperation = false
      let pasteBoard = sender.draggingPasteboard()
      if let files = pasteBoard.propertyListForType(NSFilenamesPboardType) as? [String]
      {
         draggingDelegate?.perfomOperationForDraggedFiles(files)
         performDragOperation = true
      }
      
      return performDragOperation
   }
}
