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
    
    //MARK: - Actions

    @IBAction func loginAction() {
        
        self.clearErrorIndicatorFromAllTextFields()
        
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
            
            scope = Scope(value: scopeString)
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
        
        let webViewController = WebViewUserAgentViewController()
        let userAgent = webViewController.makePresentableUserAgent(present: { [weak self] (webViewController) in
            
            self?.navigationController?.pushViewController(webViewController, animated: true)
            
        }) { [weak self] (webViewController) in
            
            self?.navigationController?.popViewController(animated: true)
        }
        
        var flow: AuthorizationGrantFlow? = AuthorizationCodeGrantFlow(authorizationEndpoint: authorizationURL, tokenEndpoint: tokenURL, clientID: client, secret: secret, redirectURI: redirectURL, scope: scope, userAgent: userAgent)

        flow?.authenticate { [weak self] (accessTokenResponse, error) in

            let title = error != nil ? "Error" : "Success"
            let message = error?.localizedDescription ?? accessTokenResponse?.accessToken
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
            self?.present(alertController, animated: true, completion: nil)
            
            flow = nil
        }
    }
    
    //MARK: - UITableViewDataSource & UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        (tableView.cellForRow(at: indexPath)?.contentView.subviews.first as? UITextField)?.becomeFirstResponder()
    }
   
    //MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
}

