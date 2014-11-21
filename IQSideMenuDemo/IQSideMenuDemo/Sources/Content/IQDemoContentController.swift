//
//  IQDemoContentController.swift
//  IQSideMenuDemo
//
//  Created by Alexander Orlov on 21/11/14.
//  Copyright (c) 2014 Alexander Orlov. All rights reserved.
//

import UIKit

class IQDemoContentController: UIViewController {

    var sideMenu: IQSideMenuController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openSideMenu() {
        sideMenu?.openMenu(true);
    }
    
    @IBAction func closeSideMenu() {
        sideMenu?.closeMenu(true);
    }
    
    @IBAction func toggleSideMenu() {
        sideMenu?.toggleMenu(true);
    }
}
