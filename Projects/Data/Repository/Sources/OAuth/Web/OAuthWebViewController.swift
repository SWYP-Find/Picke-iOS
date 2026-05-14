//
//  OAuthWebViewController.swift
//  Repository
//
//  Created by Wonji Suh on 5/15/26.
//

import Combine
import Entity
import Foundation
import UIKit
import WebKit

/// Google / Kakao OAuth authorize URL 을 WKWebView 에 띄우고,
/// 서버 콜백 URL (`https://picke.store/oauth/<provider>`) 로 네비게이션이 일어나면
/// 요청을 보내기 전에 `?code=...` 만 추출해 webview 를 닫는다.
/// (서버가 401 응답을 내려도 그 요청이 송신되기 전에 cancel 되므로 사용자에게 노출되지 않음)
@MainActor
final class OAuthWebViewController: UIViewController {
  private enum Layout {
    static let sheetHeightRatio: CGFloat = 0.8
    static let dimmingAlpha: CGFloat = 0.35
    static let cornerRadius: CGFloat = 20
    static let grabberTopSpacing: CGFloat = 8
    static let grabberWidth: CGFloat = 36
    static let grabberHeight: CGFloat = 4
    static let dragHandleHeight: CGFloat = 28
    static let webViewTopSpacing: CGFloat = 8
    static let dismissDragThreshold: CGFloat = 96
  }

  private let authorizeURL: URL
  private let redirectHost: String
  private let redirectPath: String
  private let customUserAgent: String?
  private let onComplete: (Result<String, Error>) -> Void
  private let backgroundTapSubject = PassthroughSubject<Void, Never>()
  private let sheetDragSubject = PassthroughSubject<OAuthSheetDragEvent, Never>()
  private var cancellables: Set<AnyCancellable> = []
  private var didFinish = false
  private weak var sheetContainer: UIView?

  private lazy var webView: WKWebView = {
    let config = WKWebViewConfiguration()
    let view = WKWebView(frame: .zero, configuration: config)
    view.navigationDelegate = self
    view.customUserAgent = customUserAgent
    view.scrollView.showsVerticalScrollIndicator = false
    view.scrollView.showsHorizontalScrollIndicator = false
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  init(
    authorizeURL: URL,
    redirectHost: String,
    redirectPath: String,
    customUserAgent: String? = nil,
    onComplete: @escaping (Result<String, Error>) -> Void
  ) {
    self.authorizeURL = authorizeURL
    self.redirectHost = redirectHost
    self.redirectPath = redirectPath
    self.customUserAgent = customUserAgent
    self.onComplete = onComplete
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
    modalTransitionStyle = .coverVertical
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let rootView = UIView()
    rootView.backgroundColor = .clear

    let dimmingControl = makeDimmingControl()
    let sheetContainer = makeSheetContainer()
    let dragHandleView = makeDragHandleView()
    let grabberView = makeGrabberView()
    self.sheetContainer = sheetContainer

    rootView.addSubview(dimmingControl)
    rootView.addSubview(sheetContainer)
    sheetContainer.addSubview(dragHandleView)
    dragHandleView.addSubview(grabberView)
    sheetContainer.addSubview(webView)

    NSLayoutConstraint.activate([
      dimmingControl.topAnchor.constraint(equalTo: rootView.topAnchor),
      dimmingControl.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
      dimmingControl.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
      dimmingControl.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),

      sheetContainer.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
      sheetContainer.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
      sheetContainer.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
      sheetContainer.heightAnchor.constraint(equalTo: rootView.heightAnchor, multiplier: Layout.sheetHeightRatio),

      dragHandleView.topAnchor.constraint(equalTo: sheetContainer.topAnchor),
      dragHandleView.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor),
      dragHandleView.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor),
      dragHandleView.heightAnchor.constraint(equalToConstant: Layout.dragHandleHeight),

      grabberView.topAnchor.constraint(equalTo: dragHandleView.topAnchor, constant: Layout.grabberTopSpacing),
      grabberView.centerXAnchor.constraint(equalTo: dragHandleView.centerXAnchor),
      grabberView.widthAnchor.constraint(equalToConstant: Layout.grabberWidth),
      grabberView.heightAnchor.constraint(equalToConstant: Layout.grabberHeight),

      webView.topAnchor.constraint(equalTo: dragHandleView.bottomAnchor, constant: Layout.webViewTopSpacing),
      webView.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: sheetContainer.bottomAnchor),
    ])

    view = rootView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    bind()
    webView.load(URLRequest(url: authorizeURL))
  }

  private func makeDimmingControl() -> UIControl {
    let control = UIControl()
    control.backgroundColor = UIColor.black.withAlphaComponent(Layout.dimmingAlpha)
    control.addAction(
      UIAction { [weak self] _ in
        Task { @MainActor [weak self] in
          self?.backgroundTapSubject.send(())
        }
      },
      for: .touchUpInside
    )
    control.translatesAutoresizingMaskIntoConstraints = false
    return control
  }

  private func bind() {
    backgroundTapSubject
      .sink { [weak self] in
        Task { @MainActor [weak self] in
          self?.finish(.failure(AuthError.userCancelled))
        }
      }
      .store(in: &cancellables)

    sheetDragSubject
      .sink { [weak self] event in
        Task { @MainActor [weak self] in
          self?.handleSheetDrag(event)
        }
      }
      .store(in: &cancellables)
  }

  private func makeSheetContainer() -> UIView {
    let view = UIView()
    view.backgroundColor = .systemBackground
    view.layer.cornerRadius = Layout.cornerRadius
    view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    view.clipsToBounds = true
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }

  private func makeDragHandleView() -> OAuthSheetDragHandleView {
    let view = OAuthSheetDragHandleView(events: sheetDragSubject)
    view.backgroundColor = .clear
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }

  private func makeGrabberView() -> UIView {
    let view = UIView()
    view.backgroundColor = .tertiaryLabel
    view.layer.cornerRadius = Layout.grabberHeight / 2
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }

  private func handleSheetDrag(_ event: OAuthSheetDragEvent) {
    guard let sheetContainer else { return }

    switch event {
    case let .changed(translationY):
      sheetContainer.transform = CGAffineTransform(translationX: 0, y: max(0, translationY))

    case let .ended(translationY):
      if translationY >= Layout.dismissDragThreshold {
        finish(.failure(AuthError.userCancelled))
      } else {
        UIView.animate(
          withDuration: 0.25,
          delay: 0,
          options: [.curveEaseOut, .allowUserInteraction]
        ) {
          sheetContainer.transform = .identity
        }
      }

    case .cancelled:
      UIView.animate(
        withDuration: 0.2,
        delay: 0,
        options: [.curveEaseOut, .allowUserInteraction]
      ) {
        sheetContainer.transform = .identity
      }
    }
  }

  private func finish(_ result: Result<String, Error>) {
    guard !didFinish else { return }
    didFinish = true
    let completion = onComplete
    dismiss(animated: true) {
      completion(result)
    }
  }

  private func callbackResult(from components: URLComponents) -> Result<String, Error> {
    if let error = components.queryItems?.first(where: { $0.name == "error" })?.value {
      return .failure(AuthError.backendError(error))
    }

    guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
          !code.isEmpty
    else {
      return .failure(AuthError.unknownError("OAuth authorization code 를 받지 못했습니다"))
    }

    return .success(code)
  }
}

