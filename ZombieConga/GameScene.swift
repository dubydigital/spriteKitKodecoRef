//
//  GameScene.swift
//  ZombieConga
//
//  Created by Mark Dubouzet on 2/20/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    // Game attributes
    var lives = 5
    var catsEaten = 0
    var gameOver = false
    let eatenCatsWinAmount = 10
    
    // Labels
    let livesLabel = SKLabelNode(fontNamed: "Glimstick")
    let catsEatenLabel = SKLabelNode(fontNamed: "Arial")
    
    // Sounds
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false  )
    
    // Play Area
    let playableRect: CGRect
    
    // Assets
    let background = SKSpriteNode(imageNamed: "background1")
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    let zombieAnimation: SKAction
        
    let zombieMovePointsPerSec: CGFloat = 1000.0
    
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    var velocity = CGPoint.zero
    var lastTouchLocation: CGPoint?
    
    override init(size: CGSize) {
        
        // Define Max Aspect ratio
        let maxAspectRatio: CGFloat = 16.0/9.0
        
        // Define Playable Margins
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight) / 2.0
        
        // Define Playable Rect
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        
        // Zombie Animation
        var textures:[SKTexture] = []
        for i in 1...4 {
            // Loop to add textures
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
//            print("zombie\(i)")
        }
        // add addtional textures
        textures.append(SKTexture(imageNamed: "zombie3"))
        textures.append(SKTexture(imageNamed: "zombie2"))
        textures.append(SKTexture(imageNamed: "zombie1"))
        
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)

        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Labels
    
    func addLabels() {
        livesLabel.text = "Lives: \(lives)"
        livesLabel.fontColor = SKColor.red
        livesLabel.fontSize = 100
        livesLabel.zPosition = 100
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .bottom
        livesLabel.position = CGPoint(x: 20, y: size.height/6)
        addChild(livesLabel)
        
        // System Font sample
        let label = SKLabelNode(text: "bon appetit")
        label.fontSize = 50
        label.position = CGPoint(x: 800, y: 100)
        self.addChild(label)
       
       
        // Arial Label
        catsEatenLabel.text = "Cats Eaten: 0"
        catsEatenLabel.fontSize = 60
        catsEatenLabel.position = CGPoint(x: 200, y: 100)
        self.addChild(catsEatenLabel)

    }
    
    // MARK: - Scene Methods:
    override func sceneDidLoad() {
        print("sceneDidLoad")
    }
    
    override func didMove(to view: SKView) {
        
        playBackgroundMusic(filename: "backgroundMusic.mp3")
        
        setupBgGame()
        // Zombie
        setUpZombie()
        
        //  Spawn enemy
        spawnEnemyAction()
                
        // Spawn Cat
        spawnCatAction()
        
        // Add Labels
        addLabels()
        // Debug
//        debugDrawPlayableArea()
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }

        lastUpdateTime = currentTime

        if let lastTouchLocation = lastTouchLocation {
            let diff = lastTouchLocation - zombie.position
            if diff.length() <= zombieMovePointsPerSec * CGFloat(dt) {
                // Stops Zombie
                zombie.position = lastTouchLocation
                velocity = CGPoint.zero
                
                // Stop animation when idle
                zombie.removeAction(forKey: "zombieAnimation")
            } else {
                // Keeps zombie moving
                moveSprite(sprite: zombie, velocity: velocity)
                
                // Rotate towards movement direction
                let angle = atan2(velocity.y, velocity.x)
                zombie.zRotation = angle

                // Start animation if not already running
                if zombie.action(forKey: "zombieAnimation") == nil {
                    zombie.run(SKAction.repeatForever(zombieAnimation), withKey: "zombieAnimation")
                }
            }
        }

        // Check Zombie Bounds
        boundsCheckZombie()
        
        // Collision
