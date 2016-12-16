//
//  ViewController.swift
//  XLPageViewController
//
//  Created by Aibek Dzhakipov on 12/5/16.
//  Copyright © 2016 Dzhakipov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, XLPageViewControllerDataSource, XLPageViewControllerDelegate {
    
    let pageController = XLPageViewController()
    let controllers: [ChildController] = {
        return (0...4).map { (index) -> ChildController in
            let controller = ChildController()
            controller.label.text = String(index)
            return controller
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewController(pageController)
        view.addSubview(pageController.view)
        stretch(pageController.view, in: view)
        pageController.didMove(toParentViewController: self)
        
        pageController.dataSource = self
        pageController.delegate = self
        pageController.reloadData()
        pageController.currentPageIndex = 3
    }
    
    @IBAction func randomPageButtonPressed(_ sender: Any) {
        scrollToRandomPage()
    }
    
    func scrollToRandomPage(animated: Bool = true) {
        guard !controllers.isEmpty else { return }
        while true {
            let randomIndex = Int.random(modulo: controllers.count)
            guard randomIndex != pageController.currentPageIndex else { continue }
            pageController.scrollToPage(at: randomIndex, animated: animated)
            break
        }
    }
    
    func numberOfPages(in pageController: XLPageViewController) -> Int {
        return controllers.count
    }
    
    func viewControllerForPage(at index: Int) -> UIViewController {
        return controllers[index]
    }
    
    func pageViewControllerDidChangeCurrentPageIndex(pageController: XLPageViewController) {
//        print("current page index changed from: \(pageController.previousCurrentPageIndex) to: \(pageController.currentPageIndex)")
    }
}

class ChildController: UIViewController {
    let label = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        label.font = UIFont.systemFont(ofSize: 30)
        label.textColor = .black
        label.textAlignment = .center
        view.addSubview(label)
        stretch(label, in: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        printFunction(function: #function)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        printFunction(function: #function)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        printFunction(function: #function)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        printFunction(function: #function)
    }
    
    func printFunction(function: String) {
//        print(function, ", index: ", label.text!)
    }
}

fileprivate func stretch(_ subview: UIView, in superview: UIView) {
    subview.translatesAutoresizingMaskIntoConstraints = false
    let views = ["subview": subview]
    superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: [], metrics: nil, views: views))
    superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: [], metrics: nil, views: views))
}

extension Int {
    static func random(modulo: Int? = nil) -> Int {
        guard let modulo = modulo else { return Int(arc4random()) }
        return Int(arc4random_uniform(UInt32(modulo)))
    }
}
