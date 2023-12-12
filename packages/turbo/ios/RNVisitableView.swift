//
//  RNTTurboWebview.swift
//  HotwireRNDemo
//
//  Created by Bartłomiej Fryz on 24/06/2022.
//

import RNTurboiOS
import UIKit

class RNVisitableView: UIView, RNSessionSubscriber {
  var id: UUID = UUID()
  @objc var sessionHandle: NSString? = nil
  @objc var applicationNameForUserAgent: NSString? = nil
  @objc var url: NSString = ""
  @objc var onMessage: RCTDirectEventBlock?
  @objc var onVisitProposal: RCTDirectEventBlock?
  @objc var onOpenExternalUrl: RCTDirectEventBlock?
  @objc var onLoad: RCTDirectEventBlock?
  @objc var onVisitError: RCTDirectEventBlock?
  @objc var onWebAlert: RCTDirectEventBlock?
  @objc var onWebConfirm: RCTDirectEventBlock?

  private var onConfirmHandler: ((Bool) -> Void)?
  private var onAlertHandler: (() -> Void)?


  private lazy var session: RNSession = RNSessionManager.shared.findOrCreateSession(sessionHandle: sessionHandle!, webViewConfiguration: webViewConfiguration)
  private lazy var webView: WKWebView = session.webView
  private lazy var webViewConfiguration: WKWebViewConfiguration = {
    let configuration = WKWebViewConfiguration()
    configuration.applicationNameForUserAgent = applicationNameForUserAgent as String?
    return configuration
  }()
    
  lazy var controller: RNVisitableViewController = {
    let controller = RNVisitableViewController()
    controller.delegate = self
    return controller
  }()
    
  override func didMoveToWindow() {
    reactViewController()?.addChild(controller)
    controller.view.frame = bounds // Fixes incorrect size of the webview
    controller.didMove(toParent: reactViewController())
    addSubview(controller.view)
  }
    
  public func handleMessage(message: WKScriptMessage) {
    if let messageBody = message.body as? [AnyHashable : Any] {
      onMessage?(messageBody)
    }
  }
  
  public func injectJavaScript(code: NSString) -> Void {
    webView.evaluateJavaScript(code as String)
  }
  
  public func sendAlertResult() -> Void {
    self.onAlertHandler?()
    self.onAlertHandler = nil
  }
  
  public func sendConfirmResult(result: NSString) -> Void {
    let confirmResult = result == "true"
    self.onConfirmHandler?(confirmResult)
    self.onConfirmHandler = nil
  }
    
  public func reload(){
    session.reload()
  }
    
  private func visit() {
    if(controller.visitableURL?.absoluteString == url as String) {
      return
    }
    performVisit()
  }
    
  private func performVisit() {
    controller.visitableURL = URL(string: String(url))
    session.visit(controller)
  }
    
  public func didProposeVisit(proposal: VisitProposal){
    if (webView.url == proposal.url) {
      // When reopening same URL we want to reload webview
      reload()
    } else {
      let event: [AnyHashable: Any] = [
        "url": proposal.url.absoluteString,
        "action": proposal.options.action.rawValue,
      ]
      onVisitProposal!(event)
    }
  }

  public func didFailRequestForVisitable(visitable: Visitable, error: Error){
    var event: [AnyHashable: Any] = [
      "url": visitable.visitableURL.absoluteString,
      "error": error.localizedDescription,
    ]
    if let turboError = error as? TurboError, case let .http(statusCode) = turboError {
      event["statusCode"] = statusCode
    }
    onVisitError?(event)
  }
    
  public func didOpenExternalUrl(url: URL) {
    onOpenExternalUrl?(["url": url.absoluteString])
  }

  func handleAlert(message: String, completionHandler: @escaping () -> Void) {
    let event: [AnyHashable: Any] = [
      "message": message,
    ]
    self.onWebAlert?(event)
    self.onAlertHandler = completionHandler
  }
  
  func handleConfirm(message: String, completionHandler: @escaping (Bool) -> Void) {
    let event: [AnyHashable: Any] = [
      "message": message,
    ]
    self.onWebConfirm?(event)
    self.onConfirmHandler = completionHandler
  }
}

extension RNVisitableView: RNVisitableViewControllerDelegate {
  
  func visitableWillAppear(visitable: Visitable) {
    session.registerVisitableView(newView: self)
    visit()
  }
    
  func visitableDidDisappear(visitable: Visitable) {
    session.unregisterVisitableView(view: self)
  }

  func visitableDidRender(visitable: Visitable) {
    let event: [AnyHashable: Any] = [
      "title": webView.title!,
      "url": webView.url!
    ]
    onLoad?(event)
  }
  
}