//        checkCollisions() call in didEvaluateActions instead
        if lives <= 0 && !gameOver {
            gameOver = true
            print("You Lose!")
            backgroundMusicPlayer.stop()
            
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
        
        if catsEaten >= eatenCatsWinAmount {
            gameOver = true
            print("You Win!")
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
        
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }

    
    // MARK: - Touches Methods:
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        lastTouchLocation = touchLocation
        moveZombieToward(location: touchLocation)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        lastTouchLocation = touchLocation
        moveZombieToward(location: touchLocation)
    }
    
    // MARK: - Game Methods:
    func setupBgGame() {
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) // default
        background.zPosition = -1
        addChild(background)
    }
    
    func setUpZombie() {
        zombie.position  = CGPoint(x: 400, y:400)
        addChild(zombie)
//        zombie.run(SKAction.repeatForever(zombieAnimation))
    }
    
    // MARK: - Enemy
    func spawnEnemyAction() {
        run(SKAction.repeatForever( SKAction.repeatForever(
            SKAction.sequence( [SKAction.run(spawnEnemy),
            SKAction.wait(forDuration: 2.0)]   )  )
            )
        )
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        enemy.position = CGPoint(
            x: size.width + enemy.size.width/2,
            y: CGFloat.random( min: CGRectGetMinY(playableRect) + enemy.size.height/2,
                               max: CGRectGetMaxY(playableRect) - enemy.size.height/2)
        )
//        print("size.width: \(size.width)")
        addChild(enemy)
        
        let actionMove = SKAction.moveTo(x: -enemy.size.width/2, duration: 3.0 )
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
        
    // MARK: - Cat
    func spawnCatAction() {
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(spawnCat), SKAction.wait(forDuration: 1.0)  ])
        ))
    }
    
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(
            x: CGFloat.random(min: CGRectGetMinX(playableRect),
                              max: CGRectGetMaxX(playableRect)),
            y: CGFloat.random(min: CGRectGetMinY(playableRect),
                              max: CGRectGetMaxY(playableRect))
            )
            cat.setScale(0)
            addChild(cat)
        
        let appear = SKAction.scale(to: 1.0, duration:  0.5)
        cat.zRotation = -π / 16.0
        let wait = SKAction.wait(forDuration: 10)
        let disappear = SKAction.scale(to: 0, duration:  0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, wait, disappear, removeFromParent ]
        cat.run(SKAction.sequence(actions))
    }
    
    // MARK: - Collision
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodes(withName: "cat", using: { node, _ in
            let cat = node as! SKSpriteNode
            if CGRectIntersectsRect(cat.frame, self.zombie.frame ) {
                hitCats.append(cat)
            }
        })
        
        for cat in hitCats {
            print("hit: \(cat.name ?? "no cat name") ")
            zombieHitCat(cat: cat)
        }
        
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodes(withName: "enemy", using: { node, _ in
            let enemy = node as! SKSpriteNode
            if CGRectIntersectsRect(CGRectInset(enemy.frame, 20, 20),
                                    self.zombie.frame) {
                hitEnemies.append(enemy)
            }
        })
        
        for enemy in hitEnemies {
            print("hit: \(enemy.name ?? "no enemy name")")
            zombieHitEnemy(enemy: enemy)
        }
         
    }
    
    func zombieHitCat(cat: SKSpriteNode) {
        cat.removeFromParent()
        run(catCollisionSound)
        catsEaten += 1
        
        catsEatenLabel.text = "Cats eaten: \(catsEaten)"
        
        print("catsEaten: \(catsEaten)")
    }
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
        enemy.removeFromParent()
        run(enemyCollisionSound)
        lives -= 1
         
        // Update Lives Label
        livesLabel.text = "Lives: \(lives)"
        
        // Blicking Effect
        let blinkTimes = 5.0
        let duration = 1.5
        let blinkAction = SKAction.customAction(withDuration: duration, actionBlock: { node,    elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime) % slice
            node.isHidden = remainder > slice / 2
        })
        
        let setHidden = SKAction.run() {
            self.zombie.isHidden = false
        }
        
        zombie.run(SKAction.sequence([blinkAction, setHidden]))
    }
    
    // MARK: - Movement
    
//    func moveTrain() {
//        var trainCount = 0
//        var targetPosition = zombie.position
//        
//        enumerateChildNodes(withName: "train", using: { node, stop in
//            if !node.hasActions() {
//                
//                let actionDuration = 0.3
//                let offset = targetPosition - node.position
//                let direction = offset.normalized()
//                let amountToMovePerSec = direction * self.catMovePointsPersec
//                
//                
//            }
//                
//            
//        })
//    }
//    
    func moveZombieToward(location: CGPoint ) {
        let offset = CGPoint(x: location.x - zombie.position.x, y: location.y - zombie.position.y)
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length) )
        velocity = CGPoint(x: direction.x * zombieMovePointsPerSec, y: direction.y * zombieMovePointsPerSec)
        
        // Calculate angle to rotate, rotates zombie towards direction
           let angle = atan2(velocity.y, velocity.x)
           zombie.run(SKAction.rotate(toAngle: angle, duration: 0.1, shortestUnitArc: true))
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint ) {
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt), y: velocity.y * CGFloat(dt))
        sprite.position =  CGPoint(x: sprite.position.x + amountToMove.x, y: sprite.position.y + amountToMove.y )
        print("\n---------\n velocity: \(velocity)  \n sprite.position: \(sprite.position) \n amountToMove: \(amountToMove) \n dt: \(dt) ")
    }
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: 0, y: CGRectGetMinY(playableRect))
        let topRight = CGPoint(x: size.width, y: CGRectGetMaxY(playableRect))
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
//            velocity.x = -velocity.x
            velocity = CGPointZero
        }
        
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
//            velocity.x = -velocity.x
            velocity = CGPointZero
        }
        
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
//            velocity.y = -velocity.y
            velocity = CGPointZero
        }
        
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
//            velocity.y = -velocity.y
            velocity = CGPointZero
        }
    }
    
    // MARK: Debug
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 40
        addChild(shape)
    }
    
}
