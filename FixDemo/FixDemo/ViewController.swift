//
//  ViewController.swift
//  FixDemo
//
//  Created by 王渊鸥 on 2019/1/30.
//  Copyright © 2019 王渊鸥. All rights reserved.
//

import UIKit
import Fix

class ViewController: UIViewController {
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var view2: UIView!
    @IBOutlet weak var view3: UIView!
    @IBOutlet weak var view4: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view1.fixTop == 200
        view1.fixHeight == 40
        
        view2.fixTop == 200
        view2.fixHeight == 40
        view2.fixWidth == view1.fixWidth
        
        view3.fixTop == 200
        view3.fixHeight == 40
        view3.fixWidth == view1.fixWidth
        
        view4.fixTop == 200
        view4.fixHeight == 40
        view4.fixWidth == view1.fixWidth
        
        try! view.fixH(20, view1, 8, view2, 8, view3, 8, view4, 20)
    }
}

