//
//  WebMessageListener.swift
//  flutter_inappwebview
//
//  Created by Lorenzo Pichilli on 10/03/21.
//

import Foundation
import WebKit

public class WebMessageListener : FlutterMethodCallDelegate {

    var jsObjectName: String
    var allowedOriginRules: Set<String>
    var channel: FlutterMethodChannel?
    var webView: InAppWebView?
    
    public init(jsObjectName: String, allowedOriginRules: Set<String>) {
        self.jsObjectName = jsObjectName
        self.allowedOriginRules = allowedOriginRules
        super.init()
        self.channel = FlutterMethodChannel(name: "com.pichillilorenzo/flutter_inappwebview_web_message_listener_" + self.jsObjectName,
                                       binaryMessenger: SwiftFlutterPlugin.instance!.registrar!.messenger())
        self.channel?.setMethodCallHandler(self.handle)
    }
    
    public func assertOriginRulesValid() throws {
        for (index, originRule) in allowedOriginRules.enumerated() {
            if originRule.isEmpty {
                throw NSError(domain: "allowedOriginRules[\(index)] is empty", code: 0)
            }
            if originRule == "*" {
                continue
            }
            if let url = URL(string: originRule) {
                guard let scheme = url.scheme else {
                    throw NSError(domain: "allowedOriginRules \(originRule) is invalid", code: 0)
                }
                if scheme == "http" || scheme == "https", url.host == nil || url.host!.isEmpty {
                    throw NSError(domain: "allowedOriginRules \(originRule) is invalid", code: 0)
                }
                if scheme != "http", scheme != "https", url.host != nil || url.port != nil {
                    throw NSError(domain: "allowedOriginRules \(originRule) is invalid", code: 0)
                }
                if url.host == nil || url.host!.isEmpty, url.port != nil {
                    throw NSError(domain: "allowedOriginRules \(originRule) is invalid", code: 0)
                }
                if !url.path.isEmpty {
                    throw NSError(domain: "allowedOriginRules \(originRule) is invalid", code: 0)
                }
                if let hostname = url.host {
                    if let firstIndex = hostname.firstIndex(of: "*") {
                        let distance = hostname.distance(from: hostname.startIndex, to: firstIndex)
                        if distance != 0 || (distance == 0 && hostname.prefix(2) != "*.") {
                            throw NSError(domain: "allowedOriginRules \(originRule) is invalid", code: 0)
                        }
                    }
                    if hostname.hasPrefix("[") {
                        if !hostname.hasSuffix("]") {
                            throw NSError(domain: "allowedOriginRules \(originRule) is invalid", code: 0)
                        }
                        let fromIndex = hostname.index(hostname.startIndex, offsetBy: 1)
                        let toIndex = hostname.index(hostname.startIndex, offsetBy: hostname.count - 1)
                        let indexRange = Range<String.Index>(uncheckedBounds: (lower: fromIndex, upper: toIndex))
                        let ipv6 = String(hostname[indexRange])
                        if !Util.isIPv6(address: ipv6) {
                            throw NSError(domain: "allowedOriginRules \(originRule) is invalid", code: 0)
                        }
                    }
                }
            } else {
                throw NSError(domain: "allowedOriginRules \(originRule) is invalid", code: 0)
            }
        }
    }
    
    public func initJsInstance(webView: InAppWebView) {
        self.webView = webView
        if let webView = self.webView {
            let jsObjectNameEscaped = jsObjectName.replacingOccurrences(of: "\'", with: "\\'")
            let allowedOriginRulesString = allowedOriginRules.map { (allowedOriginRule) -> String in
                if allowedOriginRule == "*" {
                    return "'*'"
                }
                let rule = URL(string: allowedOriginRule)!
                let host = rule.host != nil ? "'" + rule.host!.replacingOccurrences(of: "\'", with: "\\'") + "'" : "null"
                return """
                {scheme: '\(rule.scheme!)', host: \(host), port: \(rule.port != nil ? String(rule.port!) : "null")}
                """
            }.joined(separator: ", ")
            let source = """
            (function() {
                var allowedOriginRules = [\(allowedOriginRulesString)];
                var isPageBlank = window.location.href === "about:blank";
                var scheme = !isPageBlank ? window.location.protocol.replace(":", "") : null;
                var host = !isPageBlank ? window.location.hostname : null;
                var port = !isPageBlank ? window.location.port : null;
                if (window.\(JAVASCRIPT_BRIDGE_NAME)._isOriginAllowed(allowedOriginRules, scheme, host, port)) {
                    window['\(jsObjectNameEscaped)'] = new FlutterInAppWebViewWebMessageListener('\(jsObjectNameEscaped)');
                }
            })();
            """
            webView.configuration.userContentController.addPluginScript(PluginScript(
                groupName: "WebMessageListener-" + jsObjectName,
                source: source,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false,
                requiredInAllContentWorlds: false,
                messageHandlerNames: ["onWebMessageListenerPostMessageReceived"]
            ))
            webView.configuration.userContentController.sync(scriptMessageHandler: webView)
        }
    }
    
