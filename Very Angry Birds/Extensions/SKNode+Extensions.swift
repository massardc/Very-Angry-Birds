//
//  SKNode+Extensions.swift
//  Very Angry Birds
//
//  Created by ClementM on 19/03/2018.
//  Copyright © 2018 ClementM. All rights reserved.
//

import SpriteKit

extension SKNode {
    
    func aspectScale(toSize size: CGSize, width: Bool, withMultiplier multiplier: CGFloat) {
        let scale = width ? (size.width * multiplier) / self.frame.size.width : (size.height * multiplier) / self.frame.size.height
        self.setScale(scale)
    }
    
}
