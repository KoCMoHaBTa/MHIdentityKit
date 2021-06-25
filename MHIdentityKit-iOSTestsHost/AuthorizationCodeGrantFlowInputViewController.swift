//
//  AuthorizationCodeGrantFlowInputViewController.swift
//  MHIdentityKitTestsHost
//
//  Created by Milen Halachev on 9/24/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import UIKit
import MHIdentityKit

class AuthorizationCodeGrantFlowInputViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var clientTextField: UITextField!
    @IBOutlet weak var secretTextField: UITextField!
    @IBOutlet weak var scopeTextField: UITextField!
    @IBOutlet weak var authorizationURLTextField: UITextField!
    @IBOutlet weak var tokenURLTextField: UITextField!
    @IBOutlet weak var redirectURLTextField: UITextField!
    
    private var accessTokenRequest: URLRequest?
    private var accessTokenResponse: AccessTokenResponse?
    private var accessTokenError: Error?

    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    private func setErrorIndicator(to textField: UITextField) {
        
        textField.layer.borderColor = UIColor.red.cgColor
        textField.layer.borderWidth = 1
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 4
    }
    
    private func clearErrorIndicator(from textField: UITextField) {
        
        textField.layer.borderColor = nil
        textField.layer.borderWidth = 0
        textField.layer.masksToBounds = false
        textField.layer.cornerRadius = 0
    }
    
    private func clearErrorIndicatorFromAllTextFields() {
        
        self.clearErrorIndicator(from: self.clientTextField)
        self.clearErrorIndicator(from: self.secretTextField)
        self.clearErrorIndicator(from: self.scopeTextField)
        self.clearErrorIndicator(from: self.authorizationURLTextField)
        self.clearErrorIndicator(from: self.tokenURLTextField)
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
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if accessTokenRequestAvailable, let request = self.accessTokenRequest {
            
            alertController.addAction(UIAlertAction(title: "View access token request", style: .default, handler: { (_) in
                
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
            }))
        }
        
        if accessTokenResponseAvailable, let response = self.accessTokenResponse {
            
            alertController.addAction(UIAlertAction(title: "View access token response", style: .default, handler: { (_) in
                
                let value = response.parameters.map({ (key, value) -> String in
                    
                    return "\(key): \n\(value as? String ?? "nil")"
                }).joined(separator: "\n\n")
                
                self.showAlert(title: "Access token response", value: value)
            }))
        }
        
        if accessTokenErrorAvailable, let error = self.accessTokenError {
            
            alertController.addAction(UIAlertAction(title: "View access token error", style: .default, handler: { (_) in
                
                self.showAlert(title: "Access token error", value: error.localizedDescription)
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func showAlert(title: String?, value: String?) {
        
        let alertController = UIAlertController(title: title, message: value, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Copy", style: .default, handler: { (_) in
            
            UIPasteboard.general.string = value
        }))
        
        alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - Actions

    @IBAction func loginAction() {
        
        self.clearErrorIndicatorFromAllTextFields()
        self.clearResult()
        
        guard let client = self.clientTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), client.isEmpty == false else {
            
            self.setErrorIndicator(to: self.clientTextField)
            self.clientTextField.becomeFirstResponder()
            return
        }
        
        var secret: String? = self.secretTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if secret?.isEmpty == true {
            
            secret = nil
        }
        
        var scope: Scope? = nil
        if let scopeString = self.scopeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), scopeString.isEmpty == false {
            
            scope = Scope(rawValue: scopeString)
        }
        
        guard let authorizationURLString = self.authorizationURLTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), authorizationURLString.isEmpty == false, let authorizationURL = URL(string: authorizationURLString) else {
            
            self.setErrorIndicator(to: self.authorizationURLTextField)
            self.authorizationURLTextField.becomeFirstResponder()
            return
        }
        
        guard let tokenURLString = self.tokenURLTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), tokenURLString.isEmpty == false, let tokenURL = URL(string: tokenURLString) else {
            
            self.setErrorIndicator(to: self.tokenURLTextField)
            self.tokenURLTextField.becomeFirstResponder()
            return
        }
        
        guard let redirectURLString = self.redirectURLTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), redirectURLString.isEmpty == false, let redirectURL = URL(string: redirectURLString) else {
            
            self.setErrorIndicator(to: self.redirectURLTextField)
            self.redirectURLTextField.becomeFirstResponder()
            return
        }
        
        let userAgent = PresentableUserAgent(WebViewUserAgentViewController(), presentationHandler: { [weak self] (webViewController) in
            
            self?.navigationController?.pushViewController(webViewController, animated: true)
            
        }) { [weak self] (webViewController) in
            
            self?.navigationController?.popViewController(animated: true)
        }
        
        let networkClient = AnyNetworkClient { [weak self] request in
            
            self?.accessTokenRequest = request
            return try await DefaultNetoworkClient.shared.perform(request)
        }
        
        let flow: AuthorizationGrantFlow = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationURL, tokenEndpoint: tokenURL, clientID: client, secret: secret, redirectURI: redirectURL, scope: scope, userAgent: userAgent, networkClient: networkClient)

        if #available(iOS 15.0, *) {
            
            async { [weak self] in
                do {
                    
                    self?.accessTokenResponse = try await flow.authenticate()
                }
                catch {
                    
                    self?.accessTokenError = error
                }
                
                self?.showResult()
            }
        }
        else { fatalError("Xcode 13 Beta 1 requires iOS 15 for all async/await APIs ") }
    }
    
    //MARK: - UITableViewDataSource & UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath)
        
        if let textField = (cell?.contentView.subviews.first as? UITextField) {
            
            textField.becomeFirstResponder()
        }
        
        if let label = cell?.contentView.subviews.first as? UILabel, label.text == "View Result" {
            
            self.showResult()
        }
    }
   
    //MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
}

