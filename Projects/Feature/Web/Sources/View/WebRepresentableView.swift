//
//  WebRepresentableView.swift
//  Profile
//
//  Created by Wonji Suh  on 1/4/26.
//

import SwiftUI
import WebKit

import PickeDesignKit

public struct WebRepresentableView: UIViewRepresentable {
  // MARK: - URL to load

  private var urlToLoad: String

  public init(urlToLoad: String) {
    self.urlToLoad = urlToLoad
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  public func makeUIView(context: Context) -> UIView {
    // 컨테이너
    let containerView = UIView()
    containerView.backgroundColor = UIColor(red: 26 / 255.0, green: 26 / 255.0, blue: 26 / 255.0, alpha: 1.0)

    // WKWebView
    let configuration = WKWebViewConfiguration()
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.scrollView.showsVerticalScrollIndicator = false
    webView.scrollView.minimumZoomScale = 1.0
    webView.scrollView.maximumZoomScale = 1.0
    webView.navigationDelegate = context.coordinator
    webView.uiDelegate = context.coordinator
    webView.allowsLinkPreview = true
    webView.backgroundColor = UIColor(red: 26 / 255.0, green: 26 / 255.0, blue: 26 / 255.0, alpha: 1.0)
    webView.translatesAutoresizingMaskIntoConstraints = false

    // ProgressView(로딩 인디케이터) 표시
    let loadingContainer = createLoadingIndicator()
    loadingContainer.translatesAutoresizingMaskIntoConstraints = false

    containerView.addSubview(webView)
    containerView.addSubview(loadingContainer)

    NSLayoutConstraint.activate([
      // WebView는 전체
      webView.topAnchor.constraint(equalTo: containerView.topAnchor),
      webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
      webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

      // 로딩 인디케이터는 중앙
      loadingContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      loadingContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])

    // 코디네이터가 참조 보관
    context.coordinator.webView = webView
    context.coordinator.loadingIndicator = loadingContainer

    // 로드 직전에 로딩 컨테이너 표시
    loadingContainer.alpha = 1

    // 로드
    _Concurrency.Task {
      await loadURLInWebView(urlToLoad: urlToLoad, webView: webView)
    }

    return containerView
  }

  func loadURLInWebView(urlToLoad: String, webView: WKWebView) async {
    guard let url = URL(string: urlToLoad) else {
      return
    }
    let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)

    await MainActor.run {
      webView.configuration.upgradeKnownHostsToHTTPS = true
      webView.configuration.preferences.minimumFontSize = 16
      webView.load(request)
    }
  }

  public func updateUIView(_: UIView, context _: Context) {
    // 필요 시 업데이트
  }

  // MARK: - Loading Indicator

  private func createLoadingIndicator() -> UIView {
    let indicator = UIActivityIndicatorView(style: .large)
    indicator.color = .white
    indicator.hidesWhenStopped = false
    indicator.startAnimating()
    return indicator
  }

  // MARK: - Coordinator

  public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var parent: WebRepresentableView
    weak var webView: WKWebView?
    weak var loadingIndicator: UIView?

    init(_ parent: WebRepresentableView) {
      self.parent = parent
    }

    // MARK: - WKNavigationDelegate

    public func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
      // 로딩 시작 → AnimatedImage 표시 (MainActor 최적화)
      Task { @MainActor [weak self] in
        guard let self, let loadingIndicator else { return }
        loadingIndicator.alpha = 1
      }
    }

    public func webView(_: WKWebView, didFinish _: WKNavigation!) {
      // 로딩 완료 → AnimatedImage 숨김(페이드아웃)
      hideLoadingIndicator()
    }

    public func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
      hideLoadingIndicator()
    }

    public func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError _: Error) {
      hideLoadingIndicator()
    }

    private func hideLoadingIndicator() {
      Task { @MainActor [weak self] in
        guard let self, let loadingIndicator else { return }

        UIView.animate(withDuration: 0.3, animations: {
          loadingIndicator.alpha = 0
        })
      }
    }
  }
}
