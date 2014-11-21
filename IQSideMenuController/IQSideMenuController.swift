//
//  IQSideMenuController.swift
//  IQSideMenu
//
//  Copyright © 2014 Orlov Alexander
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import UIKit

class IQSideMenuController: UIViewController, UIScrollViewDelegate {
    //MARK: Built-in menuViewWidthCalculators
    class MenuViewWidthCalculators {
        //keeps constant width in absolute (pixels)
        class func constantCalculator(constantWidth: CGFloat) -> (sideMenuControllerWidth: CGFloat) -> CGFloat {
            return {(sideMenuControllerWidth: CGFloat) -> CGFloat in
                if ((constantWidth > 0.0) && (constantWidth < sideMenuControllerWidth)) {
                    return constantWidth
                }
                
                return sideMenuControllerWidth * Internal.initialMenuWidthPercentOfScreenMinimumWidth
            }
        }
        
        //keeps constant dependence of menuWidth from parent width
        class func percentCalculator(percent: CGFloat) -> (sideMenuControllerWidth: CGFloat) -> CGFloat {
            return {(sideMenuControllerWidth: CGFloat) -> CGFloat in
                if (percent < 1.0) && (percent > 0.0) {
                    return sideMenuControllerWidth * percent
                }
                
                return sideMenuControllerWidth * Internal.initialMenuWidthPercentOfScreenMinimumWidth
            }
        }
    }
    
    //MARK: Internal
    private struct Internal {
        static let initialMenuWidthPercentOfScreenMinimumWidth: CGFloat = 0.85
    }
    
    //MARK: iVars
    var menuViewController: UIViewController? {
        willSet {
            newValue?.removeFromParentViewController()
            newValue?.view.removeFromSuperview()
        }
        didSet {
            oldValue?.view.removeFromSuperview()
            if (self.isViewLoaded()) {
                self.insertMenuView()
            }
        }
    }
    var contentViewController: UIViewController? {
        willSet {
            newValue?.removeFromParentViewController()
            newValue?.view.removeFromSuperview()
        }
        didSet {
            oldValue?.view.removeFromSuperview()
            if (self.isViewLoaded()) {
                self.insertContentView()
            }
        }
    }
    
    //MARK: Interface
    func openMenu(animated: Bool) {
        self.scrollableView?.setContentOffset(CGPoint(x: 0.0, y: self.scrollableView!.contentOffset.y), animated: animated);
    }
    
    func closeMenu(animated: Bool) {
        self.scrollableView?.setContentOffset(CGPoint(x: self.menuViewController!.view.bounds.size.width, y: self.scrollableView!.contentOffset.y), animated: animated);
    }
    
    func toggleMenu(animated: Bool) {
        if (self.scrollableView != nil) {
            if (self.currentPercentOfAnimation == 0.0) {
                self.closeMenu(animated)
            } else {
                self.openMenu(animated)
            }
        }
    }
    
    var menuViewWidthCalculationClosure: (sideMenuControllerWidth: CGFloat) -> CGFloat = MenuViewWidthCalculators.percentCalculator(Internal.initialMenuWidthPercentOfScreenMinimumWidth)
    var progressTrackingClosure: ((progress: CGFloat) -> ())?
    var animationClosure: ((progress: CGFloat, menuView: UIView?, contentView: UIView?) -> ())?
    private  var scrollableView: IQSideMenuScroller?
    private  var currentPercentOfAnimation: CGFloat = 1.0
    
    //MARK: Init
    private func designedInit() {
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    private func commonInit() {
        //
    }
    
    //MARK: UIViewController Lifecycle
    override init() {
        super.init()
        self.designedInit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.designedInit()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.designedInit()
    }
    
    override func loadView() {
        //create main view
        self.view = UIView(frame: UIScreen.mainScreen().applicationFrame)
        self.view.clipsToBounds = true
        self.view.backgroundColor = UIColor.blackColor()
        self.view.autoresizingMask = UIViewAutoresizing.None
        
        //create scroller
        self.scrollableView = IQSideMenuScroller(frame: self.view.bounds)
        self.scrollableView!.clipsToBounds = false
        self.scrollableView!.showsHorizontalScrollIndicator = false
        self.scrollableView!.showsVerticalScrollIndicator = false
        self.scrollableView!.backgroundColor = UIColor.clearColor()
        self.scrollableView!.pagingEnabled = true
        self.scrollableView!.bounces = false
        self.scrollableView!.directionalLockEnabled = true
        self.scrollableView!.scrollsToTop = false
        self.scrollableView!.autoresizingMask = UIViewAutoresizing.None
        self.scrollableView!.delegate = self
        self.view.addSubview(self.scrollableView!)
        
        //insert external subviews if didn`t yet
        self.insertContentView()
        self.insertMenuView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.commonInit()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions.New, context: nil)
        self.performLayout()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.view.removeObserver(self, forKeyPath: "frame")
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willAnimateRotationToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        self.performLayout()
    }
    
