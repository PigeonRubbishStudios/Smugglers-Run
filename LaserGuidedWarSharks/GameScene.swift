//
//  GameScene.swift
//  LaserGuidedWarSharks
//
//  Created by Bolinger, Kyle on 3/8/18.
//  Copyright © 2018 Pigeon Rubbish Studios. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate
{
    var shark: SKSpriteNode!
    var boat: SKSpriteNode!
    var torpedo: SKSpriteNode!
    var hud: SKSpriteNode!
    var heart1: SKSpriteNode!
    var heart2: SKSpriteNode!
    var heart3: SKSpriteNode!
    var barrel1: SKSpriteNode!
    var barrel2: SKSpriteNode!
    var bottle: SKSpriteNode!
    var barrelIcon: SKSpriteNode?
    var barrelBar: SKSpriteNode?
    var cam: SKCameraNode?
    var backgroundMusic: SKAudioNode!
    var backgroundBoatSound: SKAudioNode!
    var touchLocation = CGPoint()
    var boatLocation = CGPoint()
    var torpedoLoc = CGPoint()
    var lastTouchLocation: CGPoint?
    var boatLoc: CGPoint?
    var velocity = CGPoint.zero
    var velocity2 = CGPoint.zero
    var boatVelocity = CGPoint.zero
    var boatVelocity2 = CGPoint.zero
    var boatMovement = CGPoint(x: -20, y: 8) //Boat Starting "Touch" Location
    var xAcceleration = CGFloat(0)
    var widthScale = CGFloat()
    var heightScale = CGFloat()
    var contactQueue = [SKPhysicsContact]()
    var heartImages: UIImage?
    var startFiring = Bool()
    var invincible = false
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    var rumCollected = 0
    var collectablesOnScreen = 0
    var lives = 3
    
    //Shader Variables
    var shaders = [ShaderExample]()
    var currentShader = 0
    typealias ShaderExample = (title: String, shader: SKShader)
    
    let theMask:SKSpriteNode = SKSpriteNode(imageNamed: "barrelBar")
    let sharkAnimation: SKAction
    let motionManager = CMMotionManager()
    let sharkMovePointsPerSec: CGFloat = 480.0 //Shark Speed
    let boatMovePointsPerSec: CGFloat = 380.0 //Boat Speed
    let sharkRotateRadiansPerSec:CGFloat = 5.0 * π //Shark Rotation Speed
    let playableRect: CGRect
    let sharkName = "shark"
    let kBoatFiredBulletName = "boatFiredBullet"
    let kBoatCategory: UInt32 = 0x1 << 0
    let kSharkCategory: UInt32 = 0x1 << 2
    let kSceneEdgeCategory: UInt32 = 0x1 << 3
    let kBoatFiredBulletCategory: UInt32 = 0x1 << 4
    let kCollectableCategory: UInt32 = 0x1 << 4
    
    override func didMove(to view:SKView)
    {
        super.didMove(to:view)
        
        //Bring in Physics
        self.physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        //Bring in Sprites and Nodes
        createShark()
        createBoat()
        createCamera()
        createBackground()
        createOverlay()
        createBuoy()
        createHUD()
        createHeart1()
        createHeart2()
        createHeart3()
        createProgressBar()
        startTorpedos()
        
        //Set Up Accelerometers
        setupCoreMotion()
        
        //Set the Velocity.Y of the Shark and Boat to 0
        velocity2.y = 0
        boatVelocity2.y = 0
        
        //Set Starting "Touch" Point for the Boat
        boatMoving(boatLocation: boatMovement)
        
        if let musicURL = Bundle.main.url(forResource: "srMusic", withExtension: "wav")
        {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
        
        if let boatSoundURL = Bundle.main.url(forResource: "boatSound", withExtension: "mp3")
        {
            backgroundBoatSound = SKAudioNode(url: boatSoundURL)
            backgroundBoatSound.position = boat.position
            addChild(backgroundBoatSound)
        }
        
        //Toggle to Show Playable Area Boundaries
        //debugDrawPlayableArea()
    }
    
    //Function to Set Up Playable Area and Shark Animations
    override init(size: CGSize)
    {
        //Setting the Playable Area Dimensions
        let maxAspectRatio:CGFloat = 3.0/4.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight)/2.0
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)
        
        // You create an array that will store all of the textures to run in the animation.
        var textures:[SKTexture] = []
        
        for i in 1...6
        {
            textures.append(SKTexture(imageNamed: "shark\(i)"))
        }
        // This adds frames 5, 4, 3, & 2to the list
        textures.append(textures[4])
        textures.append(textures[3])
        textures.append(textures[2])
        textures.append(textures[1])
        // Create and run an action
        sharkAnimation = SKAction.animate(with: textures,
                                           timePerFrame: 0.075)
        
        super.init(size: size)
    }
    
    //Some Bullshit Required for the Override Function ¯\_(ツ)_/¯
    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    //Update Function
    override func update(_ currentTime: TimeInterval)
    {
        //Some Update Finding Bullshit ¯\_(ツ)_/¯
        if lastUpdateTime > 0
        {
            dt = currentTime - lastUpdateTime
        }
        else
        {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        //Set Up Camera Position
        if let camera = cam
        {
            camera.position = CGPoint(x: size.width/2, y: size.height/2)
        }
        
        //Set the Boat to Always be 760 Points Below the Shark
        boat.position.y = shark.position.y - 960
        
        //Move the Shark and Boat
        updatePlayer()
        move(sprite: shark, velocity: velocity)
        moveBoat(sprite: boat, velocity: boatVelocity)
        
        //Check if the Shark and Boat are in the Playable Area
        boundsCheckShark()
        boundsCheckBoat()
        
        //Fire Torpedos
        fireBoatBullets(forUpdate: currentTime)
        
        //Check for Collisions
        processContacts(forUpdate: currentTime)
        
        //Randomly Spawn Collectables
        randomCollectableSpawner(forUpdate: currentTime)
        
        //Destroy Heart Sprites
        destroyLives()
        
        //Move to Win Scene
        goToWinScene()
    }
    
    //Function to Begin Contacts
    func didBegin(_ contact: SKPhysicsContact)
    {
        contactQueue.append(contact)
    }
    
    //Function to Handle Collisions
    func handle(_ contact: SKPhysicsContact)
    {
        // Ensure you haven't already handled this contact and removed its nodes
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil
        {
            return
        }
        
        //Set Up Node Names
        let nodeNames = [contact.bodyA.node!.name!, contact.bodyB.node!.name!]
        
        // Torpedo Hit Shark
        if nodeNames.contains("shark") && nodeNames.contains(kBoatFiredBulletName) && lives >= 0 && invincible == false
        {
            sharkHit()
            lives = lives - 1
            contact.bodyB.node!.removeFromParent()
            
            if let sealSound = SKEmitterNode(fileNamed: "sealSound")
            {
                sealSound.position = shark.position
                addChild(sealSound)
            }
            let sound = SKAction.playSoundFileNamed("sealSound", waitForCompletion: false)
            run(sound)
        }
        
        //Shark Collects Item
        if nodeNames.contains("shark") && (nodeNames.contains("barrel1") || nodeNames.contains("barrel2") || nodeNames.contains("bottle")) && rumCollected < 15
        {
            rumCollected = rumCollected + 1
            collectablesOnScreen = collectablesOnScreen - 1
            contact.bodyB.node!.removeFromParent()
            addProgress()
            
            if let drinkSound = SKEmitterNode(fileNamed: "drinkSound")
            {
                drinkSound.position = shark.position
                addChild(drinkSound)
            }
            let sound = SKAction.playSoundFileNamed("BankCoin", waitForCompletion: false)
            run(sound)
        }
    }
    
    //Function to Update Collisions
    func processContacts(forUpdate currentTime: CFTimeInterval)
    {
        for contact in contactQueue
        {
            handle(contact)
            
            if let index = contactQueue.index(of: contact)
            {
                contactQueue.remove(at: index)
            }
        }
    }
    
    //Set up the Shark
    func createShark()
    {
        //Set up the Texture and Position for the Shark Sprite
        let sharkTexture = SKTexture(imageNamed: "shark3")
        let rotationMin = CGFloat(1.0472) //Rotation Min
        let rotationMax = CGFloat(2.0944) //Rotation Max
        let rotationRange = SKRange(lowerLimit: rotationMin, upperLimit: rotationMax) //Rotation Constraint Array
        let rotationConstraint = SKConstraint.zRotation(rotationRange) //Lock Rotation Constraint
        shark = SKSpriteNode(texture: sharkTexture)
        shark.name = sharkName
        shark.position = CGPoint(x: 768, y: 1024)
        shark.constraints = [rotationConstraint]
        shark.zRotation = 1.57
        shark.zPosition = 30
        
        //Add the Shark to the Game
        addChild(shark)
        
        //Set up the Physics for the Shark
        shark.physicsBody = SKPhysicsBody(texture: sharkTexture, size: sharkTexture.size())
        shark.physicsBody?.isDynamic = false
        shark.physicsBody!.categoryBitMask = kSharkCategory
        shark.physicsBody!.contactTestBitMask = 0x0
        shark.physicsBody!.collisionBitMask = kSceneEdgeCategory
    }
    
    //Function to Set Up Accelerometers
    func setupCoreMotion()
    {
        motionManager.accelerometerUpdateInterval = 0.2
        let queue = OperationQueue()
        motionManager.startAccelerometerUpdates(to: queue, withHandler:
            {
                accelerometerData, error in
                guard let accelerometerData = accelerometerData else
                {
                    return
                }
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = (CGFloat(acceleration.x) * 0.75) +
                    (self.xAcceleration * 0.25)
        })
    }
    
    //Function To Set Shark Acceleration
    func updatePlayer()
    {
        // Set velocity based on core motion
        velocity.x = xAcceleration * 1000.0
    }
    
    //Shark Movement Step 1:
    func moveSharkToward(location: CGPoint)
    {
        let offset = location - shark.position
        let direction = offset.normalized()
        velocity = direction * sharkMovePointsPerSec
    }
    
    //Shark Movement Step 2:
    func sceneTouched(touchLocation:CGPoint)
    {
        lastTouchLocation = touchLocation
        moveSharkToward(location: touchLocation)
    }
    
    //Shark Movement Step 3:
    func move(sprite: SKSpriteNode, velocity: CGPoint)
    {
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
                                   y: velocity2.y * CGFloat(dt))
        sprite.position += amountToMove
        
        //Rotate the Shark
        rotate(sprite: shark, direction: velocity, rotateRadiansPerSec: sharkRotateRadiansPerSec)
        
        //Start the Shark Animation
        startSharkAnimation()
    }
    
    //Function to Start the Shark Animation
    func startSharkAnimation()
    {
        if shark.action(forKey: "animation") == nil
        {
            shark.run(
                //Repeat the animated sprites forever.
                SKAction.repeatForever(sharkAnimation),
                withKey: "animation")
        }
    }
    
    //Function to Rotate the Shark
    func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat)
    {
//        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
//        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
//        sprite.zRotation += shortest.sign() * amountToRotate
        
        //Set the Shark Rotation Based on the Accelerometers
        if xAcceleration >= 0.1
        {
            let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
            let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
            sprite.zRotation += shortest.sign() * amountToRotate
        }
        else if xAcceleration <= -0.1
        {
            let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
            let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
            sprite.zRotation += shortest.sign() * amountToRotate
        }
        if xAcceleration <= 0.1 && xAcceleration >= -0.1
        {
            let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: 1.5708)
            let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
            sprite.zRotation += shortest.sign() * amountToRotate
        }
    }
    
    //Function to Check if the Shark is within the Playable Area
    func boundsCheckShark()
    {
        let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
        
        if shark.position.x <= bottomLeft.x
        {
            shark.position.x = bottomLeft.x
            velocity.x = abs(velocity.x)
        }
        if shark.position.x >= topRight.x
        {
            shark.position.x = topRight.x
            velocity.x = -velocity.x
        }
    }
    
    //Player hits enemy and becomes invincible/blinks three times.
    func sharkHit()
    {
        //Switches the invincible to true/on.
        invincible = true
        
        //Player will blink using times and durations.  Durations will be 3
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customAction(withDuration: duration)
        {
            node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime).truncatingRemainder(
                dividingBy: slice)
            node.isHidden = remainder > slice / 2
        }
        
        //This function makes the player reappear and reset the invincibility variable back to false.
        let setHidden = SKAction.run()
        {
            [weak self] in
            self?.shark.isHidden = false
            self?.invincible = false
        }
        
        //This sequence complete both the blinking action, hiding and making the player reappear.
        shark.run(SKAction.sequence([blinkAction, setHidden]))
    }
    
    //Set up the Boat
    func createBoat()
    {
        //Set up the Texture and Position for the Boat Sprite
        let boatTexture = SKTexture(imageNamed: "boat")
        boat = SKSpriteNode(texture: boatTexture)
        boat.position = CGPoint(x: 768, y: 0)
        boat.zRotation = 4.71
        boat.zPosition = 40
        
        //Add the Boat to the Game
        addChild(boat)
        
        //Set up the Physics for the Boat
        boat.physicsBody = SKPhysicsBody(texture: boatTexture, size: boatTexture.size())
        boat.physicsBody!.isDynamic = false
        boat.physicsBody!.categoryBitMask = kBoatCategory
        boat.physicsBody!.contactTestBitMask = 0x0
        boat.physicsBody!.collisionBitMask = 0x0
    }
    
    //Boat Movement Step 1:
    func moveBoatToward(location: CGPoint)
    {
        let offset = location - boat.position
        let direction = offset.normalized()
        boatVelocity = direction * boatMovePointsPerSec
    }
    
    //Boat Movement Step 2:
    func boatMoving(boatLocation:CGPoint)
    {
        boatLoc = boatLocation
        moveBoatToward(location: boatLocation)
    }
    
    //Boat Movement Step 3:
    func moveBoat(sprite: SKSpriteNode, velocity: CGPoint)
    {
        if lives > 0
        {
            let amountToMove = CGPoint(x: boatVelocity.x * CGFloat(dt),
                                       y: boatVelocity2.y * CGFloat(dt))
            sprite.position += amountToMove
        }
    }
    
    //Function to Check if the Boat is within the Playable Area
    func boundsCheckBoat()
    {
        let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
        
        if boat.position.x <= bottomLeft.x
        {
            boat.position.x = bottomLeft.x
            boatVelocity.x = abs(boatVelocity.x)
        }
        if boat.position.x >= topRight.x
        {
            boat.position.x = topRight.x
            boatVelocity.x = -boatVelocity.x
        }
    }
    
    //Enumerate Torpedos
    enum BulletType
    {
        case boatFired
    }
    
    //Function to Make Torpedos
    func makeBullet(ofType bulletType: BulletType) -> SKNode
    {
        var bullet: SKNode
        let torpedoTexture = SKTexture(imageNamed: "seal")
        
        switch bulletType
        {
        case .boatFired:
            bullet = SKSpriteNode(texture: torpedoTexture)
            bullet.name = kBoatFiredBulletName
            break
        }
        
        //Set up the Physics for the Torpedo
        bullet.physicsBody = SKPhysicsBody(texture: torpedoTexture, size: torpedoTexture.size())
        bullet.physicsBody!.isDynamic = true
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask = kBoatFiredBulletCategory
        bullet.physicsBody!.contactTestBitMask = kSharkCategory
        bullet.physicsBody!.collisionBitMask = 0x0
        
        return bullet
    }
    
    //Function to Fire Torpedos
    func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval)
    {
        let bulletAction = SKAction.sequence([
            SKAction.move(to: destination, duration: duration),
            SKAction.wait(forDuration: 3.0 / 60.0),
            SKAction.removeFromParent()
            ])

        bullet.run(SKAction.group([bulletAction]))
        
        addChild(bullet)
    }
    
    //Update Function to Fire Torpedos
    func fireBoatBullets(forUpdate currentTime: CFTimeInterval)
    {
        let existingBullet = childNode(withName: kBoatFiredBulletName)
        let randomFire = Int.random(min: 1, max: 100)
        
        switch Int.random(min: 0, max: 2)
        {
        case 0:
            if existingBullet == nil && startFiring == true && lives > 0 && rumCollected < 15 && randomFire >= 75
            {
                let bullet = makeBullet(ofType: .boatFired)
                bullet.position = CGPoint(x: boat.position.x, y: boat.position.y - boat.frame.size.height / 2 + bullet.frame.size.height / 2)
                bullet.zRotation = 4.71
                
                let bulletDestination = CGPoint(x: boat.position.x, y: 2048)
                
                fireBullet(bullet: bullet, toDestination: bulletDestination, withDuration: 3.5)
            }
        case 1:
            print(randomFire)
        case 2:
            print(randomFire)
        default:
            print(randomFire)
        }
    }
    
    //Function to Start Firing Torpedos After 3 Seconds
    func startTorpedos()
    {
        let wait = SKAction.wait(forDuration: 3.0)
        let block = SKAction.run
        {
            self.startFiring = true
        }
        self.run(SKAction.sequence([wait, block]))
    }
    
    //Function to Create the Scrolling Background and Water Shader
    func createBackground()
    {
        let waterTexture = SKTexture(imageNamed: "water")
        
        for i in 0 ... 1
        {
            let waterNode = SKSpriteNode(texture: waterTexture)
            waterNode.zPosition = -50
            waterNode.anchorPoint = CGPoint.zero
            waterNode.position = CGPoint(x: 0, y: (cameraRect.size.height * CGFloat(i)) - CGFloat(1 * i))
            addChild(waterNode)
            
            shaders.append(("Water", createWater()))
            let example = shaders[currentShader]
            waterNode.shader = example.shader
            waterNode.setValue(SKAttributeValue(size: waterTexture.size()), forAttribute: "a_size")
            
            let moveDown = SKAction.moveBy(x: 0, y: -waterTexture.size().height, duration: 3.0)
            let moveReset = SKAction.moveBy(x: 0, y: waterTexture.size().height, duration: 0)
            let moveLoop = SKAction.sequence([moveDown, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            waterNode.run(moveForever)
        }
    }
    
    //Function to Create the Water Overlay
    func createOverlay()
    {
        let overlayTexture = SKTexture(imageNamed: "overlay")
        
        for i in 0 ... 1
        {
            let overlayNode = SKSpriteNode(texture: overlayTexture)
            overlayNode.alpha = 1
            overlayNode.zPosition = -40
            overlayNode.anchorPoint = CGPoint.zero
            overlayNode.position = CGPoint(x: 0, y: (cameraRect.size.height * CGFloat(i)) - CGFloat(1 * i))
            addChild(overlayNode)
        }
    }
    
    //Function to Create and Move the Buoys
    func createBuoy()
    {
        let rightBuoyTexture = SKTexture(imageNamed: "buoy")
        let leftBuoyTexture = SKTexture(imageNamed: "buoy2")
        for i in 0 ... 1
        {
            let leftBuoyNode = SKSpriteNode(texture: leftBuoyTexture)
            leftBuoyNode.zPosition = -30
            leftBuoyNode.anchorPoint = CGPoint.zero
            leftBuoyNode.position = CGPoint(x: -380
                , y: (cameraRect.size.height * CGFloat(i)) - CGFloat(1 * i))
            addChild(leftBuoyNode)
            let rightBuoyNode = SKSpriteNode(texture: rightBuoyTexture)
            rightBuoyNode.zPosition = -30
            rightBuoyNode.anchorPoint = CGPoint.zero
            rightBuoyNode.position = CGPoint(x: 1374, y: (cameraRect.size.height * CGFloat(i)) - CGFloat(1 * i))
            addChild(rightBuoyNode)
            
            let rightMoveDown = SKAction.moveBy(x: 0, y: -rightBuoyTexture.size().height, duration: 3.0)
            let rightMoveReset = SKAction.moveBy(x: 0, y: rightBuoyTexture.size().height, duration: 0)
            let rightMoveLoop = SKAction.sequence([rightMoveDown, rightMoveReset])
            let rightMoveForever = SKAction.repeatForever(rightMoveLoop)
            let moveDown = SKAction.moveBy(x: 0, y: -leftBuoyTexture.size().height, duration: 3.0)
            let moveReset = SKAction.moveBy(x: 0, y: leftBuoyTexture.size().height, duration: 0)
            let moveLoop = SKAction.sequence([moveDown, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            rightBuoyNode.run(rightMoveForever)
            leftBuoyNode.run(moveForever)
        }
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
    
    //Function to Create the HUD
    func createHUD()
    {
        //Set up the Color, Size, and Position for the HUD
        let hudTexture = SKTexture(imageNamed: "hud")
        hud = SKSpriteNode(texture: hudTexture)
        hud.position = CGPoint(x: 768, y: 1869.5)
        hud.zPosition = 100
        
        //Add the HUD to the Game
        addChild(hud)
    }
    
    //Function to Create Heart 1
    func createHeart1()
    {
        //Set up the Texture and Position for the 1st Heart Sprite
        let heartTexture = SKTexture(imageNamed: "heart")
        heart1 = SKSpriteNode(texture: heartTexture)
        heart1.position = CGPoint(x: 350, y: 1961)
        heart1.setScale(1.7)
        heart1.zPosition = 110

        //Add Heart 1 to the Game
        addChild(heart1)
    }

    //Function to Create Heart 2
    func createHeart2()
    {
        //Set up the Texture and Position for the 2nd Heart Sprite
        let heartTexture = SKTexture(imageNamed: "heart")
        heart2 = SKSpriteNode(texture: heartTexture)
        heart2.position = CGPoint(x: 450, y: 1961)
        heart2.setScale(1.7)
        heart2.zPosition = 110

        //Add Heart 2 to the Game
        addChild(heart2)
    }

    //Function to Create Heart 3
    func createHeart3()
    {
        //Set up the Texture and Position for the 3rd Heart Sprite
        let heartTexture = SKTexture(imageNamed: "heart")
        heart3 = SKSpriteNode(texture: heartTexture)
        heart3.position = CGPoint(x: 550, y: 1961)
        heart3.setScale(1.7)
        heart3.zPosition = 110

        //Add Heart 3 to the Game
        addChild(heart3)
    }
    
    //Function to Destroy Heart Sprites
    func destroyLives()
    {
        if lives == 2
        {
            heart3.removeFromParent()
        }
        if lives == 1
        {
            heart2.removeFromParent()
        }
        if lives == 0
        {
            heart1.removeFromParent()
            shark.removeFromParent()
            let wait = SKAction.wait(forDuration: 3.0)
            let block = SKAction.run
            {
                let myScene = GameOverScene(size: self.size)
                myScene.scaleMode = self.scaleMode
                self.view?.presentScene(myScene)
            }
            self.run(SKAction.sequence([wait, block]))
        }
    }
    
    //Function to Create the Progress Bar
    func createProgressBar()
    {
        //Set Up the Barrel and Barrel Bar Background
        barrelBar = SKSpriteNode(imageNamed: "barrelBar")
        barrelBar?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        barrelBar?.position = CGPoint(x: 1115, y: 1917)
        barrelBar?.zPosition = 120
        barrelIcon = SKSpriteNode(imageNamed: "barrelIcon2")
        barrelIcon?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        barrelIcon?.position = CGPoint(x: 1115, y: 1938.5)
        barrelIcon?.zPosition = 160
        addChild(barrelBar!)
        addChild(barrelIcon!)
        
        //Set Up the Image that will be Masked
        let imageToMask:SKSpriteNode = SKSpriteNode(imageNamed: "darkRum")
        imageToMask.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        imageToMask.position = CGPoint(x: 1115, y: 1851)
        imageToMask.zPosition = 140
        
        //Set Up the Image that will be the Mask
        theMask.size = CGSize(width: barrelBar!.size.width * (widthScale), height: barrelBar!.size.height * (heightScale))
        theMask.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        theMask.position = CGPoint(x: 1115, y: 1851)
        theMask.zPosition = 130
        
        //Masking Requires Using An SKCropNode
        let cropNode:SKCropNode = SKCropNode()
        cropNode.addChild(imageToMask) //Add the imageToMask into the cropNode
        cropNode.maskNode = theMask //Set the Mask
        cropNode.zPosition = 150
        
        //Add the cropNode to the Scene
        self.addChild(cropNode)
    }
    
    //Function to Add Progress when an Item is Collected
    func addProgress()
    {
        if rumCollected > 0 && rumCollected <= 2
        {
            widthScale = 0.8
            heightScale = heightScale + 0.066
        }
        if rumCollected > 2 && rumCollected <= 4
        {
            widthScale = 0.9
            heightScale = heightScale + 0.066
        }
        if rumCollected == 5
        {
            widthScale = 0.95
            heightScale = heightScale + 0.066
        }
        if rumCollected > 4 && rumCollected < 15
        {
            widthScale = 1.0
            heightScale = heightScale + 0.066
        }
        theMask.size = CGSize(width: barrelBar!.size.width * (widthScale), height: barrelBar!.size.height * (heightScale))
    }
    
    //Function to Add Barrel 1 to the Screen
    func addBarrel1()
    {
        if collectablesOnScreen < 2
        {
            let barrel1Texture = SKTexture(imageNamed: "barrel1")
            barrel1 = SKSpriteNode(texture: barrel1Texture)
            
            barrel1.name = "barrel1"
            barrel1.position = CGPoint(
                x: CGFloat.random(min: self.cameraRect.minX,
                                  max: self.cameraRect.maxX),
                y: 2048)
            barrel1.setScale(0)
            barrel1.zPosition = 0
            barrel1.physicsBody = SKPhysicsBody(texture: barrel1Texture, size: barrel1Texture.size())
            barrel1.physicsBody!.isDynamic = true
            barrel1.physicsBody!.affectedByGravity = false
            barrel1.physicsBody!.categoryBitMask = kCollectableCategory
            barrel1.physicsBody!.contactTestBitMask = kSharkCategory
            barrel1.physicsBody!.collisionBitMask = 0x0
            addChild(barrel1)
            
            collectablesOnScreen = collectablesOnScreen + 1
            
            let appear = SKAction.scale(to: 0.8, duration: 0.5)
            
            let scaleUp = SKAction.scale(by: 1.2, duration: 2.0)
            let scaleDown = scaleUp.reversed()
            let fullScale = SKAction.sequence(
                [scaleUp, scaleDown, scaleUp, scaleDown])
            let group = SKAction.group([fullScale])
            let groupWait = SKAction.repeat(group, count: 10)
            
            let disappear = SKAction.scale(to: 0, duration: 0.5)
            let removeFromParent = SKAction.removeFromParent()
            let subtractCollectables = SKAction.run
            {
                self.collectablesOnScreen = self.collectablesOnScreen - 1
            }
            let actions = [appear, groupWait, disappear, removeFromParent, subtractCollectables]
            barrel1.run(SKAction.sequence(actions))
            
            let moveDown = SKAction.moveTo(y: -300, duration: 4.0)
            barrel1.run(moveDown)
            
            let wait = SKAction.wait(forDuration: 5.0)
            let invis = SKAction.scale(to: 0, duration: 0.5)
            let block = SKAction.run
            {
                self.barrel1.removeFromParent()
                self.collectablesOnScreen = self.collectablesOnScreen - 1
            }
            barrel1.run(SKAction.sequence([wait, invis, block]))
        }
    }
    
    //Function to Add Barrel 2 to the Screen
    func addBarrel2()
    {
        if collectablesOnScreen < 2
        {
            let barrel2Texture = SKTexture(imageNamed: "barrel2")
            barrel2 = SKSpriteNode(texture: barrel2Texture)
            
            barrel2.name = "barrel2"
            barrel2.position = CGPoint(
                x: CGFloat.random(min: self.cameraRect.minX,
                                  max: self.cameraRect.maxX),
                y: 2048)
            barrel2.setScale(0)
            barrel2.zPosition = 0
            barrel2.physicsBody = SKPhysicsBody(texture: barrel2Texture, size: barrel2Texture.size())
            barrel2.physicsBody!.isDynamic = true
            barrel2.physicsBody!.affectedByGravity = false
            barrel2.physicsBody!.categoryBitMask = kCollectableCategory
            barrel2.physicsBody!.contactTestBitMask = kSharkCategory
            barrel2.physicsBody!.collisionBitMask = 0x0
            addChild(barrel2)
            
            collectablesOnScreen = collectablesOnScreen + 1
            
            let appear = SKAction.scale(to: 0.8, duration: 0.5)
            
            let scaleUp = SKAction.scale(by: 1.2, duration: 2.0)
            let scaleDown = scaleUp.reversed()
            let fullScale = SKAction.sequence(
                [scaleUp, scaleDown, scaleUp, scaleDown])
            let group = SKAction.group([fullScale])
            let groupWait = SKAction.repeat(group, count: 10)
            
            let disappear = SKAction.scale(to: 0, duration: 0.5)
            let removeFromParent = SKAction.removeFromParent()
            let subtractCollectables = SKAction.run
            {
                self.collectablesOnScreen = self.collectablesOnScreen - 1
            }
            let actions = [appear, groupWait, disappear, removeFromParent, subtractCollectables]
            barrel2.run(SKAction.sequence(actions))
            
            let moveDown = SKAction.moveTo(y: -300, duration: 4.0)
            barrel2.run(moveDown)
            
            let wait = SKAction.wait(forDuration: 5.0)
            let invis = SKAction.scale(to: 0, duration: 0.5)
            let block = SKAction.run
            {
                self.barrel2.removeFromParent()
                self.collectablesOnScreen = self.collectablesOnScreen - 1
            }
            barrel2.run(SKAction.sequence([wait, invis, block]))
        }
    }
    
    //Function to Add the Bottle to the Screen
    func addBottle()
    {
        if collectablesOnScreen < 2
        {
            let bottleTexture = SKTexture(imageNamed: "bottle")
            bottle = SKSpriteNode(texture: bottleTexture)
            
            bottle.name = "bottle"
            bottle.position = CGPoint(
                x: CGFloat.random(min: self.cameraRect.minX,
                                  max: self.cameraRect.maxX),
                y: 2048)
            bottle.setScale(0)
            bottle.zPosition = 0
            bottle.physicsBody = SKPhysicsBody(texture: bottleTexture, size: bottleTexture.size())
            bottle.physicsBody!.isDynamic = true
            bottle.physicsBody!.affectedByGravity = false
            bottle.physicsBody!.categoryBitMask = kCollectableCategory
            bottle.physicsBody!.contactTestBitMask = kSharkCategory
            bottle.physicsBody!.collisionBitMask = 0x0
            addChild(bottle)
            
            collectablesOnScreen = collectablesOnScreen + 1
            
            let appear = SKAction.scale(to: 1.2, duration: 0.5)
            
            let scaleUp = SKAction.scale(by: 1.2, duration: 2.0)
            let scaleDown = scaleUp.reversed()
            let fullScale = SKAction.sequence(
                [scaleUp, scaleDown])
            let group = SKAction.group([fullScale])
            let groupWait = SKAction.repeat(group, count: 10)
            
            let disappear = SKAction.scale(to: 0, duration: 0.5)
            let removeFromParent = SKAction.removeFromParent()
            let subtractCollectables = SKAction.run
            {
                self.collectablesOnScreen = self.collectablesOnScreen - 1
            }
            let actions = [appear, groupWait, disappear, removeFromParent, subtractCollectables]
            bottle.run(SKAction.sequence(actions))
            
            let moveDown = SKAction.moveTo(y: -300, duration: 4.0)
            bottle.run(moveDown)
            
            let wait = SKAction.wait(forDuration: 5.0)
            let invis = SKAction.scale(to: 0, duration: 0.5)
            let block = SKAction.run
            {
                self.bottle.removeFromParent()
                self.collectablesOnScreen = self.collectablesOnScreen - 1
            }
            bottle.run(SKAction.sequence([wait, invis, block]))
        }
    }
    
    //Function to Randomly Spawn Collectables
    func randomCollectableSpawner(forUpdate currentTime: CFTimeInterval)
    {
        let collectablePercentage = Int.random(min: 1, max: 100)
        
        if Int.random(min: 1, max: 100) <= collectablePercentage
        {
            if collectablePercentage >= 75 && collectablesOnScreen < 2 && rumCollected < 15
            {
                switch Int.random(min: 0, max: 2)
                {
                case 0:
                    addBarrel1()
                case 1:
                    addBarrel2()
                case 2:
                    addBottle()
                default:
                    addBottle()
                }
            }
        }
    }
    
    //Function to Move to Win Scene when 15 Items have been Collected
    func goToWinScene()
    {
        if rumCollected == 15
        {
            let wait = SKAction.wait(forDuration: 3.0)
            let block = SKAction.run
            {
                let myScene = WinScene(size: self.size)
                myScene.scaleMode = self.scaleMode
                self.view?.presentScene(myScene)
                self.startFiring = false
            }
            self.run(SKAction.sequence([wait, block]))
        }
    }
    
    //Function to Create the Camera
    func createCamera()
    {
        cam = SKCameraNode()
        self.camera = cam
        self.addChild(cam!)
    }
    
    //Set up the Camera Rectangle
    var cameraRect : CGRect
    {
        let x = (camera?.position.x)! - size.width/2
            + (size.width - playableRect.width)/2
        let y = (camera?.position.y)! - size.height/2
            + (size.height - playableRect.height)/2
        return CGRect(
            x: x,
            y: y,
            width: playableRect.width,
            height: playableRect.height)
    }
    
    //Function to Show the Playable Area Boundaries
    func debugDrawPlayableArea()
    {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }
}
