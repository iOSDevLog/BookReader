//
//  AppDelegate.swift
//  BookReader
//
//  Created by jiaxianhua on 07/20/2018.
//  Copyright (c) 2018 jiaxianhua. All rights reserved.
//

import UIKit
import BookReader

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    fileprivate func prepareDemoFile(_ sampleFilename: String, _ documentDirectory: URL, _ fileManager: FileManager) {
        if let sampleFile = Bundle.main.url(forResource: sampleFilename, withExtension: nil) {
            let destination = documentDirectory.appendingPathComponent(sampleFilename)
            if !fileManager.fileExists(atPath: destination.path) {
                try? fileManager.copyItem(at: sampleFile, to: destination)
            }
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let files = ["Sample.pdf", "ML_A4.pdf"]
        
        for file in files {
            prepareDemoFile(file, documentDirectory, fileManager)
        }
        
        if let launchOptions = launchOptions, let url = launchOptions[.url] as? URL {
            let destination = documentDirectory.appendingPathComponent(url.lastPathComponent)
            if !fileManager.fileExists(atPath: destination.path) {
                try? fileManager.copyItem(at: url, to: destination)
                NotificationCenter.default.post(name: .documentDirectoryDidChange, object: nil)
            }
        }
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination = documentDirectory.appendingPathComponent(url.lastPathComponent)
        if !fileManager.fileExists(atPath: destination.path) {
            try? fileManager.copyItem(at: url, to: destination)
            NotificationCenter.default.post(name: .documentDirectoryDidChange, object: nil)
        }
        return true
    }
}
