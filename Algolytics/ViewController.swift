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
   func perfomOperationForDraggedFiles(_ files: [String])
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
      self.progressField!.isEditable = false
      self.progressField!.textColor! = NSColor.blue()
      NSUserNotificationCenter.default().delegate = self
   }
   
   //***********************************************************************
   override var representedObject: AnyObject? {
      didSet {
      // Update the view, if already loaded.
      }
   }
   
   //**********************************************************************
   func userNotificationCenter(_ center: NSUserNotificationCenter,
                                         shouldPresent notification: NSUserNotification) -> Bool {
      return true
   }
   
   //**********************************************************************
   func display(_ progress: Progress) {
      DispatchQueue.main.async {
         print(progress)
         self.progressField!.stringValue = progress.displayText
      }
   }

   //**********************************************************************
   func displayDoneNotification() {
      DispatchQueue.main.async { 
         let notification = NSUserNotification()
         notification.title = "Computation Done!"
         notification.informativeText = "Your Aggregate Data is Ready for Export"
         notification.soundName = NSUserNotificationDefaultSoundName
         NSUserNotificationCenter.default().deliver(notification)
      }
   }
   
   //***********************************************************************
   @IBAction func exportFile(_ sender: AnyObject) {
      let myFileDialog: NSSavePanel = NSSavePanel()
      myFileDialog.title = "Export CSV File"
      myFileDialog.runModal()
      
      guard let url = myFileDialog.url else {
         return
      }
      
      let exportFilePath = try! url.appendingPathExtension("csv")
      writeResultsToOuputCSV(exportFilePath)
   }
   
   
   // MARK: Class Methods
   
   // writes our findings to the output .csv file
   // here we don't have to worry about the .csv extension...that is taken
   //    care of in the outputFilePath
   //***********************************************************************
   func writeResultsToOuputCSV(_ outputFilePath: URL) {
      let finalCSV = computer!.generateOuputCSV().data(using: String.Encoding.utf8)
      do {
         try finalCSV?.write(to: outputFilePath, options: NSData.WritingOptions.dataWritingAtomic)
      }
      catch {
         print("error in writing to .csv file")
      }
   }
   
   
   //***********************************************************************
   @IBAction func helpButtonPressed(_ sender: AnyObject) {
         // Implement
   }
   
   //***********************************************************************
   @IBAction func openCSVFromFileDidPress(_ sender: AnyObject) {
      let myFileDialog: NSOpenPanel = NSOpenPanel()
      myFileDialog.runModal()
      // Get the path to the file chosen in the NSOpenPanel
      guard let path = myFileDialog.url?.path else {
         return
      }
      
      let url = URL(fileURLWithPath: path)
      
      do {
         display(Progress.loading)
         let contents = try String(contentsOf: url, encoding: String.Encoding.ascii)
         inputCSV = CSV(string: contents, loadColumns: true)
         //print("success loading .csv file")
      } catch {
         print("error")
         display(Progress.loadingFailed)
         return
      }
      
      computer =  ComputerModel(inputCSV: inputCSV!, viewController: self)
      //computer!.cleanCSV()
      display(Progress.loadingComplete)
   }
   
   //***********************************************************************
   @IBAction func algolyticizeDidPress(_ sender: AnyObject) {
      DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes(rawValue: UInt64(Int(UInt64(DispatchQueueAttributes.qosDefault.rawValue))))).async {
         self.computer!.compute()
      }
   }                    
}

extension ViewController: FileDraggingProtocol {
   func perfomOperationForDraggedFiles(_ files: [String]) {
      // load the CSVs in question
      guard let filePath = files.first else { return }
      let url = URL(fileURLWithPath: filePath)
      
      do {
         try inputCSV = CSV(url: url, delimiter: ",", encoding: String.Encoding.utf8, loadColumns: true)
         //print("success loading .csv file")
      }
      catch {
         //print("error in reading from input .csv file")
         return
      }
      computer =  ComputerModel(inputCSV: inputCSV!, viewController: self)
   }
}

