//
//  WebViewUserAgentViewController.swift
//  MHIdentityKit-macOS
//
//  Created by Milen Halachev on 1.07.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

#if os(macOS)

import Foundation
import WebKit
import Cocoa


/**
 A default implementation of UserAgent for macOS using WKWebView.
 
 - note: It is recommended present the view controller as sheet or modally.
 */

open class WebViewUserAgentViewController: NSViewController, WKNavigationDelegate, UserAgent {
    
    open var topBarHeight: CGFloat = 50
    open var topBarButtonsSize: CGFloat = 35
    
    @IBOutlet open lazy var progressView: NSProgressIndicator! = { [unowned self] in

        let progressView = NSProgressIndicator()
        progressView.isIndeterminate = false
        progressView.minValue = 0
        progressView.maxValue = 1

        self.view.addSubview(progressView)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.init(item: progressView, attribute: .centerY, relatedBy: .equal, toItem: self.topBar, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: progressView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: progressView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0).isActive = true

        return progressView
    }()
    
    @IBOutlet open lazy var topBar: NSStackView! = { [unowned self] in
        
        let topBar = NSStackView()
        topBar.orientation = .horizontal
        topBar.edgeInsets.left = topBar.spacing
        topBar.edgeInsets.right = topBar.spacing
        
        self.view.addSubview(topBar)
        
        topBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.init(item: topBar, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: topBar, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: topBar, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: topBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50).isActive = true
        
        topBar.addView(self.backButton, in: NSStackView.Gravity.trailing)
        topBar.addView(self.forwardButton, in: NSStackView.Gravity.trailing)
        topBar.addView(self.stopButton, in: NSStackView.Gravity.trailing)
        topBar.addView(self.reloadButton, in: NSStackView.Gravity.trailing)
        
        topBar.views.forEach { (view) in
            
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.init(item: view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.topBarButtonsSize).isActive = true
            NSLayoutConstraint.init(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.topBarButtonsSize).isActive = true
        }
        
        topBar.addView(self.closeButton, in: NSStackView.Gravity.leading)
        self.closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.init(item: self.closeButton!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.topBarButtonsSize*2).isActive = true
        NSLayoutConstraint.init(item: self.closeButton!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.topBarButtonsSize).isActive = true
        
        return topBar
        
    }()
    
    @IBOutlet open lazy var webView: WKWebView! = { [unowned self] in
       
        let webView = WKWebView()
        webView.navigationDelegate = self
        
        
        self.view.addSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.init(item: webView, attribute: .top, relatedBy: .equal, toItem: self.topBar, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: webView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: webView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.init(item: webView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0).isActive = true
        
        return webView

    }()
    
    @IBOutlet open lazy var backButton: NSButton! = { [unowned self] in

        let button = NSButton()
        button.bezelStyle = NSButton.BezelStyle.texturedSquare
        button.image = NSImage(named: "NSGoLeftTemplate")
        button.target = self
        button.action = #selector(type(of: self).backAction)
        
        return button
    }()

    @IBOutlet open lazy var forwardButton: NSButton! = { [unowned self] in

        let button = NSButton()
        button.bezelStyle = NSButton.BezelStyle.texturedSquare
        button.image = NSImage(named: "NSGoRightTemplate")
        button.target = self
        button.action = #selector(type(of: self).forwardAction)
        
        return button
    }()

    @IBOutlet open lazy var stopButton: NSButton! = { [unowned self] in

        let button = NSButton()
        button.bezelStyle = NSButton.BezelStyle.texturedSquare
        button.image = NSImage(named: "NSStopProgressTemplate")
        button.target = self
        button.action = #selector(type(of: self).stopAction)
        
        return button
    }()

    @IBOutlet open lazy var reloadButton: NSButton! = { [unowned self] in
        
        let button = NSButton()
        button.bezelStyle = NSButton.BezelStyle.texturedSquare
        button.image = NSImage(named: "NSRefreshTemplate")
        button.target = self
        button.action = #selector(type(of: self).reloadAction)
        
        return button
    }()
    
    @IBOutlet open lazy var closeButton: NSButton! = { [unowned self] in
        
        let button = NSButton()
        button.bezelStyle = NSButton.BezelStyle.texturedSquare
        button.title = "Close"
        button.target = self
        button.action = #selector(type(of: self).closeAction)
        
        return button
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
    
    open override func loadView() {
        
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }
    
    open override func viewDidLoad() {
        
        super.viewDidLoad()
        
        _ = self.webViewIsLoadingObserver
        _ = self.webViewEstimatedProgressObserver
        
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
        
        
        self.progressView.doubleValue = self.webView.estimatedProgress
    }
    
    //MARK: - Actions
    
    @IBAction open func backAction(_ sender: Any) {
        
        self.webView.goBack()
    }
    
    @IBAction open func forwardAction(_ sender: Any) {
        
        self.webView.goForward()
    }
    
    @IBAction open func stopAction(_ sender: Any) {
        
        self.webView.stopLoading()
    }
    
    @IBAction open func reloadAction(_ sender: Any) {
        
        self.webView.reload()
    }
    
    @IBAction open func closeAction(_ sender: Any) {
        
        self.presentingViewController?.dismiss(self)
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
    
    @available(*, deprecated, message: "Use PresentableUserAgent instead.")
    public func makePresentableUserAgent(present: @escaping (WebViewUserAgentViewController) -> Void, dismiss: @escaping (WebViewUserAgentViewController) -> Void) -> UserAgent {
     
        return PresentableUserAgent(self, presentationHandler: present, dismissHandler: dismiss)
    }
}

#endif