private enum OAuthSheetDragEvent {
  case changed(CGFloat)
  case ended(CGFloat)
  case cancelled
}

private final class OAuthSheetDragHandleView: UIControl {
  private let events: PassthroughSubject<OAuthSheetDragEvent, Never>
  private var initialTouchPoint: CGPoint?

  init(events: PassthroughSubject<OAuthSheetDragEvent, Never>) {
    self.events = events
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func beginTracking(_ touch: UITouch, with _: UIEvent?) -> Bool {
    initialTouchPoint = touch.location(in: self)
    return true
  }

  override func continueTracking(_ touch: UITouch, with _: UIEvent?) -> Bool {
    guard let initialTouchPoint else { return false }
    let currentPoint = touch.location(in: self)
    events.send(.changed(currentPoint.y - initialTouchPoint.y))
    return true
  }

  override func endTracking(_ touch: UITouch?, with _: UIEvent?) {
    defer { initialTouchPoint = nil }
    guard let touch,
          let initialTouchPoint
    else {
      events.send(.cancelled)
      return
    }

    let currentPoint = touch.location(in: self)
    events.send(.ended(currentPoint.y - initialTouchPoint.y))
  }

  override func cancelTracking(with _: UIEvent?) {
    initialTouchPoint = nil
    events.send(.cancelled)
  }
}

extension OAuthWebViewController: WKNavigationDelegate {
  func webView(
    _: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    guard let url = navigationAction.request.url,
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else {
      decisionHandler(.allow)
      return
    }

    let isCallback = url.host == redirectHost && url.path == redirectPath
    guard isCallback else {
      decisionHandler(.allow)
      return
    }

    decisionHandler(.cancel)
    finish(callbackResult(from: components))
  }
}

// MARK: - Presentation helper

@MainActor
enum OAuthWebPresenter {
  /// 현재 화면 위에 OAuth WebView 를 띄우고, code 를 비동기로 반환.
  static func present(
    authorizeURL: URL,
    redirectHost: String,
    redirectPath: String,
    customUserAgent: String? = nil
  ) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
      let controller = OAuthWebViewController(
        authorizeURL: authorizeURL,
        redirectHost: redirectHost,
        redirectPath: redirectPath,
        customUserAgent: customUserAgent,
        onComplete: { result in
          continuation.resume(with: result)
        }
      )

      guard let top = topViewController() else {
        continuation.resume(throwing: AuthError.missingPresentingController)
        return
      }
      top.present(controller, animated: true)
    }
  }

  private static func topViewController(
    base: UIViewController? = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
      .compactMap(\.keyWindow)
      .first?.rootViewController
  ) -> UIViewController? {
    if let nav = base as? UINavigationController {
      return topViewController(base: nav.visibleViewController)
    }
    if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
      return topViewController(base: selected)
    }
    if let presented = base?.presentedViewController {
      return topViewController(base: presented)
    }
    return base
  }
}

enum OAuthWebUserAgent {
  static var mobileSafari: String {
    let version = ProcessInfo.processInfo.operatingSystemVersion
    let osVersion = "\(version.majorVersion)_\(version.minorVersion)"

    return """
    Mozilla/5.0 (iPhone; CPU iPhone OS \(osVersion) like Mac OS X) AppleWebKit/605.1.15 \
    (KHTML, like Gecko) Version/\(version.majorVersion).\(version.minorVersion) Mobile/15E148 Safari/604.1
    """
  }
}
