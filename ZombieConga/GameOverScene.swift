//
//  GameOverScene.swift
//  ZombieConga
//
//  Created by Mark Dubouzet on 2/21/25.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    let won: Bool
    
    init(size: CGSize, won: Bool) {
        self.won = won
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
      
    override func didMove(to view: SKView) {
        var background: SKSpriteNode
        if (won) {
            background = SKSpriteNode(imageNamed: "YouWin")
            run(SKAction.sequence([ SKAction.wait(forDuration: 0.1),
                                    SKAction.playSoundFileNamed("win.wav", waitForCompletion: false)]   ))
        } else {
            background = SKSpriteNode(imageNamed: "YouLose")
            run(SKAction.sequence([SKAction.wait(forDuration: 0.1),
                                   SKAction.playSoundFileNamed("lose.wav", waitForCompletion: false)] ))
        }
        
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        self.addChild(background)
        
        let wait = SKAction.wait(forDuration: 3.0)
        let block = SKAction.run {
            let myScene = GameScene(size: self.size)
            myScene.scaleMode = self.scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            self.view?.presentScene(myScene, transition: reveal)
        }
         
        self.run(SKAction.sequence([wait, block]))
    }
    
    
}
