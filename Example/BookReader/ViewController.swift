//
//  ViewController.swift
//  BookReader
//
//  Created by jiaxianhua on 07/20/2018.
//  Copyright (c) 2018 jiaxianhua. All rights reserved.
//

import UIKit
import BookReader
import PDFKit

class ViewController: UIViewController {
    let titles = ["Book Shelf", "Open Sample Pdf"]

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(documentDirectoryDidChange(_:)), name: .documentDirectoryDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = titles[indexPath.row];
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let path = Bundle(identifier: "org.cocoapods.BookReader")?.path(forResource: "BookReader", ofType: "bundle") {
            let bundle = Bundle(path: path)
            let storyboard = UIStoryboard.init(name: "BookReader", bundle: bundle)
            
            switch indexPath.row {
            case 0:
                let bookshelfViewController: BookshelfViewController! = storyboard.instantiateViewController(withIdentifier: "BookshelfViewController") as! BookshelfViewController
                self.show(bookshelfViewController, sender: nil)
                break
            default:
                let bookViewController: BookViewController! = storyboard.instantiateViewController(withIdentifier: "BookViewController") as! BookViewController
                
                let fileManager = FileManager.default
                let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let contents = try! fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                let documents = contents.compactMap { PDFDocument(url: $0) }
                if documents.count > 0 {
                    let document = documents.last!
                    bookViewController.pdfDocument = document
                }
                self.show(bookViewController, sender: nil)
                
                break
            }
        }
    }
    
    @objc func documentDirectoryDidChange(_ notification: Notification) {
        if self.navigationController?.topViewController == self {
            if let path = Bundle(identifier: "org.cocoapods.BookReader")?.path(forResource: "BookReader", ofType: "bundle") {
                let bundle = Bundle(path: path)
                let storyboard = UIStoryboard.init(name: "BookReader", bundle: bundle)
                
                let bookshelfViewController: BookshelfViewController! = storyboard.instantiateViewController(withIdentifier: "BookshelfViewController") as! BookshelfViewController
                self.show(bookshelfViewController, sender: nil)
            }
        }
    }
}
