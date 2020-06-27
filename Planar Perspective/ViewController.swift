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

    func loadLevel(called name: String) -> Level {
        let data = getFileData(filename: name)!
        print(NSString(data: data, encoding: 1)!)
        let decoder = JSONDecoder()
        return try! decoder.decode(Level.self, from: data)
    }
    
    func getFileData(filename: String) -> Data? {
        if let path = Bundle.main.path(forResource: filename, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                return data
            }
            catch let error {
                print("parse error: \(error.localizedDescription)")
                return nil
            }
        }
        else {
            print("Invalid filename/path.")
            return nil
        }
    }
}

