//
//  ResourceOwnerPasswordCredentialsGrantFlowInputViewController.swift
//  MHIdentityKit-macOSTestsHost
//
//  Created by Milen Halachev on 1.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation
import Cocoa
import MHIdentityKit

class ResourceOwnerPasswordCredentialsGrantFlowInputViewController: NSViewController {
    
    @IBOutlet weak var clientTextField: NSTextField!
    @IBOutlet weak var secretTextField: NSTextField!
    @IBOutlet weak var scopeTextField: NSTextField!
    @IBOutlet weak var tokenURLTextField: NSTextField!
    @IBOutlet weak var usernameTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSTextField!
    
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
        self.clearErrorIndicator(from: self.secretTextField)
        self.clearErrorIndicator(from: self.scopeTextField)
        self.clearErrorIndicator(from: self.tokenURLTextField)
        self.clearErrorIndicator(from: self.usernameTextField)
        self.clearErrorIndicator(from: self.passwordTextField)
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
        
        let secret = self.secretTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard secret.isEmpty == false else {
            
            self.setErrorIndicator(to: self.secretTextField)
            self.secretTextField.becomeFirstResponder()
            return
        }
        
        var scope: Scope? = nil
        let scopeString = self.scopeTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if scopeString.isEmpty == false {
            
            scope = Scope(value: scopeString)
        }
        
        let tokenURLString = self.tokenURLTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard tokenURLString.isEmpty == false, let tokenURL = URL(string: tokenURLString) else {
            
            self.setErrorIndicator(to: self.tokenURLTextField)
            self.tokenURLTextField.becomeFirstResponder()
            return
        }
        
        let username = self.usernameTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard username.isEmpty == false else {
            
            self.setErrorIndicator(to: self.usernameTextField)
            self.usernameTextField.becomeFirstResponder()
            return
        }
        
        let password = self.passwordTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard password.isEmpty == false else {
            
            self.setErrorIndicator(to: self.passwordTextField)
            self.passwordTextField.becomeFirstResponder()
            return
        }
        
        let networkClient = AnyNetworkClient { [weak self] (request, completion) in
            
            self?.accessTokenRequest = request
            _defaultNetworkClient.perform(request, completion: completion)
        }
        
        let credentialsProvider = AnyCredentialsProvider { (handler) in
            
            handler(username, password)
        }
        
        let clientAuthorizer = HTTPBasicAuthorizer(clientID: client, secret: secret)
        
        var flow: AuthorizationGrantFlow? = ResourceOwnerPasswordCredentialsGrantFlow(tokenEndpoint: tokenURL, credentialsProvider: credentialsProvider, scope: scope, clientAuthorizer: clientAuthorizer, networkClient: networkClient)
        
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
        
        if let data = try? JSONEncoder().encode(response), let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {
            
            let value = json.map({ (key, value) -> String in
                
                return "\(key): \n\(value as? String ?? "nil")"
            }).joined(separator: "\n\n")
            
            self.showAlert(title: "Access token response", value: value)
        }
        else {
            
            let value = response.accessToken
            self.showAlert(title: "Access token response", value: value)
        }
    }
    
    @IBAction func viewAccessTokenError(_ sender: Any) {
        
        guard let error = self.accessTokenError else {
            
            return
        }
        
        self.showAlert(title: "Access token error", value: error.localizedDescription)
    }
}
