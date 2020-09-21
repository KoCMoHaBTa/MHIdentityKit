//
//  ImplicitGrantFlowInputViewController.swift
//  MHIdentityKit-macOSTestsHost
//
//  Created by Milen Halachev on 1.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import Cocoa
import MHIdentityKit

class ImplicitGrantFlowInputViewController: NSViewController {
    
    @IBOutlet weak var clientTextField: NSTextField!
    @IBOutlet weak var scopeTextField: NSTextField!
    @IBOutlet weak var authorizationURLTextField: NSTextField!
    @IBOutlet weak var redirectURLTextField: NSTextField!
    
    private var accessTokenRequest: URLRequest?
    private var accessTokenResponse: AccessTokenResponse?
    private var accessTokenError: Error?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    private func setErrorIndicator(to textField: NSTextField) {
        
        textField.layer?.borderColor = NSColor.red.cgColor
        textField.layer?.borderWidth = 1
        textField.layer?.masksToBounds = true
        textField.layer?.cornerRadius = 4
    }
    
    private func clearErrorIndicator(from textField: NSTextField) {
        
        textField.layer?.borderColor = nil
        textField.layer?.borderWidth = 0
        textField.layer?.masksToBounds = false
        textField.layer?.cornerRadius = 0
    }
    
    private func clearErrorIndicatorFromAllTextFields() {
        
        self.clearErrorIndicator(from: self.clientTextField)
        self.clearErrorIndicator(from: self.scopeTextField)
        self.clearErrorIndicator(from: self.authorizationURLTextField)
        self.clearErrorIndicator(from: self.redirectURLTextField)
    }
    
    private func clearResult() {
        
        self.accessTokenRequest = nil
        self.accessTokenResponse = nil
        self.accessTokenError = nil
    }
    
    private func showResult() {
        
        let accessTokenRequestAvailable = self.accessTokenRequest != nil
        let accessTokenResponseAvailable = self.accessTokenResponse != nil
        let accessTokenErrorAvailable = self.accessTokenError != nil
        
        let title = "Result summary"
        let message =
        """
        Access token request: \(accessTokenRequestAvailable ? "available" : "none")
        Access token response: \(accessTokenResponseAvailable ? "available" : "none")
        Access token error: \(accessTokenErrorAvailable ? "available" : "none")
        """
        
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "Close")
        
        if accessTokenRequestAvailable, let _ = self.accessTokenRequest {
            
            let button = alert.addButton(withTitle: "View access token request")
            button.target = self
            button.action = #selector(viewAccessTokenRequest(_:))
        }
        
        if accessTokenResponseAvailable, let _ = self.accessTokenResponse {
            
            let button = alert.addButton(withTitle: "View access token response")
            button.target = self
            button.action = #selector(viewAccessTokenResponse(_:))
        }
        
        if accessTokenErrorAvailable, let _ = self.accessTokenError {
            
            let button = alert.addButton(withTitle: "View access token error")
            button.target = self
            button.action = #selector(viewAccessTokenError(_:))
        }
        
        alert.runModal()
    }
    
    private func showAlert(title: String?, value: String?) {
        
        let alert = NSAlert()
        
        if let title = title {
            
            alert.messageText = title
        }
        
        if let value = value {
            
            alert.informativeText = value
        }
        
        alert.addButton(withTitle: "Close")
        
        alert.runModal()
    }
    
    //MARK: - Actions
    
    @IBAction func loginAction(_ sender: Any) {
        
        self.clearErrorIndicatorFromAllTextFields()
        self.clearResult()
        
        let client = self.clientTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard client.isEmpty == false else {
            
            self.setErrorIndicator(to: self.clientTextField)
            self.clientTextField.becomeFirstResponder()
            return
        }
        
        var scope: Scope? = nil
        let scopeString = self.scopeTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if scopeString.isEmpty == false {
            
            scope = Scope(value: scopeString)
        }
        
        let authorizationURLString = self.authorizationURLTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard authorizationURLString.isEmpty == false, let authorizationURL = URL(string: authorizationURLString) else {
            
            self.setErrorIndicator(to: self.authorizationURLTextField)
            self.authorizationURLTextField.becomeFirstResponder()
            return
        }

        let redirectURLString = self.redirectURLTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard redirectURLString.isEmpty == false, let redirectURL = URL(string: redirectURLString) else {
            
            self.setErrorIndicator(to: self.redirectURLTextField)
            self.redirectURLTextField.becomeFirstResponder()
            return
        }
        
        let webViewController = WebViewUserAgentViewController()
        let userAgent = PresentableUserAgent(webViewController) { [weak self] (webViewController) in
            
            self?.presentAsSheet(webViewController)
        }
        dismissHandler: { [weak self] (webViewController) in
            
            self?.dismiss(webViewController)
        }
        
        var flow: AuthorizationGrantFlow? = ImplicitGrantFlow(authorizationEndpoint: authorizationURL, clientID: client, redirectURI: redirectURL, scope: scope, userAgent: userAgent)
        
        flow?.authenticate { [weak self] (accessTokenResponse, error) in
            
            self?.accessTokenResponse = accessTokenResponse
            self?.accessTokenError = error
            
            self?.showResult()
            
            flow = nil
        }
    }
    
    @IBAction func viewResult(_ sender: Any) {
        
        self.showResult()
    }
    
    @IBAction func viewAccessTokenRequest(_ sender: Any) {
        
        guard let request = self.accessTokenRequest else {
            
            return
        }
        
        let value =
        """
        URL:
        \(request.url?.absoluteString ?? "nil")
        
        Method: \(request.httpMethod ?? "nil")
        
        Headers:
        \(request.allHTTPHeaderFields?.map({ "\($0): \($1)" }).joined(separator: "\n") ?? "nil")
        
        Body:
        \(request.httpBody == nil ? "nil" : String(data: request.httpBody!, encoding: .utf8) ?? "nil")
        """
        
        self.showAlert(title: "Access token request", value: value)
    }
    
    @IBAction func viewAccessTokenResponse(_ sender: Any) {
        
        guard let response = self.accessTokenResponse else {
            
            return
        }
        
        let value = response.parameters.map({ (key, value) -> String in
            
            return "\(key): \n\(value as? String ?? "nil")"
        }).joined(separator: "\n\n")
        
        self.showAlert(title: "Access token response", value: value)
    }
    
    @IBAction func viewAccessTokenError(_ sender: Any) {
        
        guard let error = self.accessTokenError else {
            
            return
        }
        
        self.showAlert(title: "Access token error", value: error.localizedDescription)
    }
}


