//
//  ViewController.swift
//  Algolytics
//
//  Created by Brendan Lau on 5/12/16.
//  Copyright © 2016 Incipia. All rights reserved.
//


import Cocoa
import Foundation
import AppKit
import SwiftCSV

protocol FileDraggingProtocol {
   func perfomOperationForDraggedFiles(files: [String])
}

class ViewController: NSViewController, NSUserNotificationCenterDelegate {
  
   var inputCSV: CSV?
   var computer: ComputerModel? // all algorythmic computation will be done within this object
   var notificationCenter: NSUserNotificationCenter?
   
   @IBOutlet var draggableView: DraggableView! {
      didSet {
         draggableView.draggingDelegate = self
      }
   }
   
   @IBOutlet weak var progressField: NSTextField!
   
   // MARK: Lifecycle
   /////////////////////////////////////

   override func viewDidLoad() {
      super.viewDidLoad()
      self.progressField!.editable = false
      self.progressField!.textColor! = NSColor.blueColor()
      NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
   }
   
   //***********************************************************************
   override var representedObject: AnyObject? {
      didSet {
      // Update the view, if already loaded.
      }
   }
   
   //**********************************************************************
   func userNotificationCenter(center: NSUserNotificationCenter,
                                         shouldPresentNotification notification: NSUserNotification) -> Bool {
      return true
   }
   
   //**********************************************************************
   func display(progress: Progress) {
      dispatch_async(dispatch_get_main_queue()) {
         print(progress)
         self.progressField!.stringValue = progress.displayText
      }
   }

   //**********************************************************************
   func displayDoneNotification() {
      dispatch_async(dispatch_get_main_queue()) { 
         let notification = NSUserNotification()
         notification.title = "Computation Done!"
         notification.informativeText = "Your Aggregate Data is Ready for Export"
         notification.soundName = NSUserNotificationDefaultSoundName
         NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
      }
   }
   
   //***********************************************************************
   @IBAction func exportFile(sender: AnyObject) {
      let myFileDialog: NSSavePanel = NSSavePanel()
      myFileDialog.title = "Export CSV File"
      myFileDialog.runModal()
      
      guard let url = myFileDialog.URL else {
         return
      }
      
      let exportFilePath = url.URLByAppendingPathExtension("csv")
      writeResultsToOuputCSV(exportFilePath!)
   }
   
   
   // MARK: Class Methods
   
   // writes our findings to the output .csv file
   // here we don't have to worry about the .csv extension...that is taken
   //    care of in the outputFilePath
   //***********************************************************************
   func writeResultsToOuputCSV(outputFilePath: NSURL) {
      print(computer!.statsUpdateCounter)
      let finalCSV = computer!.generateOuputCSV().dataUsingEncoding(NSUTF8StringEncoding)
      do {
         try finalCSV?.writeToURL(outputFilePath, options: NSDataWritingOptions.DataWritingAtomic)
      }
      catch {
         print("error in writing to .csv file")
      }
   }
   
   
   //***********************************************************************
   @IBAction func helpButtonPressed(sender: AnyObject) {
         // Implement
   }
   
   //***********************************************************************
   @IBAction func openCSVFromFileDidPress(sender: AnyObject) {
      let myFileDialog: NSOpenPanel = NSOpenPanel()
      myFileDialog.runModal()
      // Get the path to the file chosen in the NSOpenPanel
      guard let path = myFileDialog.URL?.path else {
         return
      }
      
      let url = NSURL(fileURLWithPath: path)
      
      do {
         display(Progress.Loading)
         try inputCSV = CSV(url: url, delimiter: ",", encoding: NSASCIIStringEncoding, loadColumns: true)
         //print("success loading .csv file")
      } catch {
         print("ok")
         //display(Progress.LoadingFailed)
         return
      }
      
      computer =  ComputerModel(inputCSV: inputCSV!, viewController: self)
      //computer!.cleanCSV()
      display(Progress.LoadingComplete)
   }
   
   //***********************************************************************
   @IBAction func algolyticizeDidPress(sender: AnyObject) {
      dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) { 
         self.computer!.compute()
      }
   }
}

extension ViewController: FileDraggingProtocol {
   func perfomOperationForDraggedFiles(files: [String]) {
      // load the CSVs in question
      guard let filePath = files.first else { return }
      let url = NSURL(fileURLWithPath: filePath)
      
      do {
         try inputCSV = CSV(url: url, delimiter: ",", encoding: NSUTF8StringEncoding, loadColumns: true)
         //print("success loading .csv file")
      }
      catch {
         //print("error in reading from input .csv file")
         return
      }
      computer =  ComputerModel(inputCSV: inputCSV!, viewController: self)
   }
}

