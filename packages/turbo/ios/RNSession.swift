//
//  RNTTurboWebview.swift
//  HotwireRNDemo
//
//  Created by Bartłomiej Fryz on 24/06/2022.
//

import ReactNativeHotwiredTurboiOS
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
  
  private var visitableViews: [RNSessionSubscriber] = []
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
    session.webView.uiDelegate = self.wkUiDelegate

    #if DEBUG
    if #available(iOS 16.4, *) {
      session.webView.isInspectable = true
    }
    #endif
    
    return session
  }()
  public lazy var webView: WKWebView = turboSession.webView
  
  func registerVisitableView(newView: RNSessionSubscriber) {
    if (!visitableViews.contains {
      $0.id == newView.id
    }) {
      visitableViews.append(newView)
    }
  }
  
  func unregisterVisitableView(view: RNSessionSubscriber) {
    let wasTopMostView = visitableViews.last?.id == view.id
    
    let viewIdx = visitableViews.lastIndex(where: {
      view.id == $0.id
    })
    visitableViews.remove(at: viewIdx!)

    // The new top-most view is not registered when the previous top-most view is a modal
    if (wasTopMostView) {
      guard let newView = visitableViews.last else {
        return
      }
      visitableViewWillAppear(view: newView)
    }
  }
    
  func visitableViewWillAppear(view: RNSessionSubscriber) {
    turboSession.visitableViewWillAppear(view.controller)
  }
    
  func visit(_ visitable: Visitable) {
    turboSession.visit(visitable)
  }
    
  func reload() {
    turboSession.reload()
  }
    
  func clearSnapshotCache() {
    turboSession.clearSnapshotCache()
  }
  
}


extension RNSession: SessionDelegate {
  
  func sessionWebViewProcessDidTerminate(_ session: Session) {
    visitableViews.last?.processDidTerminate()
  }

  func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
    visitableViews.last?.didProposeVisit(proposal: proposal)
  }

  func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
    visitableViews.last?.didFailRequestForVisitable(visitable: visitable, error: error)
  }

  func session(_ session: Session, openExternalURL url: URL) {
    visitableViews.last?.didOpenExternalUrl(url: url)
  }
    
  func sessionDidStartFormSubmission(_ session: Session) {
    visitableViews.last?.didStartFormSubmission()
  }
    
  func sessionDidFinishFormSubmission(_ session: Session) {
    visitableViews.last?.didFinishFormSubmission()
  }
}

extension RNSession: WKScriptMessageHandler {
  
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    for view in visitableViews {
      view.handleMessage(message: message)
    }
  }
  
}

extension RNSession : WKUIDelegateHandler{

  func alertHandler(message: String, completionHandler: @escaping () -> Void) {
    guard let visitableView = visitableViews.last else {
      return
    }
    visitableView.handleAlert(message: message, completionHandler: completionHandler)
  }

  func confirmHandler(message: String, completionHandler: @escaping (Bool) -> Void) {
    guard let visitableView = visitableViews.last else {
      return
    }
    visitableView.handleConfirm(message: message, completionHandler: completionHandler)
  }
}
