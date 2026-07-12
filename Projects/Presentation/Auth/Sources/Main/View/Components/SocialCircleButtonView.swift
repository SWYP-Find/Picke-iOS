//
//  SocialCircleButtonView.swift
//  Auth
//
//  Created by Wonji Suh  on 5/14/26.
//

import AuthenticationServices
import ComposableArchitecture
import Entity
import AuthDomain
import AuthDomainInterface
import SwiftUI

struct SocialCircleButtonView: View {
  @State var store: StoreOf<LoginFeature>
  let type: SocialType
  let onTap: () -> Void

  private let circleSize: CGFloat = 72

  @ViewBuilder
  var body: some View {
    switch type {
    case .apple:
      ZStack {
        Circle()
          .fill(.black)
          .frame(width: circleSize, height: circleSize)

        Image(systemName: type.image)
          .resizable()
          .scaledToFit()
          .frame(width: 32, height: 32)
          .foregroundStyle(.white)

        SignInWithAppleButton(.signIn) { request in
          store.send(.async(.prepareAppleRequest(request)))
        } onCompletion: { result in
          store.send(.async(.appleLogin(result, nonce: store.nonce)))
        }
        .frame(width: circleSize, height: circleSize)
        .clipShape(Circle())
        .opacity(0.02)
        .allowsHitTesting(true)
      }

    case .google:
      Button(action: onTap) {
        Circle()
          .fill(.white)
          .overlay(Circle().stroke(.gray50, lineWidth: 1))
          .frame(width: circleSize, height: circleSize)
          .overlay(
            Image(assetName: type.image)
              .resizable()
              .scaledToFit()
              .frame(width: 32, height: 32)
          )
      }
      .buttonStyle(.plain)

    case .kakao:
      Button(action: onTap) {
        Circle()
          .fill(.clear)
          .overlay(Circle().stroke(.gray50, lineWidth: 1))
          .frame(width: circleSize, height: circleSize)
          .overlay(
            Image(assetName: type.image)
              .resizable()
              .scaledToFit()
              .frame(width: circleSize, height: circleSize)
          )
      }
      .buttonStyle(.plain)
    }
  }
}
