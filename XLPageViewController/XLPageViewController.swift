//
//  XLPageViewController.swift
//  XLPageViewController
//
//  Created by Aibek Dzhakipov on 12/5/16.
//  Copyright © 2016 Dzhakipov. All rights reserved.
//

import UIKit

protocol XLPageViewControllerDataSource: class {
    func numberOfPages(in pageController: XLPageViewController) -> Int
    func viewControllerForPage(at index: Int) -> UIViewController
}

protocol XLPageViewControllerDelegate: class {
    func pageViewControllerDidChangeCurrentPageIndex(pageController: XLPageViewController)
}

class XLPageViewController: UIViewController {
    
    weak var dataSource: XLPageViewControllerDataSource?
    weak var delegate: XLPageViewControllerDelegate?
    /**
     Do no try to change collection view's following properties.
     - data source
     - delegate
     - collectionViewLayout
     - isPagingEnabled
     - allowsSelection
    */
    let collectionView: UICollectionView
    
    /**
     Current page index is index of a page on which collection view completely stopped scrolling,
     i.e. user is not panning collection view and scrolling animations have been finished.
    */
    var currentPageIndex: Int {
        // Should we make this property optional?
        // If not, what should we return when controller has 0 pages?
        set {
            guard isViewLoaded else { return }
            scrollToPage(at: newValue, animated: false)
        } get {
            return _currentPageIndex
        }
    }
    
    // Should we make this property optional?
    // If not, what should we return when controller has 0 pages?
    // Or when there was no previous current page (e.g. right when the view loads)
    fileprivate(set) var previousCurrentPageIndex = 0
    
    /**
     Private variable for keeping track of current page index because
     allowing to set it directly messes calculation of current page index,
     which should happen only in didStopScrolling().
    */
    fileprivate var _currentPageIndex = 0
    fileprivate var isScrolling: Bool = false
    fileprivate let cellReuseIdentifier = "XLPageCell"
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        collectionView.register(XLPageCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.allowsSelection = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        stretch(collectionView, in: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
        if collectionView.numberOfItems(inSection: 0) > 0 {
            scrollToPage(at: currentPageIndex, animated: false)
        }
    }
    
    func reloadData() {
        collectionView.reloadData()
    }
    
    func scrollToPage(at index: Int, animated: Bool = true) {
        let itemsCount = collectionView.numberOfItems(inSection: 0)
        precondition(itemsCount > 0, "Index out of range")
        precondition((0..<itemsCount).contains(index), "Index out of range")
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        if !animated {
            didStopScrolling()
        }
    }
}

extension XLPageViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfPages(in: self) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! XLPageCell
        cell.viewController = dataSource?.viewControllerForPage(at: indexPath.item)
        return cell
    }
}

extension XLPageViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? XLPageCell, let child = cell.viewController else { return }
        addChildViewController(child)
        cell.contentView.addSubview(child.view)
        stretch(child.view, in: cell.contentView)
        child.didMove(toParentViewController: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? XLPageCell, let child = cell.viewController else { return }
        child.willMove(toParentViewController: nil)
        child.view.removeFromSuperview()
        child.didMove(toParentViewController: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}

extension XLPageViewController: UIScrollViewDelegate {
    // scroll detection logic taken from http://stackoverflow.com/a/8010066/4934534
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        didStartScrolling()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            didStopScrolling()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didStopScrolling()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        didStopScrolling()
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        didStopScrolling()
    }
}

fileprivate extension XLPageViewController {
    
    func didStopScrolling() {
        isScrolling = false
        guard collectionView.numberOfItems(inSection: 0) > 0 else { return }
        guard !collectionView.frame.isEmpty else { return }
        
        validateFramesForVisibleCells()
        let newCurrentPageIndex = calculateCurrentPageIndex()
        let newPreviousCurrentPageIndex = _currentPageIndex
        let currentPageIndexChanged = newPreviousCurrentPageIndex != newCurrentPageIndex
        if currentPageIndexChanged {
            previousCurrentPageIndex = _currentPageIndex
            _currentPageIndex = newCurrentPageIndex
            delegate?.pageViewControllerDidChangeCurrentPageIndex(pageController: self)
        }
    }
    
    func didStartScrolling() {
        isScrolling = true
    }
    
    /**
     Do not call this method if collection view has 0 items.
     You must call this method only when collection view stopped scrolling completely.
     Use `isScrolling` property to detect when collection view stopped scrolling.
     */
    func calculateCurrentPageIndex() -> Int {
        let centerPoint = view.convert(view.center, to: collectionView)
        if let centerCellIndexPath = collectionView.indexPathForItem(at: centerPoint) {
            return centerCellIndexPath.item
        } else {
            let signature = "\(type(of: self)).\(#function)"
            debugPrint("\(signature): invalid call. Call this method only when collection view has more than 0 items, completely stopped scrolling and doesn't have an empty frame")
            return 0 // better than a fatal error 🤷‍♂️
        }
    }
    
    func validateFramesForVisibleCells() {
        let indexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in indexPaths {
            guard let cell = collectionView.cellForItem(at: indexPath) else { continue }
            let index = indexPath.item
            let isValidFrame = self.isValidFrame(frame: cell.frame, forPageAt: index)
            if !isValidFrame {
                debugPrint(type(of: self), ": Detected invalid frame for page at index: \(index)")
            }
        }
    }
    
    func isValidFrame(frame: CGRect, forPageAt index: Int) -> Bool {
        let isCorrectXOffset = validXOffsetForPage(at: index) == frame.origin.x
        let isCorrectWidth = validWidthForPage(at: index) == frame.width
        return isCorrectXOffset && isCorrectWidth
    }
    
    func validXOffsetForPage(at index: Int) -> CGFloat {
        return collectionView.bounds.width * CGFloat(index)
    }
    
    func validWidthForPage(at index: Int) -> CGFloat {
        return collectionView.frame.width
    }
    
    func stretch(_ subview: UIView, in superview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        let views = ["subview": subview]
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: [], metrics: nil, views: views))
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: [], metrics: nil, views: views))
    }
}

class XLPageCell: UICollectionViewCell {
    weak var viewController: UIViewController?
}
