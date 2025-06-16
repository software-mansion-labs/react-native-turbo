//
//  RNTTurboWebview.swift
//  HotwireRNDemo
//
//  Created by Bartłomiej Fryz on 24/06/2022.
//

import UIKit
import WebKit

let REFRESH_SCRIPT = "typeof Turbo.session.refresh === 'function'" +
            "? Turbo.session.refresh(document.baseURI)" + // Turbo 8+
            ": Turbo.visit(document.baseURI, { action: 'replace', shouldCacheSnapshot: 'false' })" // Older Turbo versions

class RNVisitableView: UIView, RNSessionSubscriber {
  var id: UUID = UUID()
  @objc var sessionHandle: NSString? = nil
  @objc var url: NSString = ""
  @objc var applicationNameForUserAgent: NSString? = nil {
    didSet {
      webViewConfiguration.applicationNameForUserAgent = applicationNameForUserAgent as? String
    }
  }
  @objc var pullToRefreshEnabled: Bool = true {
    didSet {
      controller!.visitableView.allowsPullToRefresh = pullToRefreshEnabled
    }
  }
  @objc var refreshControlTopAnchor: NSNumber = 0 {
    didSet {
      controller!.visitableView.refreshControlTopAnchor = refreshControlTopAnchor as! CGFloat
    }
  }
  @objc var scrollEnabled: Bool = true {
    didSet {
      configureWebView()
    }
  }
  @objc var contentInset: [String: CGFloat] = [:] {
    didSet {
      configureWebView()
    }
  }
  @objc var webViewDebuggingEnabled: Bool = false {
    didSet {
      configureWebView()
    }
  }
  @objc var onMessage: RCTDirectEventBlock?
  @objc var onVisitProposal: RCTDirectEventBlock?
  @objc var onOpenExternalUrl: RCTDirectEventBlock?
  @objc var onLoad: RCTDirectEventBlock?
  @objc var onError: RCTDirectEventBlock?
  @objc var onWebAlert: RCTDirectEventBlock?
  @objc var onWebConfirm: RCTDirectEventBlock?
  @objc var onFormSubmissionStarted: RCTDirectEventBlock?
  @objc var onFormSubmissionFinished: RCTDirectEventBlock?
  @objc var onShowLoading: RCTDirectEventBlock?
  @objc var onHideLoading: RCTDirectEventBlock?
  @objc var onContentProcessDidTerminate: RCTDirectEventBlock?

  private var onConfirmHandler: ((Bool) -> Void)?
  private var onAlertHandler: (() -> Void)?

  private var _session: RNSession? = nil
  private var session: RNSession? {
    if (_session != nil) {
      return _session
    }
      
    if (sessionHandle == nil) {
      return nil
    }
      
    _session = RNSessionManager.shared.findOrCreateSession(sessionHandle: sessionHandle!, webViewConfiguration: webViewConfiguration)
    return _session
  }
  private var webView: WKWebView? { session?.webView }
  private var webViewConfiguration: WKWebViewConfiguration = WKWebViewConfiguration()
    
  lazy var controller: RNVisitableViewController? = RNVisitableViewController(reactViewController: reactViewController(), delegate: self)
    
  private var isRefreshing: Bool {
    controller!.visitableView.isRefreshing
  }
    
  private func configureWebView() {
    if (webView == nil) {
      return
    }
      
    if #available(iOS 16.4, *) {
      webView!.isInspectable = webViewDebuggingEnabled
    }

