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
        //Loads a level from a JSON file
        let test = false
        let level = loadLevel(called: test ? "Recursion" : "Living")
        //let level = loadLevel(called: "TestLevel")
        //Creates and adds a LevelView subview to the view
        let subview = LevelView.init(frame: view.frame, level: level)
        view.addSubview(subview)
    }
    
    //Loads a level by name
    func loadLevel(called name: String) -> Level {
        //Retreives Data
        let data = getFileData(filename: name)!
        //print(NSString(data: data, encoding: 1)!)
        let decoder = JSONDecoder()
        //Loads the data as a Level type
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

