//
//  WebViewUserAgentViewController.swift
//  MHIdentityKit-iOS
//
//  Created by Milen Halachev on 4.08.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

#if os(iOS)

import Foundation
import WebKit
import UIKit

/**
 A default implementation of UserAgent for iOS using WKWebView.
 
 - note: It is recommended embed the view controller into UINavigationController with visible toolbar, because it contains web navigation controls. If you present it modally within an UINavigationController - it is your responsibility to setup a cancel/close button, based on your needs.
 */

open class WebViewUserAgentViewController: UIViewController, WKNavigationDelegate, UserAgent {
    
    @IBOutlet open lazy var progressView: UIProgressView! = { [unowned self] in
        
        let progressView = UIProgressView(progressViewStyle: .default)
        
        self.view.addSubview(progressView)
        
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.init(item: progressView, attribute: .top, relatedBy: .equal, toItem: self.topLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: progressView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: progressView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0).isActive = true
        
        return progressView
    }()
    
    @IBOutlet open lazy var webView: WKWebView! = { [unowned self] in
       
        let webView = WKWebView()
        webView.navigationDelegate = self
        
        self.view.addSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.init(item: webView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: webView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: webView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: webView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0).isActive = true
        
        return webView

    }()
    
    @IBOutlet open lazy var backButton: UIBarButtonItem! = { [unowned self] in
       
        return UIBarButtonItem(barButtonSystemItem: .rewind, target: self, action: #selector(type(of: self).backAction))
    }()
    
    @IBOutlet open lazy var forwardButton: UIBarButtonItem! = { [unowned self] in
        
        return UIBarButtonItem(barButtonSystemItem: .fastForward, target: self, action: #selector(type(of: self).forwardAction))
    }()
    
    @IBOutlet open lazy var stopButton: UIBarButtonItem! = { [unowned self] in
        
        return UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(type(of: self).stopAction))
    }()
    
    @IBOutlet open lazy var reloadButton: UIBarButtonItem! = { [unowned self] in
        
        return UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(type(of: self).reloadAction))
    }()
    
    private lazy var webViewIsLoadingObserver = self.webView.observe(\.isLoading) { [weak self] (webView, change) in
        
        self?.updateControlButtons()
    }
    
    private lazy var webViewEstimatedProgressObserver = self.webView.observe(\.estimatedProgress) { [weak self] (webView, change) in
        
        self?.updateProgress()
    }
    
    private var request: URLRequest?
    private var redirectURI: URL?
    private var redirectionHandler:  ((URLRequest) throws -> Bool)?
    
    deinit {
        
        if #available(iOS 11.0, *) {
            
        }
        else {
            
            //NOTE: On iOS 10 and below, swift key-value observers are not automatically invalidated upon deallocation, so we have to explicitly invalidate it in order to prevent the app from crashing
            self.webViewIsLoadingObserver.invalidate()
            self.webViewEstimatedProgressObserver.invalidate()
        }
    }
    
    open override func viewDidLoad() {
        
        super.viewDidLoad()
        
        _ = self.webViewIsLoadingObserver
        _ = self.webViewEstimatedProgressObserver
        
        self.toolbarItems = [
            
            self.backButton,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            self.forwardButton,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            self.stopButton,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            self.reloadButton
        ]
        
        self.loadData()
    }
    
    private func loadData() {
        
        guard let request = self.request else {
            
            return
        }
        
        self.webView.load(request)
    }
    
    open func updateControlButtons() {
        
        self.backButton.isEnabled = self.webView.canGoBack
        self.forwardButton.isEnabled = self.webView.canGoForward
        self.stopButton.isEnabled = self.webView.isLoading
        self.reloadButton.isEnabled = !self.webView.isLoading
        
        self.progressView.isHidden = !self.webView.isLoading
    }
    
    open func updateProgress() {
        
        self.progressView.progress = Float(self.webView.estimatedProgress)
    }
    
    //MARK: - Actions
    
    @IBAction open func backAction() {
        
        self.webView.goBack()
    }
    
    @IBAction open func forwardAction() {
        
        self.webView.goForward()
    }
    
    @IBAction open func stopAction() {
        
        self.webView.stopLoading()
    }
    
    @IBAction open func reloadAction() {
        
        self.webView.reload()
    }
    
    //MARK: - WKNavigationDelegate
    
    open func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if (try? self.redirectionHandler?(navigationAction.request)) == true {
            
            decisionHandler(.cancel)
        }
        else {
            
            decisionHandler(.allow)
        }
    }
    
    //MARK: - UserAgent
    
    open func perform(_ request: URLRequest, redirectURI: URL?, redirectionHandler: @escaping (URLRequest) throws -> Bool) {
        
        self.request = request
        self.redirectURI = redirectURI
        self.redirectionHandler = redirectionHandler
        
        guard self.isViewLoaded else {
            
            return
        }
        
        self.loadData()
    }
}

extension WebViewUserAgentViewController {
    
    /**
     Makes a presentable UserAgent of the receiver.
     
     - parameter present: This is the presentation handler. Called when the user agent has to be shown on screen.
     - parameter dismiss: This is the dimiss handler. Called when the user agent successfully handles a redirect and has to be dismissed.
     
     - note: It is recommended embed the view controller into UINavigationController with visible toolbar, because it contains web navigation controls. If you present it modally within an UINavigationController - it is your responsibility to setup a cancel/close button, based on your needs.
     */
    
    open func makePresentableUserAgent(present: @escaping (WebViewUserAgentViewController) -> Void, dismiss: @escaping (WebViewUserAgentViewController) -> Void) -> UserAgent {
     
        return AnyUserAgent { [weak self] (request, redirectURL, redicationHandler) in
            
            guard let _self = self else {
                
                return
            }
            
            _self.perform(request, redirectURI: redirectURL, redirectionHandler: { (request) -> Bool in
                
                let didHandleRedirect = try redicationHandler(request)
                
                if didHandleRedirect, let _self = self {
                    
                    dismiss(_self)
                }
                
                return didHandleRedirect
            })
            
            present(_self)
        }

    }
}

#endif
