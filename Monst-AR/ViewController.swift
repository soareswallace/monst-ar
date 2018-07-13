//
//  ViewController.swift
//  Monst-AR
//
//  Created by Wallace Junior on 11/07/18.
//  Copyright © 2018 Wallace Junior. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var trackerNode: SCNNode!
    var mainContainer: SCNNode!
    var gameHasStarted = false
    var foundSurface = false
    var gamePos = SCNVector3Make(0.0, 0.0, 0.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/Scene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func randomPosition() -> SCNVector3{
        let randomX = (Float(arc4random_uniform(200))/100.0) - 1.0
        let randomY = (Float(arc4random_uniform(200))/100.0) + 1.5
        
        return SCNVector3Make(randomX, randomY, -3.0)
    }
    
    @objc func addPlane() {
        let planeNode = sceneView.scene.rootNode.childNode(withName: "plane", recursively: false)?.copy() as! SCNNode
        planeNode.isHidden = false
        planeNode.position = randomPosition()
        
        mainContainer.addChildNode(planeNode)
        
        let randSpeed = SCNVector3Make(0.0, 0.0, Float(arc4random_uniform(2) + 4))
        planeNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        planeNode.physicsBody?.isAffectedByGravity = false
        planeNode.physicsBody?.applyForce(randSpeed, asImpulse: true)
        
        let planeDissapearAction = SCNAction.sequence([SCNAction.wait(duration: 10.0), SCNAction.fadeOut(duration: 1.0), SCNAction.removeFromParentNode()])
        planeNode.runAction(planeDissapearAction)
        
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(addPlane), userInfo: nil, repeats: false)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameHasStarted{
            //Plane Crashsing stuf later in part 3
            guard let touch = touches.first else { return }
            
            let touchLocation = touch.location(in: view)
            
            guard let nodeHitTest = sceneView.hitTest(touchLocation, options: nil).first else { return }
            let hitNode = nodeHitTest.node
            
            guard hitNode.name == "plane" else { return }
            
            let planeSpinForce = SCNVector4Make(0.5, 0.0, 1.0, 50)
            hitNode.physicsBody?.isAffectedByGravity = true
            hitNode.physicsBody?.applyTorque(planeSpinForce, asImpulse: true)
            
        }
        else{
            guard foundSurface else { return }
            trackerNode.removeFromParentNode()
            gameHasStarted = true
            
            
            mainContainer = sceneView.scene.rootNode.childNode(withName: "mainContainer", recursively: false)!
            mainContainer.isHidden = false
            mainContainer.position = gamePos
            
            addPlane()
            
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambientLight.color = UIColor.white
            ambientLight.intensity = 1000
            
            let ambientLightNode = SCNNode()
            ambientLightNode.light = ambientLight
            ambientLightNode.position.y = 3.0
            
            mainContainer.addChildNode(ambientLightNode)
            
            let omniLight = SCNLight()
            omniLight.type = .omni
            omniLight.color = UIColor.white
            omniLight.intensity = 500
            
            let omniLightNode = SCNNode()
            omniLightNode.light = omniLight
            omniLightNode.position.y = 3.0
            
            mainContainer.addChildNode(omniLightNode)
            
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard !gameHasStarted else { return } //if the statement is true pass
        guard let hitTest = sceneView.hitTest(CGPoint(x: view.frame.midX, y: view.frame.midY ), types: [.existingPlane, .featurePoint]).last else { return }
        let trans = SCNMatrix4(hitTest.worldTransform)
        gamePos = SCNVector3Make(trans.m41, trans.m42, trans.m43)
        if !foundSurface{
            let trackerPlane = SCNPlane(width: 0.3, height: 0.3)
            trackerPlane.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "target")
            
            trackerNode = SCNNode(geometry: trackerPlane)
            trackerNode.eulerAngles.x = .pi * -0.5
            sceneView.scene.rootNode.addChildNode(trackerNode)
        }
        trackerNode.position = gamePos
        foundSurface = true
        
        
    }
}
