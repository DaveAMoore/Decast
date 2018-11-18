//
//  ViewController.swift
//  Decast
//
//  Created by David Moore on 11/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import SFKit
import RemoteKit
import AWSCore

class ViewController: UIViewController, RKSessionManagerDelegate {

    let session = RKSession(device: RKDevice(serialNumber: "LE2RDNFR44"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AWSDDLog.add(AWSDDTTYLogger(), with: .verbose)
        
        // Do any additional setup after loading the view, typically from a nib.
        session.sessionManager.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        session.activate()
    }
    
    func sessionManager(_ sessionManager: RKSessionManager, presentAuthenticationViewController viewController: UIViewController) {
        present(viewController, animated: false, completion: nil)
    }
}

