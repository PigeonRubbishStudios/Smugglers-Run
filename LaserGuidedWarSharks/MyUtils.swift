//
//  MyUtils.swift
//  LaserGuidedWarSharks
//
//  Created by Bolinger, Kyle D on 3/29/18.
//  Copyright © 2018 HLAD Studios. All rights reserved.
//

import Foundation
import CoreGraphics
import SpriteKit

func + (left: CGPoint, right: CGPoint) -> CGPoint
{
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func += (left: inout CGPoint, right: CGPoint)
{
    left = left + right
}

func - (left: CGPoint, right: CGPoint) -> CGPoint
{
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func -= (left: inout CGPoint, right: CGPoint)
{
    left = left - right
}

func * (left: CGPoint, right: CGPoint) -> CGPoint
{
    return CGPoint(x: left.x * right.x, y: left.y * right.y)
}

func *= (left: inout CGPoint, right: CGPoint)
{
    left = left * right
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint
{
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func *= (point: inout CGPoint, scalar: CGFloat)
{
    point = point * scalar
}

func / (left: CGPoint, right: CGPoint) -> CGPoint
{
    return CGPoint(x: left.x / right.x, y: left.y / right.y)
}

func /= ( left: inout CGPoint, right: CGPoint)
{
    left = left / right
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint
{
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

func /= (point: inout CGPoint, scalar: CGFloat)
{
    point = point / scalar
}

#if !(arch(x86_64) || arch(arm64))
    func atan2(y: CGFloat, x: CGFloat) -> CGFloat
    {
        return CGFloat(atan2f(Float(y), Float(x)))
    }
    
    func sqrt(a: CGFloat) -> CGFloat
    {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint
{
    
    func length() -> CGFloat
    {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint
    {
        return self / length()
    }
    
    var angle: CGFloat
    {
        return atan2(y, x)
    }
}

let π = CGFloat.pi

func shortestAngleBetween(angle1: CGFloat,
                          angle2: CGFloat) -> CGFloat
{
    let twoπ = π * 2.0
    var angle = (angle2 - angle1)
        .truncatingRemainder(dividingBy: twoπ)
    if angle >= π
    {
        angle = angle - twoπ
    }
    if angle <= -π
    {
        angle = angle + twoπ
    }
    return angle
}

extension CGFloat
{
    func sign() -> CGFloat
    {
        return self >= 0.0 ? 1.0 : -1.0
    }
}

extension CGFloat
{
    static func random() -> CGFloat
    {
        return CGFloat(Float(arc4random()) / Float(UInt32.max))
    }
    
    static func random(min: CGFloat, max: CGFloat) -> CGFloat
    {
        assert(min < max)
        return CGFloat.random() * (max - min) + min
    }
}

func randomNum(_ n:Int) -> Int
{
    return Int(arc4random_uniform(UInt32(n)))
}

extension SKNode
{
    func rotateVersus(destPoint: CGPoint, durationRotation: TimeInterval, durationMove: TimeInterval)
    {
        let v1 = CGVector(dx:0, dy:1)
        //let v2 = CGVector(dx:destPoint.x - position.x, dy: destPoint.y - position.y)
        let v2 = CGVector(dx:destPoint.x - position.x, dy: destPoint.y - position.y)
        let angle = atan2(v2.dy, v2.dx) - atan2(v1.dy, v1.dx)
        let finalAngle = angle - CGFloat(Double.pi/2)
        
        //let rotate = SKAction.rotate(toAngle: finalAngle * 360, duration: durationRotation)
        let rotate = SKAction.rotate(toAngle: finalAngle, duration: durationRotation)
        //let move = SKAction.move(by: CGVector(dx: v2.dx * 0.9, dy: v2.dy * 0.9), duration: durationMove)
        let sequence = SKAction.sequence([rotate])
        self.run(sequence)
    }
}
