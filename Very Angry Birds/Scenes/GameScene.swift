//
//  GameScene.swift
//  Very Angry Birds
//
//  Created by ClementM on 14/03/2018.
//  Copyright © 2018 ClementM. All rights reserved.
//

import SpriteKit
import GameplayKit

enum RoundState {
    case ready, flying, finished, animating
}

class GameScene: SKScene {
    
    //MARK: - Variables
    var sceneManagerDelegate: SceneManagerDelegate?
    
    var mapNode = SKTileMapNode()
    
    let gameCamera = GameCamera()
    var panRecognizer = UIPanGestureRecognizer()
    var pinchRecognizer = UIPinchGestureRecognizer()
    var maxScale: CGFloat = 0
    
    var bird = Bird(type: .red)
    var birds = [Bird]()
    let anchor = SKNode()
    
    var level: Int?
    
    var roundState = RoundState.ready
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        
        guard let level = level else {
            return
        }
        guard let levelData = LevelData(level: level) else {
            return
        }
        for birdColor in levelData.birds {
            if let newBirdType = BirdType(rawValue: birdColor) {
                birds.append(Bird(type: newBirdType))
            }
        }
        
        setupLevel()
        setupGestureRecognizers()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch roundState {
        case .ready:
            if let touch = touches.first {
                let touchLocation = touch.location(in: self)
                if bird.contains(touchLocation) {
                    panRecognizer.isEnabled = false
                    bird.grabbed = true
                    bird.position = touchLocation
                }
            }
        case .flying:
            break
        case .finished:
            guard let view = view else { return }
            roundState = .animating
            let moveCameraBackAction = SKAction.move(to: CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2), duration: 2.0)
            moveCameraBackAction.timingMode = .easeInEaseOut
            gameCamera.run(moveCameraBackAction) {
                self.panRecognizer.isEnabled = true
                self.addBird()
            }
        case .animating:
            break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if bird.grabbed {
                let touchLocation = touch.location(in: self)
                bird.position = touchLocation
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if bird.grabbed {
            bird.grabbed = false
            bird.flying = true
            roundState = .flying
            constraintToAnchor(active: false)
            gameCamera.setConstraints(withScene: self, andFrame: mapNode.frame, toNode: bird)
            let dx = anchor.position.x - bird.position.x
            let dy = anchor.position.y - bird.position.y
            let impulse = CGVector(dx: dx, dy: dy)
            bird.physicsBody?.applyImpulse(impulse)
            bird.isUserInteractionEnabled = false
        }
    }
    
    //MARK: - Custom function
    func setupGestureRecognizers() {
        guard let view = view else { return }
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        view.addGestureRecognizer(panRecognizer)
        
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        view.addGestureRecognizer(pinchRecognizer)
    }
    
    func setupLevel() {
        if let mapNode = childNode(withName: "Tile Map Node") as? SKTileMapNode {
            self.mapNode = mapNode
            maxScale = mapNode.mapSize.width / frame.size.width
        }
        
        addCamera()
        
        for child in mapNode.children {
            if let child = child as? SKSpriteNode {
                guard let name = child.name else { continue }
                if !["glass" ,"wood" , "stone"].contains(name) { continue }
                guard let type = BlockType(rawValue: name) else { continue }
                let block = Block(type: type)
                block.size = child.size
                block.position = child.position
                block.zRotation = child.zRotation
                block.zPosition = ZPosition.obstacle
                block.createPhysicsBody()
                mapNode.addChild(block)
                // We don't need the placeholder anymore
                child.removeFromParent()
            }
            
        }
        
        let dimensions = CGRect(x: 0, y: mapNode.tileSize.height, width: mapNode.frame.size.width, height: mapNode.frame.size.height - mapNode.tileSize.height)
        physicsBody = SKPhysicsBody(edgeLoopFrom: dimensions)
        physicsBody?.categoryBitMask = PhysicsCategory.edge
        physicsBody?.contactTestBitMask = PhysicsCategory.bird | PhysicsCategory.block
        physicsBody?.collisionBitMask = PhysicsCategory.all
        
        anchor.position = CGPoint(x: mapNode.frame.midX / 2, y: mapNode.frame.midY / 2)
        addChild(anchor)
        addSlingshot()
        addBird()
    }
    
