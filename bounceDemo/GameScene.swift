//
//  GameScene.swift
//  bounceDemo
//
//  Created by Jay on 4/17/16.
//  Copyright (c) 2016 Jay. All rights reserved.
//

import SpriteKit

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Monster   : UInt32 = 0b1       // 1
    static let Projectile: UInt32 = 0b10      // 2
    static let Player    : UInt32 = 0b100     // 4
    static let Goal      : UInt32 = 0b1000    // 8
    static let Border    : UInt32 = 0b10000   // 16
    
}

class GameConstants {
    static let playerAngularVelocity = CGFloat(1)
    static let playerVelocity = 100.0
    
    static let moveDistance = CGFloat(5.0)
    static let moveDuration = 0.1
    static let moveLeft = CGPoint(x: -moveDistance, y: 0.0)
    static let moveRight = CGPoint(x: moveDistance, y: 0.0)
    static let moveUp = CGPoint(x: 0.0, y: moveDistance)
    static let moveDown = CGPoint(x: 0.0, y: -moveDistance)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let player = SKShapeNode(circleOfRadius: 40.0)
    var monsterCount = 0
    var monsterKilled = 0
    var moves = 0
    
    
    
    override func didMoveToView(view: SKView) {
        setupBackground()
        setupControls()
        setupBorders()
        setupPlayer(CGPoint(x: size.width - 100.0, y: size.height/2))
        
        for x in 1...10 {
            for y in 1...10 {
                
                let actualY = random(min: -size.height/30.0, max: size.height/30.0)
                let position = CGPoint(x: size.width/11/2 * CGFloat(x), y: size.height/11 * CGFloat(y) + actualY)
                addField(position)
                monsterCount++
            }
        }
        

    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }

    func setupControls() {
        let uipgr = UIPanGestureRecognizer(target: self, action: "slidePlayer:")
        
        view?.addGestureRecognizer(uipgr)
    }
    
    
    func slidePlayer(gesture: UIPanGestureRecognizer) {
        //        let relativeLocation = gesture.translationInView(self.view)
        let relativeVelocity = gesture.velocityInView(self.view)
        //        print("\(relativeLocation) : \(relativeVelocity)")
        
        switch gesture.state {
        case .Changed:
            let dx = (player.physicsBody?.velocity.dx)! + relativeVelocity.x/2.0
            let dy = (player.physicsBody?.velocity.dy)! - relativeVelocity.y/2.0
            
            player.physicsBody?.velocity = CGVectorMake(dx, dy)
            moves++
            
        default:
            break
        }
    }
    func setupBackground() {
        
        backgroundColor = SKColor.blackColor()
        
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0)
        physicsWorld.contactDelegate = self
        
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
    }

    
    func setupPlayer(position: CGPoint) {
        
        
        player.position = position
        player.physicsBody = SKPhysicsBody(circleOfRadius: 40.0)
        
        if let physics = player.physicsBody {
            physics.dynamic = true
            physics.affectedByGravity = false
            physics.categoryBitMask = PhysicsCategory.Player
            physics.contactTestBitMask = PhysicsCategory.Border
            physics.collisionBitMask = PhysicsCategory.Monster | PhysicsCategory.Border
            physics.usesPreciseCollisionDetection = true
        }
        addChild(player)
        
    }
    
    func setupBorders() {
        
        let border1 = SKSpriteNode(color: UIColor.blueColor(), size: CGSize(width: size.width*2, height: 100))
        let border2 = SKSpriteNode(color: UIColor.blueColor(), size: CGSize(width: size.width*2, height: 100))
        let border3 = SKSpriteNode(color: UIColor.blueColor(), size: CGSize(width: 100, height: size.height*2))
        let border4 = SKSpriteNode(color: UIColor.blueColor(), size: CGSize(width: 100, height: size.height*2))
        
        border1.position = CGPoint(x: size.width/2, y: size.height + 50)
        border2.position = CGPoint(x: size.width/2, y: -50)
        border3.position = CGPoint(x: size.width + 50, y: size.height/2)
        border4.position = CGPoint(x: -50, y: size.height/2)
        
        let borders = [border1, border2, border3, border4]
        
        for border in borders {
            border.physicsBody = SKPhysicsBody(rectangleOfSize: border.size)
            
            if let physics = border.physicsBody {
                physics.pinned = true
                physics.allowsRotation = false
                physics.affectedByGravity = false
                physics.dynamic = false
                physics.categoryBitMask = PhysicsCategory.Border
                physics.contactTestBitMask = PhysicsCategory.Monster
                physics.collisionBitMask = PhysicsCategory.None
                physics.usesPreciseCollisionDetection = true
            }
            addChild(border)
        }
        
    }

    
    func addField(position: CGPoint) {
        
        let circle = SKShapeNode(circleOfRadius: 20.0)
        
        circle.position = position
        circle.physicsBody = SKPhysicsBody(circleOfRadius: 20.0)
        
        if let physics = circle.physicsBody {
            physics.dynamic = true
            physics.affectedByGravity = false
            physics.linearDamping = 0.1
            physics.categoryBitMask = PhysicsCategory.Monster
            physics.contactTestBitMask = PhysicsCategory.Border
            physics.collisionBitMask = PhysicsCategory.Monster | PhysicsCategory.Player
            physics.usesPreciseCollisionDetection = true
        }
        addChild(circle)
        
    }
    
    
    
    func monsterDidCollideWithBorder(projectile:SKNode) {
        print(monsterKilled)
        monsterKilled++
        projectile.removeFromParent()
        
        if (monsterKilled == monsterCount)
        {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true, moves: moves)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Border != 0)) {
                if let node = firstBody.node {
                    monsterDidCollideWithBorder(node)
                }
        }
    }

    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
