//
//  Extension+MoyaProvider+Auth.swift
//  Repository
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

import AsyncMoya

public extension MoyaProvider {
  /// 인증된 세션(인터셉터 부착) 기반의 Provider
  static var authorized: MoyaProvider<Target> {
    let manager = OptimizedSessionManager.shared

    return MoyaProvider(
      session: manager.session,
      plugins: [
        MoyaLoggingPlugin(),
        SessionInvalidationPlugin(),
      ]
    )
  }
}