    public static func fromMap(map: [String:Any?]?) -> WebMessageListener? {
        guard let map = map else {
            return nil
        }
        return WebMessageListener(
            jsObjectName: map["jsObjectName"] as! String,
            allowedOriginRules: Set(map["allowedOriginRules"] as! [String])
        )
    }
    
    public override func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        
        switch call.method {
        case "postMessage":
            if let webView = webView {
                let jsObjectNameEscaped = jsObjectName.replacingOccurrences(of: "\'", with: "\\'")
                let messageEscaped = (arguments!["message"] as! String).replacingOccurrences(of: "\'", with: "\\'")
                let source = """
                (function() {
                    var webMessageListener = window['\(jsObjectNameEscaped)'];
                    if (webMessageListener != null) {
                        var event = {data: '\(messageEscaped)'};
                        if (webMessageListener.onmessage != null) {
                            webMessageListener.onmessage(event);
                        }
                        for (var listener of webMessageListener.listeners) {
                            listener(event);
                        }
                    }
                })();
                """
                webView.evaluateJavascript(source: source) { (_) in
                    result(true)
                }
            } else {
               result(true)
            }
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    public func isOriginAllowed(scheme: String?, host: String?, port: Int?) -> Bool {
        for allowedOriginRule in allowedOriginRules {
            if allowedOriginRule == "*" {
                return true
            }
            if scheme == nil || scheme!.isEmpty {
                continue
            }
            if scheme == nil || scheme!.isEmpty, host == nil || host!.isEmpty, port == nil || port == 0 {
                continue
            }
            if let rule = URL(string: allowedOriginRule) {
                let rulePort = rule.port == nil || rule.port == 0 ? (rule.scheme == "https" ? 443 : 80) : rule.port!
                let currentPort = port == nil || port == 0 ? (scheme == "https" ? 443 : 80) : port!
                var IPv6: String? = nil
                if let hostname = rule.host, hostname.hasPrefix("[") {
                    let fromIndex = hostname.index(hostname.startIndex, offsetBy: 1)
                    let toIndex = hostname.index(hostname.startIndex, offsetBy: hostname.count - 1)
                    let indexRange = Range<String.Index>(uncheckedBounds: (lower: fromIndex, upper: toIndex))
                    do {
                        IPv6 = try Util.normalizeIPv6(address: String(hostname[indexRange]))
                    } catch {}
                }
                var hostIPv6: String? = nil
                if let host = host, Util.isIPv6(address: host) {
                    do {
                        hostIPv6 = try Util.normalizeIPv6(address: host)
                    } catch {}
                }
                
                let schemeAllowed = scheme != nil && !scheme!.isEmpty && scheme == rule.scheme
                
                let hostAllowed = rule.host == nil ||
                    rule.host!.isEmpty ||
                    host == rule.host ||
                    (rule.host!.hasPrefix("*") && host != nil && host!.hasSuffix(rule.host!.split(separator: "*", omittingEmptySubsequences: false)[1])) ||
                    (hostIPv6 != nil && IPv6 != nil && hostIPv6 == IPv6)
                
                let portAllowed = rulePort == currentPort
                
                if schemeAllowed, hostAllowed, portAllowed {
                    return true
                }
            }
        }
        return false
    }
    
    public func onPostMessage(message: String?, sourceOrigin: URL?, isMainFrame: Bool) {
        let arguments: [String:Any?] = [
            "message": message,
            "sourceOrigin": sourceOrigin?.absoluteString,
            "isMainFrame": isMainFrame
        ]
        channel?.invokeMethod("onPostMessage", arguments: arguments)
    }

    public func dispose() {
        channel?.setMethodCallHandler(nil)
        channel = nil
        webView = nil
    }
    
    deinit {
        print("WebMessageListener - dealloc")
        dispose()
    }
}
