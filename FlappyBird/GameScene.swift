//
//  GameScene.swift
//  FlappyBird
//
//  Created by amin.kuang on 2018/7/16.
//  Copyright © 2018年 amin.kuang. All rights reserved.
//

import SpriteKit
import GameplayKit

enum GameStatus {
    
    case idle
    case running
    case over
}

class GameScene: SKScene {
    
    let birdCategory: UInt32 = 0x1 << 0
    let pipeCategory: UInt32 = 0x1 << 1
    let floorCategory: UInt32 = 0x1 << 2
    
    lazy var floor1: SKSpriteNode = {
        
        let floor = SKSpriteNode(imageNamed: "floor")
        floor.anchorPoint = CGPoint(x: 0, y: 0)
        floor.position = CGPoint(x: 0, y: 0)
        
        return floor
    }()
    
    lazy var floor2: SKSpriteNode = {
        
        let floor = SKSpriteNode(imageNamed: "floor")
        floor.anchorPoint = CGPoint(x: 0, y: 0)
        floor.position = CGPoint(x: floor1.size.width, y: 0)
        
        return floor
    }()
    
    lazy var gameOverLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "Game Over"
        label.zPosition = 50
        return label
    }()
    
    lazy var metersLabel: SKLabelNode = {
        let label = SKLabelNode(text: "meters: 0")
        label.verticalAlignmentMode = .top
        label.horizontalAlignmentMode = .center
        return label
    }()
    
    var meters = 0 {
        didSet{
            metersLabel.text = "meters: \(meters)"
        }
    }
    
    var birdTextures: [SKTexture]!
    
    
    var bird: SKSpriteNode!
    
    var gameStatus = GameStatus.idle {
        
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name.init("GameSceneNotification"), object: gameStatus)
        }
    }
    
    override func didMove(to view: SKView) {
        
        backgroundColor = SKColor(red: 80.0/255, green: 192.0/255, blue: 203.0/255, alpha: 1.0)
        
        //给场景中的物理体添加边界，这个边界也是个物理体，它限制了游戏范围，其它物理体就不会跑出这个边界
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        
        /*
         SKPhysicsWorld，这个类基于场景，只能被修改但是不能被创建，这个类负责提供重力和检查碰撞
         
         设置物理世界的碰撞检测代理为场景自己，这样如果这个物理世界里面有两个可以碰撞接触的物理体碰到一起了就会通知他的代理
         */
        physicsWorld.contactDelegate = self
        
        //打印重力
        print(physicsWorld.gravity)
        
        birdTextures = loadTextures(imagePath: Bundle.main.path(forResource: "bird", ofType: "gif")!)
        
        addChild(floor1)
        
        addChild(floor2)
        
        //配置floor1物理体
        floor1.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: floor1.size.width, height: floor1.size.height))
        floor1.physicsBody?.categoryBitMask = floorCategory
        
        //配置floor2物理体
        floor2.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: floor2.size.width, height: floor2.size.height))
        floor2.physicsBody?.categoryBitMask = floorCategory
        
        bird = SKSpriteNode(texture: birdTextures[0])
        
        addChild(bird)
        
        bird.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.5)
        
        //配置小鸟物理体
        bird.physicsBody = SKPhysicsBody(texture: bird.texture!, size: bird.size)
        //禁止旋转
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = birdCategory
        //线性阻尼
        bird.physicsBody?.linearDamping = 0.3
        //质量(单位kg)
        bird.physicsBody?.mass = 0.04
        
        //设置可以让小鸟碰撞检测的物理体
        bird.physicsBody?.contactTestBitMask = floorCategory | pipeCategory
        
        metersLabel.position = CGPoint(x: size.width * 0.5, y: size.height)
        metersLabel.zPosition = 100
        addChild(metersLabel)
        
        //isDynamic表示这个物理体是否是动态的，默认是true
        bird.physicsBody?.isDynamic = false
        
        birdStartFly()
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        switch gameStatus {
        case .idle:

            startGame()

        case .running:

            //给小鸟施加一个冲量
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 20))
            
        case .over:
            return
            
        }
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
        if gameStatus != .over {
            moveScene()
        }
        
        if gameStatus == .running {
            meters += 1
        }
    }
    
    func shuffle() {
        
        gameStatus = .idle
        
        removeAllPipesNode()
        
        gameOverLabel.removeFromParent()
        
        bird.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.5)
        
        birdStartFly()
        
        bird.physicsBody?.isDynamic = false

    }
    
    func startGame() {
        
        gameStatus = .running
        
        bird.physicsBody?.isDynamic = true
        
        meters = 0
        
        startCreateRandomPipesAction()
    }
    
    func gameOver() {
        
        gameStatus = .over
        
        birdStopFly()
        
        stopCreateRandomPipesAction()
        
        isUserInteractionEnabled = false
        
        addChild(gameOverLabel)
        //设置gameOverLabel位置在屏幕顶部
        gameOverLabel.position = CGPoint(x: size.width * 0.5, y: size.height)
        //设置gameOverLabel通过一个动画action移动到屏幕中间
        gameOverLabel.run(SKAction.move(by: CGVector(dx: 0, dy: -size.height * 0.5), duration: 0.5)) {
            
            self.isUserInteractionEnabled = true
        }
    }
    
    //地面移动
    func moveScene() {
        
        floor1.position = CGPoint(x: floor1.position.x - 2, y: floor1.position.y)
        floor2.position = CGPoint(x: floor2.position.x - 2, y: floor2.position.y)
        
        if floor1.position.x < -floor2.size.width {
            floor1.position = CGPoint(x: floor2.position.x + floor2.size.width, y: floor1.position.y)
        }
        
        if floor2.position.x < -floor2.size.width {
            floor2.position = CGPoint(x: floor1.position.x + floor1.size.width, y: floor2.position.y)
        }
        
        for pipeNode in children where pipeNode.name == "pipe" {
            //因为我们要用到水管的size，但是SKNode没有size属性，所以要把它转成SKSpriteNode
            if let pipeSprite = pipeNode as? SKSpriteNode {
                //将水管左移与地面一样的位移
                pipeSprite.position = CGPoint(x: pipeSprite.position.x - 2, y: pipeSprite.position.y)
                //检查水管是否完全超出屏幕左侧了，如果是则将它从场景里移除掉
                if pipeSprite.position.x < -pipeSprite.size.width * 0.5 {
                    pipeSprite.removeFromParent()
                }
                
            }
        }
        
        
    }
    
    
    func birdStartFly() {
        
        let flyAction = SKAction.animate(with: birdTextures, timePerFrame: 0.12)
        
        bird.run(SKAction.repeatForever(flyAction), withKey: "fly")
        
    }
    
    func birdStopFly() {
        
        bird.removeAction(forKey: "fly")
        
    }
    
    //因为无法直接将gif动画在SpriteKit中播放，所以我们必须将gif中的一系列静态图片抽取出来然后形成一个动画帧
    func loadTextures(imagePath: String) -> [SKTexture]?{
        
        guard let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: imagePath) as CFURL, nil) else {
            return nil
        }
        
        let count = CGImageSourceGetCount(imageSource)
        var images:[CGImage] = []
        
        for i in 0..<count{
            guard let img = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else {continue}
            
            images.append(img)
        }
        
        return images.map {SKTexture(cgImage:$0)}
    }
    
    
    func addPipes(topSize: CGSize, bottomSize: CGSize) {
        
        //创建上水管
        //利用上水管图片创建一个上水管纹理对象
        let topTexture = SKTexture(imageNamed: "top_pipe")
        //利用上水管纹理对象和传入的上水管大小参数创建一个上水管对象
        let topPipe = SKSpriteNode(texture: topTexture, size: topSize)
        //给这个水管取个名字叫pipe
        topPipe.name = "pipe"
        //设置上水管的垂直位置为顶部贴着屏幕顶部，水平位置在屏幕右侧之外
        topPipe.position = CGPoint(x: self.size.width + topPipe.size.width * 0.5, y: self.size.height - topPipe.size.height * 0.5)
        
        //创建下水管
        let bottomTexture = SKTexture(imageNamed: "bottom_pipe")
        let bottomPipe = SKSpriteNode(texture: bottomTexture, size: bottomSize)
        bottomPipe.name = "pipe"
        bottomPipe.position = CGPoint(x: self.size.width + bottomPipe.size.width * 0.5, y: self.floor1.size.height + bottomPipe.size.height * 0.5)
        
        //配置上水管物理体
        topPipe.physicsBody = SKPhysicsBody(texture: topTexture, size: topSize)
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.categoryBitMask = pipeCategory
        
        //配置下水管物理体
        bottomPipe.physicsBody = SKPhysicsBody(texture: bottomTexture, size: bottomSize)
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.categoryBitMask = pipeCategory
        
        //将上下水管添加到场景里
        addChild(topPipe)
        addChild(bottomPipe)
        
    }
    
    //创造一对高度随机的上下水管
    func createRandomPipes() {
        
        //先计算地板顶部到屏幕顶部的总可用高度
        let height = self.size.height - self.floor1.size.height
        
        //计算上下水管中间的空档的随机高度，最小空档高度为2.5倍小鸟高度，最大为3.5倍小鸟高度
        let pipeGap = CGFloat(arc4random_uniform(UInt32(bird.size.height))) + bird.size.height * 2.5
        
        //水管宽度60
        let pipeWidth = CGFloat(60)
        
        //计算上水管的高度，这个高度要小于总的可用高度减去空档的高度
        let topPipeHeight = CGFloat(arc4random_uniform(UInt32(height - pipeGap)))
        
        //计算下水管高度
        let bottomPipeHeight = height - topPipeHeight - pipeGap
        
        let topSize = CGSize(width: pipeWidth, height: topPipeHeight)
        
        let bottomSize = CGSize(width: pipeWidth, height: bottomPipeHeight)
        
        addPipes(topSize: topSize, bottomSize: bottomSize)
        
    }
    
    
    func startCreateRandomPipesAction() {
        
        //创建一个等待的action，等待时间的平均值为3.5秒，变化范围为1秒
        let waitAction = SKAction.wait(forDuration: 4.5, withRange: 1)
        
        //创建一个产生随机水管的action，这个action实际上就是调用一下我们上面的createRandomPipes方法
        let generatePipeAction = SKAction.run {
            
            self.createRandomPipes()
        }
        
        run(SKAction.repeatForever(SKAction.sequence([waitAction, generatePipeAction])), withKey: "createPipe")
        
    }
    
    //停止创建水管
    func stopCreateRandomPipesAction() {
        
        removeAction(forKey: "createPipe")
    }
    
    //移除残留的水管
    func removeAllPipesNode() {
        
        for pipe in children where pipe.name == "pipe" {
            //循环检查场景的子节点，当这个子节点名字为pipe,从场景里移除
            pipe.removeFromParent()
        }
    }
    
    
}

extension GameScene: SKPhysicsContactDelegate
{
    func didBegin(_ contact: SKPhysicsContact) {
        //先检查游戏状态是否在运行中，如果不在运行中则不做操作，直接return
        if gameStatus != .running {
            return
        }
        
        //为了方便我们判断碰撞的bodyA和bodyB的categoryBitMask哪个小，小的则将它保存到新建的变量bodyA里的，大的则保存到新建变量bodyB里
        
        var bodyA: SKPhysicsBody
        
        var bodyB: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            
            bodyA = contact.bodyA
            bodyB = contact.bodyB
            
        }else{
            
            bodyA = contact.bodyB
            bodyB = contact.bodyA
        }
        
        //接下来判断bodyA是否为小鸟，bodyB是否为水管或者地面，如果是则游戏结束，直接调用gameOver()方法
        
        if (bodyA.categoryBitMask == birdCategory && bodyB.categoryBitMask == pipeCategory)||(bodyA.categoryBitMask == birdCategory && bodyB.categoryBitMask == floorCategory) {
            
            gameOver()
            
        }
        
    }
}

extension GameScene
{
    
    func startPlay() {

        shuffle()
    
    }

}
