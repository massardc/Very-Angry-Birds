//
//  Block.swift
//  Very Angry Birds
//
//  Created by ClementM on 18/03/2018.
//  Copyright © 2018 ClementM. All rights reserved.
//

import SpriteKit

enum BlockType: String {
    case glass, wood, stone
}

class Block: SKSpriteNode {

    let type: BlockType
    var health: Int
    let damageThreshold: Int
    
    init(type: BlockType) {
        self.type = type
        switch type {
        case .glass:
            health = 50
        case .wood:
            health = 200
        case .stone:
            health = 500
        }
        damageThreshold = health / 2
        
        let texture = SKTexture(imageNamed: type.rawValue)
        super.init(texture: texture, color: UIColor.clear, size: CGSize.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createPhysicsBody() {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = true
        physicsBody?.categoryBitMask = PhysicsCategory.block
        physicsBody?.contactTestBitMask = PhysicsCategory.all
        physicsBody?.collisionBitMask = PhysicsCategory.all
    }
    
    func impact(withForce force: Int) {
        health -= force
        if health < 1 {
            removeFromParent()
        } else if health < damageThreshold {
            texture = SKTexture(imageNamed: type.rawValue + "Broken")
        }
    }
    
    
}