    deinit {
        self.menuViewController = nil;
        self.contentViewController = nil;
        self.scrollableView = nil;
    }
    
    //MARK: Implementation
    private func insertMenuView() {
        if (self.menuViewController == nil) {
            return
        }
        if (contains(self.scrollableView!.subviews as [UIView], self.menuViewController!.view)) {
            return
        }
        self.menuViewController!.view.autoresizingMask = UIViewAutoresizing.None
        self.menuViewController!.view.layer.shouldRasterize = true
        self.menuViewController!.view.layer.rasterizationScale = UIScreen.mainScreen().scale
        self.addChildViewController(self.menuViewController!)
        self.scrollableView!.addSubview(self.menuViewController!.view)
        self.scrollableView!.sendSubviewToBack(self.menuViewController!.view)
        self.performLayout()
    }
    
    private func insertContentView() {
        if (self.contentViewController == nil) {
            return
        }
        if (self.scrollableView == nil) {
            return
        }
        if (contains(self.scrollableView!.subviews as [UIView], self.contentViewController!.view)) {
            return
        }
        self.contentViewController!.view.autoresizingMask = UIViewAutoresizing.None
        self.contentViewController!.view.layer.shouldRasterize = true
        self.contentViewController!.view.layer.rasterizationScale = UIScreen.mainScreen().scale
        self.addChildViewController(self.contentViewController!)
        self.scrollableView!.addSubview(self.contentViewController!.view)
        self.performLayout()
    }
    
    private func updateCurrentPercentOfAnimation() {
        if (self.menuViewController != nil) {
            let menuViewWidth: CGFloat = self.menuViewController!.view.bounds.size.width
            let percentOfAnimation: CGFloat = self.scrollableView!.contentOffset.x/menuViewWidth
            
            self.currentPercentOfAnimation = percentOfAnimation
        }
    }
    
    private func performLayout() {
        let contentViewWidth: CGFloat = self.view.bounds.size.width
        let contentViewHeight: CGFloat = self.view.bounds.size.height
        let menuViewWidth: CGFloat = self.menuViewWidthCalculationClosure(sideMenuControllerWidth: self.view.bounds.size.width)
        let menuViewHeight: CGFloat = self.view.bounds.size.height
        
        let currentContentOffsetX = self.currentPercentOfAnimation * menuViewWidth
        
        let lowerMenuViewXPosition: CGFloat = 0.0
        let upperMenuViewXPosition: CGFloat = menuViewWidth * 0.5
        let menuViewX = lowerMenuViewXPosition + (upperMenuViewXPosition - lowerMenuViewXPosition) * self.currentPercentOfAnimation
        
        self.menuViewController?.view.frame = CGRectMake(menuViewX, 0.0, menuViewWidth, menuViewHeight)
        self.contentViewController?.view.frame = CGRectMake(menuViewWidth, 0.0, contentViewWidth, contentViewHeight)
        
        self.scrollableView?.contentSize = CGSizeMake(menuViewWidth * 2, self.view.bounds.size.height)
        self.scrollableView?.contentOffset = CGPointMake(currentContentOffsetX, 0.0)
        self.scrollableView?.frame = CGRectMake(0, 0, menuViewWidth, self.view.bounds.size.height)
        
        self.performAnimation(self.currentPercentOfAnimation)
    }
    
    private func performAnimation(percentOfAnimation: CGFloat) {
        self.animationClosure?(progress: percentOfAnimation, menuView: self.menuViewController?.view, contentView: self.contentViewController?.view)
    }
    
    //MARK: UIScrollView Delegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.updateCurrentPercentOfAnimation()
        self.performLayout()
        self.progressTrackingClosure?(progress: self.currentPercentOfAnimation)
    }
    
    //MARK: Observes
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if (self.isViewLoaded()) {
            if (object as UIView == self.view) {
                if (keyPath == "frame") {
                    self.performLayout()
                }
            }
        }
    }
}

private class IQSideMenuScroller: UIScrollView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return self.superview!.pointInside(self.convertPoint(point, toView: self.superview!), withEvent: event)
    }
}