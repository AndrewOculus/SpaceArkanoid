//
//  GameScene.swift
//  SpaceGame
//
//  Created by Андрей Лапушкин on 19.04.2018.
//  Copyright © 2018 Андрей Лапушкин. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene , SKPhysicsContactDelegate{
    
    var starField:SKEmitterNode!
    var player:SKSpriteNode!
    var scoreLabel:SKLabelNode!
    var gameTimer:Timer!
    
    var possibleAliens = ["alien","alien2","alien3"]
    var alienCategory:UInt32 = 0x1 << 1
    var photonTorpedpedoCategory:UInt32 = 0x1 << 0
    
    let motionManager = CMMotionManager()
    var accselerom:CGFloat = 0

    
    var score:Int = 0 {
        didSet
        {
            scoreLabel.text = "Score \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        
        starField = SKEmitterNode(fileNamed: "Starfield")
        starField.position = CGPoint(x: 0, y: 1472)
        starField.advanceSimulationTime(10)
        self.addChild(starField)
        
        starField.zPosition = -1
        
        player = SKSpriteNode(imageNamed: "shuttle")
        player.position = CGPoint(x: self.frame.size.width/2, y: player.size.height/2 + 20)
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: 100, y: self.frame.size.height-60)
        self.addChild(scoreLabel)
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(self.addAlien), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data: CMAccelerometerData?, error: Error?) in
            if let accselerometrData = data{
                let accs = accselerometrData.acceleration
                self.accselerom = CGFloat(accs.x*0.75) + self.accselerom*0.25
            }
            }
        
    }
    override func didSimulatePhysics() {
        player.position.x += self.accselerom * 50
        if player.position.x < 20 {
            player.position = CGPoint(x: self.frame.size.width+20, y: player.position.y)
        }else if player.position.x > self.frame.size.width + 20 {
            player.position = CGPoint(x: -20, y: player.position.y)
        }
    }
    @objc func addAlien(){
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        let randomAlienPosition = GKRandomDistribution(lowestValue: 0, highestValue: 414)
        let position = CGFloat(randomAlienPosition.nextInt())
        alien.position = CGPoint(x: position, y: self.frame.size.height)
        alien.physicsBody = SKPhysicsBody(rectangleOf: (alien.size))
        alien.physicsBody?.isDynamic = true
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animationDuration = 6
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x:position,y: -((alien.size.height))), duration: TimeInterval(animationDuration)))
        actionArray.append(SKAction.removeFromParent())
        alien.run(SKAction.sequence(actionArray))
        
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
    }
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & photonTorpedpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0{
            torpedoDidCollideWithAlien(torp: firstBody.node as! SKSpriteNode, al: secondBody.node as! SKSpriteNode)
        }
        
    }
    func torpedoDidCollideWithAlien( torp:SKSpriteNode , al:SKSpriteNode){
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = al.position
        self.addChild(explosion)
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))

        torp.removeFromParent()
        al.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 0.5)){
            explosion.removeFromParent()
        }
        score += 5
        
    }
    func fireTorpedo(){
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        let torpedo = SKSpriteNode(imageNamed: "torpedo")
        torpedo.position = player.position
        torpedo.position.y += 5
        
        torpedo.physicsBody = SKPhysicsBody(circleOfRadius: torpedo.size.width/2)
        torpedo.physicsBody?.isDynamic = true
        
        torpedo.physicsBody?.categoryBitMask = photonTorpedpedoCategory
        torpedo.physicsBody?.contactTestBitMask = alienCategory
        torpedo.physicsBody?.collisionBitMask = 0
        torpedo.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(torpedo)
        
        var animationDuration:TimeInterval = 0.3
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x:player.position.x,y: self.frame.size.height+10), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        torpedo.run(SKAction.sequence(actionArray))

    }
    
    override func update(_ currentTime: TimeInterval) {

    }
}
