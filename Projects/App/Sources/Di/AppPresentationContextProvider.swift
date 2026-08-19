//
//  AppPresentationContextProvider.swift
//  Picke
//
//  Created by Wonji Suh  on 5/14/26.
//

import AuthenticationServices
import UIKit

/// 앱 전체에서 사용할 ASWebAuthenticationSession용 presentation provider
final class AppPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
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
