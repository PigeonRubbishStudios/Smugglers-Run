//
//  GameViewController.swift
//  LaserGuidedWarSharks
//
//  Created by Kyle Bolinger on 4/19/18.
//  Copyright © 2018 HLAD Studios. All rights reserved.
//

import Foundation
import SpriteKit

class GameViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let scene =
            MainMenuScene(size:CGSize(width: 1536, height: 2048))
        let skView = self.view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.showsPhysics = false
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
}
