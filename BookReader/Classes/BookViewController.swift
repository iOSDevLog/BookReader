//
//  BookViewController.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/03.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit
import PDFKit
import MessageUI
import UIKit.UIGestureRecognizerSubclass

public class BookViewController: UIViewController, UIPopoverPresentationControllerDelegate, PDFViewDelegate, ActionMenuViewControllerDelegate, SearchViewControllerDelegate, ThumbnailGridViewControllerDelegate, OutlineViewControllerDelegate, BookmarkViewControllerDelegate, MFMailComposeViewControllerDelegate {
    @objc public var pdfDocument: PDFDocument?

    @IBOutlet public weak var pdfView: PDFView!
    @IBOutlet weak var pdfThumbnailViewContainer: UIView!
    @IBOutlet public weak var pdfThumbnailView: PDFThumbnailView!
    @IBOutlet private weak var pdfThumbnailViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelContainer: UIView!
    @IBOutlet public weak var pageNumberLabel: UILabel!
    @IBOutlet weak var pageNumberLabelContainer: UIView!
    
    var tableOfContentsToggleSegmentedControl: UISegmentedControl!
    @IBOutlet weak var thumbnailGridViewConainer: UIView!
    @IBOutlet weak var outlineViewConainer: UIView!
    @IBOutlet weak var bookmarkViewConainer: UIView!

    public var bookmarkButton: UIBarButtonItem!
    public var bookmarkButtonSelectedColor: UIColor = UIColor.red
    
    var searchNavigationController: UINavigationController?

    let barHideOnTapGestureRecognizer = UITapGestureRecognizer()
    let pdfViewGestureRecognizer = PDFViewGestureRecognizer()
    
    var bundle: Bundle!
    
