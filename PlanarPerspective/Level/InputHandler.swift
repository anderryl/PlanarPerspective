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
    //Gesture recognizers
    private var left: UISwipeGestureRecognizer!
    private var right: UISwipeGestureRecognizer!
    private var up: UISwipeGestureRecognizer!
    private var down: UISwipeGestureRecognizer!
    private var tap: UITapGestureRecognizer!
    private var pan: UIPanGestureRecognizer!
    private var long: UILongPressGestureRecognizer!
    //Supervisor
    private unowned let level: LevelView
    
    //Initialize delegate with supervisor reference
    init(level: LevelView) {
        self.level = level
        //Setup recognizers
        left = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeft))
        right = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight))
        up = UISwipeGestureRecognizer(target: self, action: #selector(swipeUp))
        down = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown))
        tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        long = UILongPressGestureRecognizer(target: self, action: #selector(long(_: )))
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
        for rec in [up, down, right, left, tap, long, pan] {
            rec!.cancelsTouchesInView = false
            level.addGestureRecognizer(rec!)
        }
    }
    
    //Called when a leftward swipe is detected
    @objc func swipeLeft() {
        //Attempts transition depending on plane
        switch level.plane {
        case .FRONT:
            attemptTransition(from: .FRONT, to: .RIGHT)
        case .BACK:
            attemptTransition(from: .BACK, to: .LEFT)
        case .LEFT:
            attemptTransition(from: .LEFT, to: .FRONT)
        case .RIGHT:
            attemptTransition(from: .RIGHT, to: .BACK)
        case .TOP:
            attemptTransition(from: .TOP, to: .LEFT)
        case .BOTTOM:
            attemptTransition(from: .BOTTOM, to: .RIGHT)
        }
    }
    
    //Called when a rightward swipe is detected
    @objc func swipeRight() {
        //Attempts transition depending on plane
        switch level.plane {
        case .FRONT:
            attemptTransition(from: .FRONT, to: .LEFT)
        case .BACK:
            attemptTransition(from: .BACK, to: .RIGHT)
        case .LEFT:
            attemptTransition(from: .LEFT, to: .BACK)
        case .RIGHT:
            attemptTransition(from: .RIGHT, to: .FRONT)
        case .TOP:
            attemptTransition(from: .TOP, to: .RIGHT)
        case .BOTTOM:
            attemptTransition(from: .BOTTOM, to: .LEFT)
        }
    }
    
    //Called when a upward swipe is detected
    @objc func swipeUp() {
        //Attempts transition depending on plane
        switch level.plane {
        case .FRONT:
            attemptTransition(from: .FRONT, to: .BOTTOM)
        case .BACK:
            attemptTransition(from: .BACK, to: .BOTTOM)
        case .LEFT:
            attemptTransition(from: .LEFT, to: .BOTTOM)
        case .RIGHT:
            attemptTransition(from: .RIGHT, to: .BOTTOM)
        case .TOP:
            attemptTransition(from: .TOP, to: .FRONT)
        case .BOTTOM:
            attemptTransition(from: .BOTTOM, to: .BACK)
        }
    }
    
    //Called when a downward swipe is detected
    @objc func swipeDown(_ recognizer: UISwipeGestureRecognizer) {
        //Attempts transition depending on plane
        switch level.plane {
        case .FRONT:
            attemptTransition(from: .FRONT, to: .TOP)
        case .BACK:
            attemptTransition(from: .BACK, to: .TOP)
        case .LEFT:
            attemptTransition(from: .LEFT, to: .TOP)
        case .RIGHT:
            attemptTransition(from: .RIGHT, to: .TOP)
        case .TOP:
            attemptTransition(from: .TOP, to: .BACK)
        case .BOTTOM:
            attemptTransition(from: .BOTTOM, to: .FRONT)
        }
    }
    
    //Called when a tap gesture is detected
    @objc func tap(_ recognizer: UITapGestureRecognizer) {
        let loc = recognizer.location(in: level)
        touch(transform(loc))
    }
    
    //Called when a pan gesture is detected. Tests if still active; attempts move if ended.
    @objc func pan(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.numberOfTouches > 2 {
            let loc = recognizer.location(in: level)
            test(touch: transform(loc))
            if recognizer.state == .ended {
                touch(transform(loc))
            }
        }
    }
    
    //Called when a long press is detected. Tests if still active; attempts move if ended.
    @objc func long(_ recognizer: UILongPressGestureRecognizer) {
        let loc = recognizer.location(in: level)
        test(touch: transform(loc))
        if recognizer.state == .ended {
            touch(transform(loc))
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
    
    //Attempts a transition between planes
    func attemptTransition(from initial: Plane, to final: Plane) {
        level.logic.attemptTransition(from: initial, to: final)
    }
    
    //Attempts a movement following a touch
    func touch(_ touch: CGPoint) {
        test = nil
        level.logic.attemptMove(to: touch)
    }
    
    //Retreives the current position transformation based on player location and current plane
    func transform(_ point: CGPoint) -> CGPoint {
        let player = ProjectionHandler.compress(vertex: level.position, onto: level.plane)
        return CGPoint(x: point.x + player.x - level.frame.width / 2, y: point.y + player.y - level.frame.height / 2)
    }
}
