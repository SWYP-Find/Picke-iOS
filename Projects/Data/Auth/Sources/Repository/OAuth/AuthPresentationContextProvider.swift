//
//  AuthPresentationContextProvider.swift
//  AuthData
//
//  Created by Wonji Suh  on 5/14/26.
//

import AuthenticationServices
import UIKit

/// 앱 전체에서 사용할 ASWebAuthenticationSession용 presentation provider
public final class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
  override public init() { super.init() }

  public func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: { $0.isKeyWindow }) ??
      UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first?
      .windows.first ??
      ASPresentationAnchor()
  }
}
