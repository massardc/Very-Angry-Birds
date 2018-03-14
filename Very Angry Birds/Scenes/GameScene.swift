//
//  GameScene.swift
//  Very Angry Birds
//
//  Created by ClementM on 14/03/2018.
//  Copyright © 2018 ClementM. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    //MARK: - Variables
    var mapNode = SKTileMapNode()
    
    let gameCamera = GameCamera()
    var panRecognizer = UIPanGestureRecognizer()
    var pinchRecognizer = UIPinchGestureRecognizer()
    var maxScale: CGFloat = 0
    
    var bird = Bird(type: .red)
    let anchor = SKNode()
    
    override func didMove(to view: SKView) {
        setupLevel()
        setupGestureRecognizers()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)
            if bird.contains(touchLocation) {
                panRecognizer.isEnabled = false
                bird.grabbed = true
                bird.position = touchLocation
            }
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
        anchor.position = CGPoint(x: mapNode.frame.midX / 2, y: mapNode.frame.midY / 2)
        addChild(anchor)
        addBird()
    }
    
    func addCamera() {
        guard let view = view else { return }
        addChild(gameCamera)
        gameCamera.position = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
        camera = gameCamera
        gameCamera.setConstraints(withScene: self, andFrame: mapNode.frame, toNode: nil)
    }
    
    func addBird() {
        bird.position = anchor.position
        addChild(bird)
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
