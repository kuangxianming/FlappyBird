//
//  GameViewController.swift
//  FlappyBird
//
//  Created by amin.kuang on 2018/7/16.
//  Copyright © 2018年 amin.kuang. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

fileprivate extension Selector {
    
   static let startBtnClick = #selector(GameViewController.startBtnEvent(sender:))
    
}

class GameViewController: UIViewController {

    var startBtn: UIButton!
    
    weak var gameScene: GameScene!
    var isFirstPlay = true {
        didSet {
            guard !isFirstPlay else {return}
            
            startBtn.setTitle("restart", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            //代码创建scene
            let scene = GameScene(size: view.bounds.size)
            gameScene = scene
            
            gameScene.addObserver(self, forKeyPath: "gameStatus", options: .new, context: nil)
            
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
        
            // Present the scene
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
            //显示物理体外框
//            view.showsPhysics = true
            
            //创建游戏开始按钮
            startBtn = UIButton(type: .custom)
            startBtn.setTitle("start", for: .normal)
            startBtn.setTitleColor(.green, for: .normal)
            startBtn.titleLabel?.font = UIFont(name: "Chalkduster", size: 17)
            startBtn.frame = CGRect(x: (view.bounds.size.width - 80) * 0.5, y: 200, width: 80, height: 40)
            startBtn.layer.borderWidth = 1
            startBtn.layer.borderColor = UIColor.orange.cgColor
            startBtn.layer.cornerRadius = 2
            startBtn.layer.masksToBounds = true
            view.addSubview(startBtn)
            startBtn.addTarget(self, action: .startBtnClick, for: .touchUpInside)
            
            //接收通知
            NotificationCenter.default.addObserver(self, selector: #selector(resetStartBtn(noti:)), name: NSNotification.Name("GameSceneNotification"), object: nil)
            
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func startBtnEvent(sender: UIButton) {
        
        gameScene.startPlay()
        isFirstPlay = false
    
    }
    
    @objc func resetStartBtn(noti: Notification) {
        
        if let newStatus = noti.object as? GameStatus {
            
            if newStatus == GameStatus.over {
                startBtn.isHidden = false
            }else{
                startBtn.isHidden = true
            }
            
        }
        
    }
    
}



