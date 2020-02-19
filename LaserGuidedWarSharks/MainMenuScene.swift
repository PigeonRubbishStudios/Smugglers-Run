//
//  MainMenuScene.swift
//  LaserGuidedWarSharks
//
//  Created by Kyle Bolinger on 4/10/18.
//  Copyright © 2018 Pigeon Rubbish Studios. All rights reserved.
//

import Foundation
import SpriteKit
import CoreGraphics

class MainMenuScene: SKScene
{
    var logo: SKSpriteNode!
    var backgroundMusic: SKAudioNode!
    var shaders = [ShaderExample]()
    var currentShader = 0
    typealias ShaderExample = (title: String, shader: SKShader)
    let playLabel = SKLabelNode(fontNamed: "OptimusPrincepsSemiBold")
    let playLabel2 = SKLabelNode(fontNamed: "OptimusPrincepsSemiBold")
    let versionLabel = SKLabelNode(fontNamed: "OptimusPrincepsSemiBold")
    let versionLabel2 = SKLabelNode(fontNamed: "OptimusPrincepsSemiBold")
    let gameLabel = SKLabelNode(fontNamed: "OptimusPrincepsSemiBold")
    let textColor = SKColor(red: 251.0/255.0, green: 204.0/255.0, blue: 51.0/255.0, alpha: 1.0)
    //let touchNote = SKLabelNode(fontNamed: "Helvetica-Bold")
    
    override func didMove(to view: SKView)
    {
        createBackground()
        createOverlay()
        
        if let musicURL = Bundle.main.url(forResource: "srMusicTitleScreen", withExtension: "wav")
        {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
        
        let playButton = SKSpriteNode(imageNamed: "playButton")
        playButton.name = "playButton"
        playButton.position = CGPoint(x: 768, y: 625)
        playButton.zPosition = 110
        addChild(playButton)
        
        let scaleUp = SKAction.scale(by: 1.6, duration: 3.5)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence(
            [scaleUp, scaleDown, scaleUp, scaleDown])
        let moveForever = SKAction.repeatForever(fullScale)
        
        playButton.run(moveForever)
    }
    
    func sceneTapped()
    {
        let myScene = GameScene(size: size)
        myScene.scaleMode = scaleMode
        //let reveal = SKTransition.fade(withDuration: 1.5)
        view?.presentScene(myScene)
    }

//    override func touchesBegan(_ touches: Set<UITouch>,
//                               with event: UIEvent?)
//    {
//        sceneTapped()
//    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        let touch = touches.first
        let positionInScene = touch!.location(in: self)
        let touchedNode = self.atPoint(positionInScene)
        
        if let name = touchedNode.name
        {
            if name == "playButton"
            {
                sceneTapped()
            }
        }
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
//        let date = Date()
//        let formatter = DateFormatter()
//        formatter.dateFormat = "M.d.yy"
//        let versionDate = formatter.string(from: date)
        
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
        playLabel.text = "Tap to Play!"
        playLabel2.text = "Tap to Play!"
        versionLabel.text = "Version: 1.2"
        versionLabel2.text = "Version: 1.2"
        //gameLabel.text = "Smuggler's Run"
        //touchNote.text = "Note: To Move Shark, Touch and Drag on the Top Portion of the iPad Screen Only!"
        playLabel.fontColor = textColor
        versionLabel.fontColor = textColor
        playLabel2.fontColor = SKColor.black
        versionLabel2.fontColor = SKColor.black
        //gameLabel.fontColor = SKColor.red
        //touchNote.fontColor = SKColor.red
        playLabel.fontSize = 125
        versionLabel.fontSize = 45
        playLabel2.fontSize = 125
        versionLabel2.fontSize = 45
        //gameLabel.fontSize = 225
        //touchNote.fontSize = 30
        playLabel.position = CGPoint(x: 768, y: 542)
        versionLabel.position = CGPoint(x: 768, y: 350)
        playLabel2.position = CGPoint(x: 763, y: 537)
        versionLabel2.position = CGPoint(x: 763, y: 345)
        //gameLabel.position = CGPoint(x: 768, y: 1708)
        //touchNote.position = CGPoint(x: 768, y: 942)
        playLabel.zPosition = 110
        versionLabel.zPosition = 110
        playLabel2.zPosition = 105
        versionLabel2.zPosition = 105
        //gameLabel.zPosition = 110
        //touchNote.zPosition = 510
        
        //Add Text Label
        //addChild(playLabel)
        addChild(versionLabel)
        //addChild(playLabel2)
        addChild(versionLabel2)
        //addChild(gameLabel)
        //addChild(touchNote)
        
        //Set Up Logo
        let logoTexture = SKTexture(imageNamed: "logo")
        let logoNode = SKSpriteNode(texture: logoTexture)
        logoNode.position = CGPoint(x: 812, y: 1468)
        logoNode.zPosition = 110

        //Add Logo
        addChild(logoNode)
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
