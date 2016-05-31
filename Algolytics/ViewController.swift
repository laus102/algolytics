//
//  ViewController.swift
//  Algolytics
//
//  Created by Brendan Lau on 5/12/16.
//  Copyright © 2016 Incipia. All rights reserved.
//


import Cocoa
import Foundation
import SwiftCSV


let inputFilePath = try! NSFileManager.defaultManager().URLForDirectory(.DesktopDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true).URLByAppendingPathComponent("algolytics input 5.12").URLByAppendingPathExtension("csv")

let outputFilePath = try! NSFileManager.defaultManager().URLForDirectory(.DesktopDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true).URLByAppendingPathComponent("algolytics output sample 5.12").URLByAppendingPathExtension("csv")

let tempOutputFilePath = try! NSFileManager.defaultManager().URLForDirectory(.DesktopDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true).URLByAppendingPathComponent("algolytics temp output").URLByAppendingPathExtension("csv")




class ViewController: NSViewController {
  
   var inputCSV: CSV?
   var computer: ComputerModel? // all algorythmic computation will be done within this object
   
   
   
   // MARK: Lifecycle
   /////////////////////////////////////

   override func viewDidLoad() {
      super.viewDidLoad()
      
      // load the CSVs in question
      do {
         try inputCSV = CSV(url: inputFilePath, delimiter: ",", encoding: NSUTF8StringEncoding, loadColumns: true)
         print("success loading .csv file")
      }
      catch {
         print("error in reading from input .csv file")
      }
      
      computer =  ComputerModel(inputCSV: inputCSV!)
   }

   override var representedObject: AnyObject? {
      didSet {
      // Update the view, if already loaded.
      }
   }
   
   
   
   // MARK: Class Methods
   
   // writes our findings to the output .csv file
   // here we don't have to worry about the .csv extension...that is taken
   //    care of in the outputFilePath
   //***********************************************************************
   func writeResultsToOuputCSV(outputFilePath: NSURL) {
      let finalCSV = computer?.outputCSV.dataUsingEncoding(NSUTF8StringEncoding)
      do {
         try finalCSV?.writeToURL(outputFilePath, options: NSDataWritingOptions.DataWritingAtomic)
      }
      catch {
         print("error in writing to .csv file")
      }
   }
   
   
   //***********************************************************************
   @IBAction func algolyticizeDidPress(sender: AnyObject) {
      self.computer!.compute()
      self.writeResultsToOuputCSV(tempOutputFilePath)
      
   }
}

