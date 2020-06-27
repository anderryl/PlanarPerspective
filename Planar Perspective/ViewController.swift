//
//  ViewController.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 5/16/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let level = LevelView.init(frame: view.frame)
        view.addSubview(level)
    }


}

