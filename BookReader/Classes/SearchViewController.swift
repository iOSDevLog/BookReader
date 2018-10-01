//
//  SearchViewController.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/03.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit
import PDFKit

public class SearchViewController: UITableViewController, UISearchBarDelegate, PDFDocumentDelegate {
    var pdfDocument: PDFDocument?
    weak var delegate: SearchViewControllerDelegate?

    var searchBar = UISearchBar()
    var searchResults = [PDFSelection]()

    deinit {
        pdfDocument?.cancelFindString()
        pdfDocument?.delegate = nil
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.searchBarStyle = .minimal
        tableView.tableFooterView = UIView()
        navigationItem.titleView = searchBar

        let bundle = Bundle.bookReader
        tableView.rowHeight = 88
        tableView.register(UINib(nibName: String(describing: SearchResultsCell.self), bundle: bundle), forCellReuseIdentifier: "Cell")
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchBar.becomeFirstResponder()
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true, completion: nil)
    }

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        pdfDocument?.delegate = nil
        pdfDocument?.cancelFindString()

        let searchText = searchBar.text!.trimmingCharacters(in: CharacterSet.whitespaces)
        if searchText.count >= 3 {
            searchResults.removeAll()
            tableView.reloadData()
            pdfDocument?.delegate = self
            pdfDocument?.beginFindString(searchText, withOptions: .caseInsensitive)
        }
    }

    public func didMatchString(_ instance: PDFSelection) {
        searchResults.append(instance)
        tableView.reloadData()
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Text"
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SearchResultsCell

        let selection = searchResults[indexPath.row]

        let extendedSelection = selection.copy() as! PDFSelection
        extendedSelection.extendForLineBoundaries()

        let outline = pdfDocument?.outlineItem(for: selection)
        cell.section = outline?.label

        let page = selection.pages[0]
        cell.page = page.label

        cell.resultText = extendedSelection.string
        cell.searchText = selection.string

        return cell
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selection = searchResults[indexPath.row]
        searchBar.resignFirstResponder()
        delegate?.searchViewController(self, didSelectSearchResult: selection)
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true, completion: nil)
    }
}

protocol SearchViewControllerDelegate: class {
    func searchViewController(_ searchViewController: SearchViewController, didSelectSearchResult selection: PDFSelection)
}
