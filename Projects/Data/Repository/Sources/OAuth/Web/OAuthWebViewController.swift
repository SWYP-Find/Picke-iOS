//
//  OAuthWebViewController.swift
//  Repository
//
//  Created by Wonji Suh on 5/15/26.
//

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
  private let authorizeURL: URL
  private let redirectHost: String
  private let redirectPath: String
  private let customUserAgent: String?
  private let onComplete: (Result<String, Error>) -> Void
  private var didFinish = false
  private let sheetHeightRatio: CGFloat = 0.8

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

    let dimmingControl = UIControl()
    dimmingControl.backgroundColor = UIColor.black.withAlphaComponent(0.35)
    dimmingControl.addTarget(self, action: #selector(backgroundTapped), for: .touchUpInside)
    dimmingControl.translatesAutoresizingMaskIntoConstraints = false
    rootView.addSubview(dimmingControl)

    let sheetContainer = UIView()
    sheetContainer.backgroundColor = .systemBackground
    sheetContainer.layer.cornerRadius = 20
    sheetContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    sheetContainer.clipsToBounds = true
    sheetContainer.translatesAutoresizingMaskIntoConstraints = false
    rootView.addSubview(sheetContainer)

    let grabberView = UIView()
    grabberView.backgroundColor = .tertiaryLabel
    grabberView.layer.cornerRadius = 2
    grabberView.translatesAutoresizingMaskIntoConstraints = false
    sheetContainer.addSubview(grabberView)

    sheetContainer.addSubview(webView)

    NSLayoutConstraint.activate([
      dimmingControl.topAnchor.constraint(equalTo: rootView.topAnchor),
      dimmingControl.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
      dimmingControl.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
      dimmingControl.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),

      sheetContainer.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
      sheetContainer.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
      sheetContainer.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
      sheetContainer.heightAnchor.constraint(equalTo: rootView.heightAnchor, multiplier: sheetHeightRatio),

      grabberView.topAnchor.constraint(equalTo: sheetContainer.topAnchor, constant: 8),
      grabberView.centerXAnchor.constraint(equalTo: sheetContainer.centerXAnchor),
      grabberView.widthAnchor.constraint(equalToConstant: 36),
      grabberView.heightAnchor.constraint(equalToConstant: 4),

      webView.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: 8),
      webView.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: sheetContainer.bottomAnchor),
    ])

    view = rootView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    webView.load(URLRequest(url: authorizeURL))
  }

  @objc private func backgroundTapped() {
    finish(.failure(AuthError.userCancelled))
  }

  private func finish(_ result: Result<String, Error>) {
    guard !didFinish else { return }
    didFinish = true
    let completion = onComplete
    dismiss(animated: true) {
      completion(result)
    }
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

    let isCallback = url.host == redirectHost && url.path.hasPrefix(redirectPath)
    guard isCallback else {
      decisionHandler(.allow)
      return
    }

    if let error = components.queryItems?.first(where: { $0.name == "error" })?.value {
      decisionHandler(.cancel)
      finish(.failure(AuthError.backendError(error)))
      return
    }

    if let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
       !code.isEmpty
    {
      decisionHandler(.cancel)
      finish(.success(code))
      return
    }

    decisionHandler(.allow)
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
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }
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
