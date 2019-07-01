//
//  ImplicitGrantFlowInputViewController.swift
//  MHIdentityKit-iOSTestsHost
//
//  Created by Milen Halachev on 1.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import UIKit
import MHIdentityKit

class ImplicitGrantFlowInputViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var clientTextField: UITextField!
    @IBOutlet weak var scopeTextField: UITextField!
    @IBOutlet weak var authorizationURLTextField: UITextField!
    @IBOutlet weak var redirectURLTextField: UITextField!
    
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
        self.clearErrorIndicator(from: self.scopeTextField)
        self.clearErrorIndicator(from: self.authorizationURLTextField)
        self.clearErrorIndicator(from: self.redirectURLTextField)
    }
    
    private func clearResult() {
        
        self.accessTokenResponse = nil
        self.accessTokenError = nil
    }
    
    private func showResult() {
        
        let accessTokenResponseAvailable = self.accessTokenResponse != nil
        let accessTokenErrorAvailable = self.accessTokenError != nil
        
        let title = "Result summary"
        let message =
        """
        Access token response: \(accessTokenResponseAvailable ? "available" : "none")
        Access token error: \(accessTokenErrorAvailable ? "available" : "none")
        """
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if accessTokenResponseAvailable, let response = self.accessTokenResponse {
            
            alertController.addAction(UIAlertAction(title: "View access token response", style: .default, handler: { (_) in
                
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
        
        var scope: Scope? = nil
        if let scopeString = self.scopeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), scopeString.isEmpty == false {
            
            scope = Scope(value: scopeString)
        }
        
        guard let authorizationURLString = self.authorizationURLTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), authorizationURLString.isEmpty == false, let authorizationURL = URL(string: authorizationURLString) else {
            
            self.setErrorIndicator(to: self.authorizationURLTextField)
            self.authorizationURLTextField.becomeFirstResponder()
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
        
        var flow: AuthorizationGrantFlow? = ImplicitGrantFlow(authorizationEndpoint: authorizationURL, clientID: client, redirectURI: redirectURL, scope: scope, userAgent: userAgent)
        
        flow?.authenticate { [weak self] (accessTokenResponse, error) in
            
            self?.accessTokenResponse = accessTokenResponse
            self?.accessTokenError = error
            
            self?.showResult()
            
            flow = nil
        }
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

