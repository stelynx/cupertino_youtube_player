//
//  ClientCertChallenge.swift
//  flutter_inappwebview
//
//  Created by Lorenzo Pichilli on 15/02/21.
//

import Foundation

class ClientCertChallenge: NSObject {
    var protectionSpace: URLProtectionSpace!
    
    public init(fromChallenge: URLAuthenticationChallenge) {
        protectionSpace = fromChallenge.protectionSpace
    }
    
    public func toMap () -> [String:Any?] {
        return [
            "protectionSpace": protectionSpace.toMap(),
        ]
    }
}
