//
//  RNVisitableViewController.swift
//  HotwireRNDemo
//
//  Created by Bartłomiej Fryz on 27/06/2022.
//

import Foundation
import WebKit

public protocol RNVisitableViewControllerDelegate {
  
  func visitableWillAppear(visitable: Visitable)
  
  func visitableDidAppear(visitable: Visitable)
  
  func visitableDidRender(visitable: Visitable)
    
  func visitableWillDisappear(visitable: Visitable)
  
  func visitableDidDisappear(visitable: Visitable)
  
  func showVisitableActivityIndicator()
  
  func hideVisitableActivityIndicator()
  
}

class RNVisitableViewController: UIViewController, Visitable {
  public var delegate: RNVisitableViewControllerDelegate?

  open weak var visitableDelegate: VisitableDelegate?
  public var initialVisitableURL: URL
  public var currentVisitableURL: URL {
    resolveVisitableLocation()
  }

  private var reactViewController: UIViewController? = nil

  public init(reactViewController: UIViewController?, delegate: RNVisitableViewControllerDelegate?) {
    self.initialVisitableURL = URL(string: "about:blank")!
    self.visitableLocationState = .initialized(self.initialVisitableURL)
    self.reactViewController = reactViewController
    self.delegate = delegate
    super.init(nibName: nil, bundle: nil)
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func initializeVisit(url: URL) {
    initialVisitableURL = url
    visitableLocationState = .initialized(url)
  }

  // MARK: View Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    installVisitableView()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    visitableDelegate?.visitableViewWillAppear(self)
    delegate?.visitableWillAppear(visitable: self)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    visitableDelegate?.visitableViewDidAppear(self)
    delegate?.visitableDidAppear(visitable: self)
  }
    
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    delegate?.visitableWillDisappear(visitable: self)
  }
    
  override func viewDidDisappear(_ animated: Bool) {
    delegate?.visitableDidDisappear(visitable: self)
  }

  // MARK: Visitable

  func visitableDidRender() {
    delegate?.visitableDidRender(visitable: self)
    visitableLocationState = .resolved
  }
    
  func showVisitableActivityIndicator() {
    delegate?.showVisitableActivityIndicator()
  }
    
  func hideVisitableActivityIndicator() {
    delegate?.hideVisitableActivityIndicator()
  }
    
  func visitableDidActivateWebView(_ webView: WKWebView) {
    // No-op
  }
  
  func visitableWillDeactivateWebView() {
    visitableLocationState = .deactivated(visitableView.webView?.url ?? initialVisitableURL)
  }
    
  open func visitableDidDeactivateWebView() {
    // No-op
  }
    
  // MARK: Visitable View

  open private(set) lazy var visitableView: VisitableView = {
    let view = VisitableView(frame: CGRect.zero)
    view.translatesAutoresizingMaskIntoConstraints = false
      
    return view
  }()

  private func installVisitableView() {
    view.addSubview(visitableView)
    NSLayoutConstraint.activate([
       visitableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
       visitableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
       visitableView.topAnchor.constraint(equalTo: view.topAnchor),
       visitableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }
    
  public var visitableViewController: UIViewController {
    self.reactViewController?.parent ?? self
  }

  enum VisitableLocationState {
      case resolved
      case initialized(URL)
      case deactivated(URL)
  }

  private var visitableLocationState: VisitableLocationState

  private func resolveVisitableLocation() -> URL {
      switch visitableLocationState {
      case .resolved:
          return visitableView.webView?.url ?? initialVisitableURL
      case .initialized(let url):
          return url
      case .deactivated(let url):
          return url
      }
  }
}
