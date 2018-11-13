//
//  Test.swift
//  RemoteKit
//
//  Created by David Moore on 11/9/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import Foundation
import AWSIoT

public class Test: NSObject {
    
    public func test() {
        let i = AWSIoTDataPublishRequest()!
        i.payload = ""
        i.topic = "/"
        AWSIoTData.default().publish(<#T##request: AWSIoTDataPublishRequest##AWSIoTDataPublishRequest#>, completionHandler: <#T##((Error?) -> Void)?##((Error?) -> Void)?##(Error?) -> Void#>)
    }
}
