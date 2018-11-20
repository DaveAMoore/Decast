//
//  ViewController.swift
//  Decast
//
//  Created by David Moore on 11/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import SFKit
import RemoteKit

class ViewController: UIViewController, RKSessionManagerDelegate, RKSessionDelegate, RKTrainingSessionDelegate {

    let session = RKSession(device: RKDevice(serialNumber: "LE2RDNFR44"))
    
    var trainingSession: RKTrainingSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        session.delegate = self
        session.sessionManager.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        session.activate()
    }
    
    func sessionManager(_ sessionManager: RKSessionManager, presentAuthenticationViewController viewController: UIViewController) {
        present(viewController, animated: false, completion: nil)
    }
    
    func sessionDidActivate(_ session: RKSession) {
        print("Session activated")
        session.send(RKCommand(localizedTitle: "123", commandID: "KEY_POWER"), for: RKRemote(localizedTitle: "Remote"))
    }
    
    func session(_ session: RKSession, didFailWithError error: Error) {
        print("Session failed to activate with error: \(error.localizedDescription)")
    }
    
    func session(_ session: RKSession, didSendCommand command: RKCommand, forRemote remote: RKRemote) {
        print("Session did send \(command) for \(remote)")
        trainingSession = session.newTrainingSession(for: RKRemote(localizedTitle: "Foo"))
        trainingSession?.delegate = self
        session.start(trainingSession!)
    }
    
    func session(_ session: RKSession, didFailToSendCommand command: RKCommand, forRemote remote: RKRemote, withError error: Error) {
        print("Session did fail to send \(command) for \(remote) with error: \(error.localizedDescription)")
    }
    
    func trainingSessionDidBegin(_ trainingSession: RKTrainingSession) {
        print("Training session did begin")
        trainingSession.createCommand(withLocalizedTitle: "Bar")
    }
    
    func trainingSession(_ trainingSession: RKTrainingSession, didCreateCommand command: RKCommand) {
        print("Training session did create \(command)")
        session.suspend(trainingSession)
    }
    
    func trainingSession(_ trainingSession: RKTrainingSession, didFailToCreateCommandWithError error: Error) {
        print("Training session did fail to create command: \(error.localizedDescription)")
    }
    
    func trainingSession(_ trainingSession: RKTrainingSession, didFailWithError error: Error) {
        
    }
    
    func trainingSession(_ trainingSession: RKTrainingSession, willLearnCommand command: RKCommand) {
        
    }
    
    func trainingSession(_ trainingSession: RKTrainingSession, didLearnCommand command: RKCommand) {
        
    }
    
    func trainingSessionDidRequestInclusiveArbitraryInput(_ trainingSession: RKTrainingSession) {
        
    }
    
    func trainingSession(_ trainingSession: RKTrainingSession, didRequestInputForCommand command: RKCommand) {
        
    }
    
    func trainingSessionDidRequestExclusiveArbitraryInput(_ trainingSession: RKTrainingSession) {
        
    }
}