    webView!.scrollView.isScrollEnabled = scrollEnabled
    webView!.scrollView.contentInset = UIEdgeInsets(top: contentInset["top"] ?? 0,
                                                    left: contentInset["left"] ?? 0,
                                                    bottom: contentInset["bottom"] ?? 0,
                                                    right: contentInset["right"] ?? 0)
  }
    
  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    
    // Sometimes UIPageViewController does not automatically call viewWillAppear
    // on its child view controllers. We need to manually begin the appearance transition
    // for the RNVisitableViewController when it's contained within a UIPageViewController.
    if (newWindow != nil && reactViewController()?.parent is UIPageViewController) {
      controller!.beginAppearanceTransition(true, animated: false)
    }
  }
    
  override func didMoveToWindow() {
    super.didMoveToWindow()
    
    if (window == nil) {
      return
    }
    
    let viewController = reactViewController()!
    viewController.addChild(controller!)
    addSubview(controller!.view)
    controller!.view.frame = bounds // Fixes incorrect size of the webview
    controller!.didMove(toParent: viewController)

    // Sometimes UIPageViewController does not automatically call viewDidAppear
    // on its child view controllers. We need to manually end the appearance transition
    // for the RNVisitableViewController when it's contained within a UIPageViewController.
    if (viewController.parent is UIPageViewController) {
      controller!.endAppearanceTransition()
    }
  }
    
  override func didSetProps(_ changedProps: [String]!) {
    super.didSetProps(changedProps)

    // When all properties of RNVisitableView are initialized, the visit function can be safely called.
    visit()
  }

  override func removeFromSuperview() {
    super.removeFromSuperview()
    _session = nil
    controller = nil
  }
    
  public func handleMessage(message: WKScriptMessage) {
    if let messageBody = message.body as? [AnyHashable : Any] {
      onMessage?(messageBody)
    }
  }

  public func injectJavaScript(code: NSString) -> Void {
    webView?.evaluateJavaScript(code as String)
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

  public func reload() {
    session?.reload()
  }

  public func refresh() {
    webView?.evaluateJavaScript(REFRESH_SCRIPT)
  }

  private func visit() {
    if (controller?.visitableURL?.absoluteString == url as String) {
      return
    }
    controller!.visitableURL = URL(string: String(url))
    session?.visit(controller!)
  }

  public func didProposeVisit(proposal: VisitProposal){
    if (webView?.url == proposal.url && proposal.options.action == .replace) {
      // When reopening same URL we want to refresh webview
      refresh()
    } else {
      let event: [AnyHashable: Any] = [
        "url": proposal.url.absoluteString,
        "action": proposal.options.action.rawValue,
      ]
      onVisitProposal!(event)
    }
  }

  public func didProposeVisitToCrossOriginRedirect(location: URL){
    onOpenExternalUrl?(["url": location.absoluteString])
  }

  func getStatusCodeFromError(error: TurboError?) -> Int {
    switch error {
      case .networkFailure:
        return 0
      case .timeoutFailure:
        return -1
      case .contentTypeMismatch:
        return -2
      case .pageLoadFailure:
        return -3
      case .http(let statusCode):
        return statusCode
      case .none:
        return -4
    }
  }

  public func didFailRequestForVisitable(visitable: Visitable, error: Error){
    let event: [AnyHashable: Any] = [
      "url": visitable.visitableURL.absoluteString,
      "description": error.localizedDescription,
      "statusCode": getStatusCodeFromError(error: error as? TurboError)
    ]
    onError?(event)
  }

  public func didOpenExternalUrl(url: URL) {
    onOpenExternalUrl?(["url": url.absoluteString])
  }

  public func didStartFormSubmission() {
    onFormSubmissionStarted?(["url": url])
  }

  public func didFinishFormSubmission() {
    onFormSubmissionFinished?(["url": url])
  }

  public func processDidTerminate() {
    onContentProcessDidTerminate?(["url": url])
  }

  func clearSessionSnapshotCache(){
    session?.clearSnapshotCache()
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
    session?.visitableViewWillAppear(view: self)
  }

  func visitableDidAppear(visitable: Visitable) {
    configureWebView()
    session?.visitableViewDidAppear(view: self)
  }
    
  func visitableWillDisappear(visitable: Visitable) {
    // Ensure that all completion handlers have been called.
    // Otherwise, an NSInternalInconsistencyException might occur.
    sendAlertResult()
    sendConfirmResult(result: "")
  }

  func visitableDidDisappear(visitable: Visitable) {
    // No-op
  }

  func visitableDidRender(visitable: Visitable) {
    let event: [String: String] = [
      "title": webView!.title!,
      "url": webView!.url!.absoluteString,
    ]
    onLoad?(event)
  }

  func showVisitableActivityIndicator() {
    if (isRefreshing) {
      return
    }
    onShowLoading?([:])
  }

  func hideVisitableActivityIndicator() {
    onHideLoading?([:])
  }

}
