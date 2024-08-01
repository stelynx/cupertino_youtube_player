//
//  InAppWebViewUserScript.swift
//  flutter_inappwebview
//
//  Created by Lorenzo Pichilli on 16/02/21.
//

import Foundation
import WebKit

public class UserScript : WKUserScript {
    var groupName: String?

    private var contentWorldWrapper: Any?
    @available(iOS 14.0, *)
    var contentWorld: WKContentWorld {
      get {
        if let value = contentWorldWrapper as? WKContentWorld {
          return value
        }
        return .page
      }
      set { contentWorldWrapper = newValue }
    }

    
    public override init(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) {
        super.init(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
    }
    
    public init(groupName: String?, source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) {
        super.init(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
        self.groupName = groupName
    }
    
    @available(iOS 14.0, *)
    public override init(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool, in contentWorld: WKContentWorld) {
        super.init(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly, in: contentWorld)
        self.contentWorld = contentWorld
    }

    @available(iOS 14.0, *)
    public init(groupName: String?, source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool, in contentWorld: WKContentWorld) {
        super.init(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly, in: contentWorld)
        self.groupName = groupName
        self.contentWorld = contentWorld
    }
    
    public static func fromMap(map: [String:Any?]?, windowId: Int64?) -> UserScript? {
        guard let map = map else {
            return nil
        }
        
        let contentWorldMap = map["contentWorld"] as? [String:Any?]
        if #available(iOS 14.0, *), let contentWorldMap = contentWorldMap {
            let contentWorld = WKContentWorld.fromMap(map: contentWorldMap, windowId: windowId)!
            return UserScript(
                groupName: map["groupName"] as? String,
                source: map["source"] as! String,
                injectionTime: WKUserScriptInjectionTime.init(rawValue: map["injectionTime"] as! Int) ?? .atDocumentStart,
                forMainFrameOnly: map["iosForMainFrameOnly"] as! Bool,
                in: contentWorld
            )
        }
        return UserScript(
            groupName: map["groupName"] as? String,
            source: map["source"] as! String,
            injectionTime: WKUserScriptInjectionTime.init(rawValue: map["injectionTime"] as! Int) ?? .atDocumentStart,
            forMainFrameOnly: map["iosForMainFrameOnly"] as! Bool
        )
    }
}