    @objc public static func makeFromStoryboard() -> BookViewController
    {
        return UIStoryboard(name: "BookReader", bundle: Bundle.bookReader).instantiateViewController(withIdentifier: "BookViewController") as! BookViewController
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.pdfView.document = pdfDocument

        self.bundle = Bundle.bookReader
        
        self.tableOfContentsToggleSegmentedControl = UISegmentedControl(items: [
            UIImage.init(named: "view_module", in: bundle, compatibleWith: nil)!,
            UIImage.init(named: "list", in: bundle, compatibleWith: nil)!,
            UIImage.init(named: "bookmark_ribbon", in: bundle, compatibleWith: nil)!,
            ])

        NotificationCenter.default.addObserver(self, selector: #selector(pdfViewPageChanged(_:)), name: .PDFViewPageChanged, object: nil)

        self.barHideOnTapGestureRecognizer.addTarget(self, action: #selector(gestureRecognizedToggleVisibility(_:)))
        view.addGestureRecognizer(barHideOnTapGestureRecognizer)

        self.tableOfContentsToggleSegmentedControl.selectedSegmentIndex = 0
        self.tableOfContentsToggleSegmentedControl.addTarget(self, action: #selector(toggleTableOfContentsView(_:)), for: .valueChanged)

        self.pdfView.autoScales = true
        self.pdfView.displayMode = .singlePageContinuous
        self.pdfView.displayDirection = .vertical
//        pdfView.usePageViewController(true, withViewOptions: [UIPageViewController.OptionsKey.interPageSpacing: 20])

        self.pdfView.addGestureRecognizer(pdfViewGestureRecognizer)

        self.pdfThumbnailView.layoutMode = .horizontal
        self.pdfThumbnailView.pdfView = pdfView

        self.titleLabel.text = pdfDocument?.documentAttributes?["Title"] as? String
        self.titleLabelContainer.layer.cornerRadius = 4
        self.pageNumberLabelContainer.layer.cornerRadius = 4

        self.resume()
        
        self.perform(#selector(goToFirstPage), with: nil, afterDelay: 0.1)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.navigationController?.topViewController != self {
            UIApplication.shared.keyWindow?.windowLevel = .normal
            self.presentedViewController?.dismiss(animated: false, completion: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.adjustThumbnailViewHeight()
        
        self.pdfView.autoScales = true
        self.pdfView.layoutDocumentView()
    }

    @objc func goToFirstPage() {
        self.pdfView.goToFirstPage(nil)
    }

    override public func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        
//        self.pdfView.autoScales = true

        coordinator.animate(alongsideTransition: { [weak self] (context) in
            self?.adjustThumbnailViewHeight()

            }, completion: { [weak self] (context) in
                
                self?.pdfView.autoScales = true
                self?.pdfView.layoutDocumentView()

                if self?.pdfThumbnailViewContainer.alpha == 1 {
                    UIApplication.shared.keyWindow?.windowLevel = .normal
                }
                else {
                    self?.hideBars()
                }
        })
    }

    private func adjustThumbnailViewHeight() {
        self.pdfThumbnailViewHeightConstraint.constant = 44 + self.view.safeAreaInsets.bottom
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ThumbnailGridViewController {
            viewController.pdfDocument = pdfDocument
            viewController.delegate = self
        } else if let viewController = segue.destination as? OutlineViewController {
            viewController.pdfDocument = pdfDocument
            viewController.delegate = self
        } else if let viewController = segue.destination as? BookmarkViewController {
            viewController.pdfDocument = pdfDocument
            viewController.delegate = self
        }
    }

    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func actionMenuViewControllerShareDocument(_ actionMenuViewController: ActionMenuViewController) {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self
        if let lastPathComponent = self.pdfDocument?.documentURL?.lastPathComponent,
            let documentAttributes = self.pdfDocument?.documentAttributes,
            let attachmentData = self.pdfDocument?.dataRepresentation() {
            if let title = documentAttributes["Title"] as? String {
                mailComposeViewController.setSubject(title)
            }
            mailComposeViewController.addAttachmentData(attachmentData, mimeType: "application/pdf", fileName: lastPathComponent)
            let presentationBlock: () -> () = { [weak self] in
                self?.present(mailComposeViewController, animated: true, completion: nil)
            }
            if self.presentedViewController != nil {
                self.presentedViewController?.dismiss(animated: true, completion: presentationBlock)
            }
            else {
                presentationBlock()
            }
        }
    }

    func actionMenuViewControllerPrintDocument(_ actionMenuViewController: ActionMenuViewController) {
        let printInteractionController = UIPrintInteractionController.shared
        printInteractionController.printingItem = pdfDocument?.dataRepresentation()
        printInteractionController.present(animated: true, completionHandler: nil)
    }

    @objc func share(from barButtonItem: UIBarButtonItem) {
        
        if let pdfUrl = self.pdfDocument?.documentURL {
            var activityItems: [Any] = [pdfUrl]
            if let title = self.pdfDocument?.documentAttributes?["Title"] as? String {
                activityItems.append(title)
            }
            let activityView = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            activityView.popoverPresentationController?.barButtonItem = barButtonItem
            self.present(activityView, animated: true, completion: nil)
        }
    }
    
    func searchViewController(_ searchViewController: SearchViewController, didSelectSearchResult selection: PDFSelection) {
        selection.color = .yellow
        self.pdfView.currentSelection = selection
        self.pdfView.go(to: selection)
        self.showBars()
    }

    func thumbnailGridViewController(_ thumbnailGridViewController: ThumbnailGridViewController, didSelectPage page: PDFPage) {
        self.resume()
        self.pdfView.go(to: page)
    }

    func outlineViewController(_ outlineViewController: OutlineViewController, didSelectOutlineAt destination: PDFDestination) {
        self.resume()
        self.pdfView.go(to: destination)
    }

    func bookmarkViewController(_ bookmarkViewController: BookmarkViewController, didSelectPage page: PDFPage) {
        self.resume()
        self.pdfView.go(to: page)
    }
    
    //MARK: MFMailComposeViewControllerDelegate
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
       controller.dismiss(animated: true, completion: nil)
    }

    private func resume() {
        let backButton = UIBarButtonItem(image: UIImage.init(named: "back_arrow", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(back(_:)))
        let tableOfContentsButton = UIBarButtonItem(image: UIImage.init(named: "list", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(showTableOfContents(_:)))
        let actionButton = UIBarButtonItem(image: UIImage(named: "action", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(share(from:)))
//        let actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share(from:)))
        navigationItem.leftBarButtonItems = [backButton, tableOfContentsButton, actionButton]

        let brightnessButton = UIBarButtonItem(image: UIImage.init(named: "sun", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(showAppearanceMenu(_:)))
        let searchButton = UIBarButtonItem(image: UIImage.init(named: "search", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(showSearchView(_:)))
//        let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(showSearchView(_:)))
        self.bookmarkButton = UIBarButtonItem(image: UIImage.init(named: "bookmark_ribbon", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(addOrRemoveBookmark(_:)))
        self.navigationItem.rightBarButtonItems = [bookmarkButton, searchButton, brightnessButton]

        self.pdfThumbnailViewContainer.alpha = 1

        self.pdfView.isHidden = false
        self.titleLabelContainer.alpha = self.hasTitle() ? 1 : 0
        self.pageNumberLabelContainer.alpha = 1
        self.thumbnailGridViewConainer.isHidden = true
        self.outlineViewConainer.isHidden = true
        self.bookmarkViewConainer.isHidden = true

        self.barHideOnTapGestureRecognizer.isEnabled = true

        self.updateBookmarkStatus()
        self.updatePageNumberLabel()
    }

    private func hasTitle() -> Bool {
        return self.pdfDocument?.documentAttributes?["Title"] != nil
    }
    
    private func showTableOfContents() {
        self.view.exchangeSubview(at: 0, withSubviewAt: 1)
        self.view.exchangeSubview(at: 0, withSubviewAt: 2)

        let backButton = UIBarButtonItem(image: UIImage.init(named: "back_arrow", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(back(_:)))
        let tableOfContentsToggleBarButton = UIBarButtonItem(customView: tableOfContentsToggleSegmentedControl)
        let resumeBarButton = UIBarButtonItem(title: NSLocalizedString("Resume", comment: ""), style: .done, target: self, action: #selector(resume(_:)))
        self.navigationItem.leftBarButtonItems = [backButton, tableOfContentsToggleBarButton]
        self.navigationItem.rightBarButtonItems = [resumeBarButton]

        self.pdfThumbnailViewContainer.alpha = 0

        self.toggleTableOfContentsView(tableOfContentsToggleSegmentedControl)

        self.barHideOnTapGestureRecognizer.isEnabled = false
    }

    @objc func resume(_ sender: UIBarButtonItem) {
        self.resume()
    }

    @objc func back(_ sender: UIBarButtonItem) {
        UIApplication.shared.keyWindow?.windowLevel = .normal

        if let presentingViewController = self.presentingViewController {
            presentingViewController.dismiss(animated: true, completion: nil)
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc func showTableOfContents(_ sender: UIBarButtonItem) {
        self.showTableOfContents()
    }

    @objc func showActionMenu(_ sender: UIBarButtonItem) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: String(describing: ActionMenuViewController.self)) as? ActionMenuViewController {
            viewController.modalPresentationStyle = .popover
            viewController.preferredContentSize = CGSize(width: 300, height: 88)
            viewController.popoverPresentationController?.barButtonItem = sender
            viewController.popoverPresentationController?.permittedArrowDirections = .up
            viewController.popoverPresentationController?.delegate = self
            viewController.delegate = self
            self.present(viewController, animated: true, completion: nil)
        }
    }

    @objc func showAppearanceMenu(_ sender: UIBarButtonItem) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: String(describing: AppearanceViewController.self)) as? AppearanceViewController {
            viewController.modalPresentationStyle = .popover
            viewController.preferredContentSize = CGSize(width: 300, height: 44)
            viewController.popoverPresentationController?.barButtonItem = sender
            viewController.popoverPresentationController?.permittedArrowDirections = .up
            viewController.popoverPresentationController?.delegate = self
            self.present(viewController, animated: true, completion: nil)
        }
    }

    @objc func showSearchView(_ sender: UIBarButtonItem) {
        if let searchNavigationController = self.searchNavigationController {
            self.present(searchNavigationController, animated: true, completion: nil)
        }
        else if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: String(describing: SearchViewController.self)) as? UINavigationController,
            let searchViewController = navigationController.topViewController as? SearchViewController {
            searchViewController.pdfDocument = pdfDocument
            searchViewController.delegate = self
            self.present(navigationController, animated: true, completion: nil)

            searchNavigationController = navigationController
        }
    }

    @objc func addOrRemoveBookmark(_ sender: UIBarButtonItem) {
        if let documentURL = self.pdfDocument?.documentURL?.absoluteString {
            var bookmarks = UserDefaults.standard.array(forKey: documentURL) as? [Int] ?? [Int]()
            if let currentPage = self.pdfView.currentPage,
                let pageIndex = self.pdfDocument?.index(for: currentPage) {
                if let index = bookmarks.firstIndex(of: pageIndex) {
                    bookmarks.remove(at: index)
                    UserDefaults.standard.set(bookmarks, forKey: documentURL)
                    self.bookmarkButton.image = UIImage.init(named: "bookmark_ribbon", in: bundle, compatibleWith: nil)
                    self.bookmarkButton.tintColor = nil
                } else {
                    UserDefaults.standard.set((bookmarks + [pageIndex]).sorted(), forKey: documentURL)
//                    self.bookmarkButton.image = UIImage.init(named: "bookmark_ribbon", in: bundle, compatibleWith: nil)
                    self.bookmarkButton.tintColor = self.bookmarkButtonSelectedColor
                }
            }
        }
    }

    @objc func toggleTableOfContentsView(_ sender: UISegmentedControl) {
        self.pdfView.isHidden = true
        self.titleLabelContainer.alpha = 0
        self.pageNumberLabelContainer.alpha = 0
        
        if self.tableOfContentsToggleSegmentedControl.selectedSegmentIndex == 0 {
            self.thumbnailGridViewConainer.isHidden = false
            self.outlineViewConainer.isHidden = true
            self.bookmarkViewConainer.isHidden = true
        }
        else if self.tableOfContentsToggleSegmentedControl.selectedSegmentIndex == 1 {
            self.thumbnailGridViewConainer.isHidden = true
            self.outlineViewConainer.isHidden = false
            self.bookmarkViewConainer.isHidden = true
        }
        else {
            self.thumbnailGridViewConainer.isHidden = true
            self.outlineViewConainer.isHidden = true
            self.bookmarkViewConainer.isHidden = false
        }
    }

    @objc func pdfViewPageChanged(_ notification: Notification) {
        if self.pdfViewGestureRecognizer.isTracking {
            self.hideBars()
        }
        self.updateBookmarkStatus()
        self.updatePageNumberLabel()
    }

    @objc func gestureRecognizedToggleVisibility(_ gestureRecognizer: UITapGestureRecognizer) {
        if let navigationController = self.navigationController {
            if navigationController.navigationBar.alpha > 0 {
                self.hideBars()
            } else {
                self.showBars()
            }
        }
    }

    private func updateBookmarkStatus() {
        if let documentURL = self.pdfDocument?.documentURL?.absoluteString,
            let bookmarks = UserDefaults.standard.array(forKey: documentURL) as? [Int],
            let currentPage = self.pdfView.currentPage,
            let index = self.pdfDocument?.index(for: currentPage) {
            self.bookmarkButton.tintColor = bookmarks.contains(index) ? self.bookmarkButtonSelectedColor : nil
        }
    }

    private func updatePageNumberLabel() {
        if let currentPage = self.pdfView.currentPage, let index = self.pdfDocument?.index(for: currentPage), let pageCount = self.pdfDocument?.pageCount {
            self.pageNumberLabel.text = String(format: "%d/%d", index + 1, pageCount)
        } else {
            self.pageNumberLabel.text = nil
        }
    }

    private func showBars() {
        if let navigationController = self.navigationController {
            UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
                UIApplication.shared.keyWindow?.windowLevel = .normal
                navigationController.navigationBar.alpha = 1
                self?.pdfThumbnailViewContainer.alpha = 1
                self?.titleLabelContainer.alpha = self?.hasTitle() ?? false ? 1 : 0
                self?.pageNumberLabelContainer.alpha = 1
                self?.view.setNeedsUpdateConstraints()
                self?.view.updateConstraintsIfNeeded()
            }
        }
    }

    private func hideBars() {
        if let navigationController = self.navigationController {
            UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
                UIApplication.shared.keyWindow?.windowLevel = .statusBar
                navigationController.navigationBar.alpha = 0
                self?.pdfThumbnailViewContainer.alpha = 0
                self?.titleLabelContainer.alpha = 0
                self?.pageNumberLabelContainer.alpha = 0
                self?.view.setNeedsUpdateConstraints()
                self?.view.updateConstraintsIfNeeded()

            }
        }
    }
}

class PDFViewGestureRecognizer: UIGestureRecognizer {
    var isTracking = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        isTracking = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        isTracking = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        isTracking = false
    }
}
