//
//  RNTTurboWebview.swift
//  HotwireRNDemo
//
//  Created by Bartłomiej Fryz on 24/06/2022.
//

import UIKit
import WebKit

protocol WKUIDelegateHandler{
  func alertHandler(message: String, completionHandler: @escaping () -> Void)
  func confirmHandler(message: String, completionHandler: @escaping (Bool) -> Void)
}

class TurboUIDelegate: NSObject, WKUIDelegate {
  private var uiHandler:WKUIDelegateHandler
  
  init(uiHandler: WKUIDelegateHandler) {
    self.uiHandler = uiHandler
  }
  
  func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
    uiHandler.alertHandler(message: message, completionHandler: completionHandler)
  }
  
  func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
    uiHandler.confirmHandler(message: message, completionHandler: completionHandler)
  }
}

class RNSession: NSObject {
  
  private var visitableView: RNVisitableView?
  private var sessionHandle: NSString
  private var webViewConfiguration: WKWebViewConfiguration
  private var wkUiDelegate: WKUIDelegate?
  
  init(sessionHandle: NSString, webViewConfiguration: WKWebViewConfiguration) {
    self.sessionHandle = sessionHandle
    self.webViewConfiguration = webViewConfiguration
  }
  
  public lazy var turboSession: Session = {
    webViewConfiguration.userContentController.add(self, name: "nativeApp")
    self.wkUiDelegate = TurboUIDelegate(uiHandler: self)
    
    let session = Session(webViewConfiguration: webViewConfiguration)
    session.delegate = self
    session.webView.allowsLinkPreview = false
    session.webView.scrollView.contentInsetAdjustmentBehavior = .never
    session.webView.uiDelegate = self.wkUiDelegate
    
    return session
  }()
  public lazy var webView: WKWebView = turboSession.webView
  
  func visitableViewWillAppear(view: RNVisitableView) {
    self.visitableView = view
  }
  
  func visitableViewDidAppear(view: RNVisitableView) {
    // if (visitableView !== nil && visitableView.isModal !== view.isModal) {
    //   print("You're not able to share session between modal and non-modals.")
    // }
  }
  
  func visit(_ visitable: Visitable) {
    turboSession.visit(visitable)
  }
    
  func visit(_ visitable: Visitable, action: VisitAction) {
    turboSession.visit(visitable, action: action)
  }
    
  func reload() {
    turboSession.reload()
  }
  
  func refresh() {
    visitableView?.refresh()
  }
  
  func clearSnapshotCache() {
    turboSession.clearSnapshotCache()
  }
  
}

extension RNSession: SessionDelegate {
  
  func sessionWebViewProcessDidTerminate(_ session: Session) {
    visitableView?.processDidTerminate()
  }

  func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
    visitableView?.didProposeVisit(proposal: proposal)
  }

  func session(_ session: Session, didProposeVisitToCrossOriginRedirect location: URL) {
    visitableView?.didProposeVisitToCrossOriginRedirect(location: location)
  }

  func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
    visitableView?.didFailRequestForVisitable(visitable: visitable, error: error)
  }

  func session(_ session: Session, openExternalURL url: URL) {
    visitableView?.didOpenExternalUrl(url: url)
  }
    
  func sessionDidStartFormSubmission(_ session: Session) {
    visitableView?.didStartFormSubmission()
  }
    
  func sessionDidFinishFormSubmission(_ session: Session) {
    visitableView?.didFinishFormSubmission()
  }

  func session(_ session: Session, decidePolicyFor navigationAction: WKNavigationAction) -> WebViewPolicyManager.Decision {
    guard let url = navigationAction.request.url else {
      return .allow
    }
    // regardless of the return value here nothing happens, so we have to manually open external URL
    visitableView?.didOpenExternalUrl(url: url)
    return .allow
  }
}

extension RNSession: WKScriptMessageHandler {
  
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    visitableView?.handleMessage(message: message)
  }
  
}

extension RNSession : WKUIDelegateHandler{

  func alertHandler(message: String, completionHandler: @escaping () -> Void) {
    if (visitableView == nil) {
      completionHandler()
      return
    }
    
    visitableView?.handleAlert(message: message, completionHandler: completionHandler)
  }

  func confirmHandler(message: String, completionHandler: @escaping (Bool) -> Void) {
    if (visitableView == nil) {
      completionHandler(false)
      return
    }
    
    visitableView?.handleConfirm(message: message, completionHandler: completionHandler)
  }
}
