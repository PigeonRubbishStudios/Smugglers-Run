//
//  WinScene.swift
//  LaserGuidedWarSharks
//
//  Created by Kyle Bolinger on 4/27/18.
//  Copyright © 2018 Pigeon Rubbish Studios. All rights reserved.
//

import Foundation
import SpriteKit

class WinScene: SKScene
{
    var shaders = [ShaderExample]()
    var currentShader = 0
    var countDownTimer = 5
    var timer = Timer()
    typealias ShaderExample = (title: String, shader: SKShader)
    let gameOverLabel = SKLabelNode(fontNamed: "OptimusPrincepsSemiBold")
    let countDownLabel = SKLabelNode(fontNamed: "OptimusPrincepsSemiBold")
    let gameOverLabel2 = SKLabelNode(fontNamed: "OptimusPrincepsSemiBold")
    let countDownLabel2 = SKLabelNode(fontNamed: "OptimusPrincepsSemiBold")
    let textColor = SKColor(red: 251.0/255.0, green: 204.0/255.0, blue: 51.0/255.0, alpha: 1.0)
    
    override func didMove(to view: SKView)
    {
        createBackground()
        createOverlay()
        
        let wait = SKAction.wait(forDuration: TimeInterval(countDownTimer))
        let block = SKAction.run
        {
            let myScene = MainMenuScene(size: self.size)
            myScene.scaleMode = self.scaleMode
            self.view?.presentScene(myScene)
        }
        self.run(SKAction.sequence([wait, block]))
    }
    
    func createOverlay()
    {
        let overlayTexture = SKTexture(imageNamed: "overlay")
        let overlayNode = SKSpriteNode(texture: overlayTexture)
        overlayNode.alpha = 1
        overlayNode.zPosition = -40
        overlayNode.position = CGPoint(x: 768, y: 1024)
        addChild(overlayNode)
        
        let rightBuoyTexture = SKTexture(imageNamed: "buoy")
        let leftBuoyTexture = SKTexture(imageNamed: "buoy2")
        let rightBuoyNode = SKSpriteNode(texture: rightBuoyTexture)
        rightBuoyNode.zPosition = -30
        rightBuoyNode.anchorPoint = CGPoint.zero
        rightBuoyNode.position = CGPoint(x: 1374, y: 0)
        addChild(rightBuoyNode)
        let leftBuoyNode = SKSpriteNode(texture: leftBuoyTexture)
        leftBuoyNode.zPosition = -30
        leftBuoyNode.anchorPoint = CGPoint.zero
        leftBuoyNode.position = CGPoint(x: -380, y: 0)
        addChild(leftBuoyNode)
    }
    
    func createBackground()
    {
        let waterTexture = SKTexture(imageNamed: "water")
        let waterNode = SKSpriteNode(texture: waterTexture)
        waterNode.zPosition = -50
        waterNode.position = CGPoint(x: 768, y: 1024)
        addChild(waterNode)
        
        shaders.append(("Water", createWater()))
        let example = shaders[currentShader]
        waterNode.shader = example.shader
        waterNode.setValue(SKAttributeValue(size: waterTexture.size()), forAttribute: "a_size")
        
        //Set Up Text Label
        gameOverLabel.text = "Winner, Winner, Rum for Dinner!"
        gameOverLabel.fontColor = textColor
        gameOverLabel.fontSize = 90
        gameOverLabel.position = CGPoint(x: 768, y: 1042)
        gameOverLabel.zPosition = 110
        
        gameOverLabel2.text = "Winner, Winner, Rum for Dinner!"
        gameOverLabel2.fontColor = SKColor.black
        gameOverLabel2.fontSize = 90
        gameOverLabel2.position = CGPoint(x: 763, y: 1037)
        gameOverLabel2.zPosition = 105
        
        countDownLabel.text = "Returning to Main Menu in \(countDownTimer) Seconds"
        countDownLabel.fontColor = textColor
        countDownLabel.fontSize = 60
        countDownLabel.position = CGPoint(x: 768, y: 968)
        countDownLabel.zPosition = 110
        
        countDownLabel2.text = "Returning to Main Menu in \(countDownTimer) Seconds"
        countDownLabel2.fontColor = SKColor.black
        countDownLabel2.fontSize = 60
        countDownLabel2.position = CGPoint(x: 763, y: 963)
        countDownLabel2.zPosition = 105
        
        //Add Text Label
        addChild(gameOverLabel)
        addChild(countDownLabel)
        addChild(gameOverLabel2)
        addChild(countDownLabel2)
    }
    
    //Function to Create Water Effect Shader
    func createWater() -> SKShader
    {
        let uniforms: [SKUniform] =
            [
                SKUniform(name: "u_speed", float: 3), //Water Speed
                SKUniform(name: "u_strength", float: 2.5), //Water Strength
                SKUniform(name: "u_frequency", float: 10) //Water Frequency
        ]
        return SKShader(fromFile: "SHKWater", uniforms: uniforms)
    }
}
