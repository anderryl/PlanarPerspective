//
//  InputHandler.swift
//  Planar Perspective
//
//  Created by Anderson, Todd W. on 6/10/20.
//  Copyright © 2020 Anderson, Todd W. All rights reserved.
//

import Foundation
import UIKit

//Delegate class for detecting and handling user input
class InputHandler {
    //The current test point
    private var test: CGPoint?
    private var planeform: CGAffineTransform!
    //Gesture recognizers
    private var left: UISwipeGestureRecognizer!
    private var right: UISwipeGestureRecognizer!
    private var up: UISwipeGestureRecognizer!
    private var down: UISwipeGestureRecognizer!
    private var tap: UITapGestureRecognizer!
    private var pan: UIPanGestureRecognizer!
    private var long: UILongPressGestureRecognizer!
    private var rotation: UIRotationGestureRecognizer!
    private var forward: UISwipeGestureRecognizer!
    private var back: UISwipeGestureRecognizer!
    //Supervisor
    private unowned let level: LevelView
    
    //Initialize delegate with supervisor reference
    init(level: LevelView) {
        self.level = level
        //Setup recognizers
        rotation = UIRotationGestureRecognizer(target: self, action: #selector(rotate(_:)))
        left = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeft))
        right = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight))
        up = UISwipeGestureRecognizer(target: self, action: #selector(swipeUp))
        down = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown))
        tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        long = UILongPressGestureRecognizer(target: self, action: #selector(longed(_:)))
        forward = UISwipeGestureRecognizer(target: self, action: #selector(future))
        back = UISwipeGestureRecognizer(target: self, action: #selector(past))
        long.minimumPressDuration = 0.3
        long.allowableMovement = 30
        pan.require(toFail: up)
        pan.require(toFail: down)
        pan.require(toFail: left)
        pan.require(toFail: right)
        left.direction = .left
        right.direction = .right
        up.direction = .up
        down.direction = .down
        back.direction = .right
        forward.direction = .left
        back.numberOfTouchesRequired = 2
        forward.numberOfTouchesRequired = 2
        planeform = CGAffineTransform()
        
        for rec in [up, down, right, left, tap, long, pan, rotation, back, forward] {
            rec!.cancelsTouchesInView = false
            level.addGestureRecognizer(rec!)
        }
    }
    
    //Called when a leftward swipe is detected
    @objc func swipeLeft() {
        level.logic.attemptTransition(direction: .LEFT)
    }
    
    //Called when a rightward swipe is detected
    @objc func swipeRight() {
        level.logic.attemptTransition(direction: .RIGHT)
    }
    
    //Called when a upward swipe is detected
    @objc func swipeUp() {
        level.logic.attemptTransition(direction: .DOWN)
    }
    
    //Called when a downward swipe is detected
    @objc func swipeDown() {
        level.logic.attemptTransition(direction: .UP)
    }
    
    @objc func future() {
        print("BACK TO THE FUTURE")
    }
    
    @objc func past() {
        print("BACK TO THE PAST")
    }
    
    //Called when a tap gesture is detected
    @objc func tapped(_ recognizer: UITapGestureRecognizer) {
        let loc = recognizer.location(in: level)
        touch(level.matrix.unfold(point: loc.applying(planeform), onto: level.position))
    }
    
    //Called when a pan gesture is detected. Tests if still active; attempts move if ended.
    @objc func pan(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.numberOfTouches > 2 {
            let loc = recognizer.location(in: level)
            test(touch: loc.applying(planeform))
            if recognizer.state == .ended {
                touch(level.matrix.unfold(point: loc.applying(planeform), onto: level.position))
            }
        }
    }
    
    //Called when a long press is detected. Tests if still active; attempts move if ended.
    @objc func longed(_ recognizer: UILongPressGestureRecognizer) {
        let loc = recognizer.location(in: level)
        test(touch: loc.applying(planeform))
        if recognizer.state == .ended {
            touch(level.matrix.unfold(point: loc.applying(planeform), onto: level.position))
        }
    }
    
    @objc func rotate(_ recognizer: UIRotationGestureRecognizer) {
        if abs(recognizer.rotation) > 3.14159 / 4 {
            if recognizer.rotation > 0 {
                level.logic.attemptTwist(rotation: .COUNTER)
            }
            else {
                level.logic.attemptTwist(rotation: .CLOCKWISE)
            }
        }
    }
    
    //Set the test point
    func test(touch: CGPoint) {
        test = touch
    }
    
    //Reset the test point
    func nixTest() {
        test = nil
    }
    
    //Retreive the test point
    func getTest() -> CGPoint? {
        return test
    }
    
    //Decides whether a tap gesture will be processed
    func allowTap() -> Bool {
        for rec in [left, right, up, down] {
            if !(rec!.state == UIGestureRecognizer.State.ended || rec!.state == UIGestureRecognizer.State.failed || rec!.state == UIGestureRecognizer.State.cancelled) {
                return false
            }
        }
        return false
    }
    
    //Attempts a movement following a touch
    func touch(_ touch: Position) {
        test = nil
        level.logic.attemptMove(to: touch)
    }
    
    func update(_ planeform: CGAffineTransform) {
        self.planeform = planeform
    }
}