    func addCamera() {
        guard let view = view else { return }
        addChild(gameCamera)
        gameCamera.position = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
        camera = gameCamera
        gameCamera.setConstraints(withScene: self, andFrame: mapNode.frame, toNode: nil)
    }
    
    func addSlingshot() {
        let slingshot = SKSpriteNode(imageNamed: "slingshot")
        let scaleSize = CGSize(width: 0, height: mapNode.frame.midY / 2 - mapNode.tileSize.height / 2)
        slingshot.aspectScale(toSize: scaleSize, width: false, withMultiplier: 1.0)
        slingshot.position = CGPoint(x: anchor.position.x, y: mapNode.tileSize.height + slingshot.size.height / 2)
        slingshot.zPosition = ZPosition.obstacle
        mapNode.addChild(slingshot)
    }
    
    func addBird() {
        if birds.isEmpty {
            print("No more birds")
            return
        }
        
        bird = birds.removeFirst()
        bird.physicsBody = SKPhysicsBody(rectangleOf: bird.size)
        bird.physicsBody?.categoryBitMask = PhysicsCategory.bird
        bird.physicsBody?.contactTestBitMask = PhysicsCategory.all
        bird.physicsBody?.collisionBitMask = PhysicsCategory.block | PhysicsCategory.edge
        bird.physicsBody?.isDynamic = false
        bird.position = anchor.position
        bird.zPosition = ZPosition.bird
        addChild(bird)
        bird.aspectScale(toSize: mapNode.tileSize, width: true, withMultiplier: 1.0)
        constraintToAnchor(active: true)
        roundState = .ready
    }
    
    func constraintToAnchor(active: Bool) {
        if active {
            let slingRange = SKRange(lowerLimit: 0.0, upperLimit: bird.size.width * 3)
            let positionConstraint = SKConstraint.distance(slingRange, to: anchor)
            bird.constraints = [positionConstraint]
        } else {
            bird.constraints?.removeAll()
        }
    }
    
    override func didSimulatePhysics() {
        guard let physicsBody = bird.physicsBody else { return }
        if roundState == .flying && physicsBody.isResting {
            gameCamera.setConstraints(withScene: self, andFrame: mapNode.frame, toNode: nil)
            bird.removeFromParent()
            roundState = .finished
        }
    }
    
}

//MARK: Extension for SKPhysics Contact Delegate Methods
extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        switch mask {
        case PhysicsCategory.bird | PhysicsCategory.block,
             PhysicsCategory.block | PhysicsCategory.edge:
            if let block = contact.bodyA.node as? Block {
                block.impact(withForce: Int(contact.collisionImpulse))
            } else if let block = contact.bodyB.node as? Block {
                block.impact(withForce: Int(contact.collisionImpulse))
            }
            if let bird = contact.bodyA.node as? Bird {
                bird.flying = false
            } else if let bird = contact.bodyB.node as? Bird {
                bird.flying = false
            }
        case PhysicsCategory.block | PhysicsCategory.block:
            if let block = contact.bodyA.node as? Block {
                block.impact(withForce: Int(contact.collisionImpulse))
            }
            if let blockB = contact.bodyB.node as? Block{
                blockB.impact(withForce: Int(contact.collisionImpulse))
            }
        case PhysicsCategory.bird | PhysicsCategory.edge:
            // We can directly use the bird property of our class
            bird.flying = false
        default:
            break
        }
    }
}

//MARK: - Extension for Gesture Recognizer methods
extension GameScene {
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        guard let view = view else { return }
        let translation = sender.translation(in: view) * gameCamera.yScale
        gameCamera.position = CGPoint(x: gameCamera.position.x - translation.x, y: gameCamera.position.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: view)
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        guard let view = view else { return }
        if sender.numberOfTouches == 2 {
            let locationInView = sender.location(in: view)
            let location = convertPoint(toView: locationInView)
            if sender.state == .changed {
                let convertedScale = 1 / sender.scale
                let newScale = gameCamera.yScale * convertedScale
                if newScale < maxScale && newScale > 0.5 {
                    gameCamera.setScale(newScale)
                }
                
                let locationAfterScale = convertPoint(toView: locationInView)
                let locationDelta = location - locationAfterScale
                let newPosition = gameCamera.position + locationDelta
                gameCamera.position = newPosition
                sender.scale = 1.0
                gameCamera.setConstraints(withScene: self, andFrame: mapNode.frame, toNode: nil)
            }
        }
    }
    
}
