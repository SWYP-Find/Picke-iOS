//
//  LoginView.swift
//  Auth
//
//  Created by Wonji Suh  on 5/11/26.
//

import ComposableArchitecture
import SwiftUI

import DesignSystem
import Entity

public struct LoginView: View {
  @Bindable var store: StoreOf<LoginFeature>

  public init(store: StoreOf<LoginFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.gray50
        .edgesIgnoringSafeArea(.all)

      VStack {
        logoView()

        Spacer()
          .frame(height: 200)

        loginSNSButtonText()

        logjnButton()

        Spacer()
          .frame(height: UIScreen.screenHeight * 0.12)
      }
      .toastOverlay()
    }
    .pickeModal($store.scope(state: \.termsAgreement, action: \.termsAgreement)) { termsStore in
      TermsAgreementView(store: termsStore)
    }
  }
}

extension LoginView {
  @ViewBuilder
  private func logoView() -> some View {
    VStack(alignment: .center) {
      Spacer()

      Text(" 당신의 생각을")
        .pretendardFont(.headingMedium)
        .foregroundStyle(.neutral200)

      Image(asset: .loginLogo)
        .resizable()
        .scaledToFit()
        .frame(width: 106, height: 90)
    }
  }

  @ViewBuilder
  private func loginSNSButtonText() -> some View {
    HStack {
      Rectangle()
        .fill(.borderGrayDefault)
        .frame(width: 64, height: 1)

      Spacer()
        .frame(width: 12)

      Text("SNS 계정으로 로그인")
        .pretendardFont(.medium15)
        .foregroundStyle(.neutral300)

      Rectangle()
        .fill(.borderGrayDefault)
        .frame(width: 64, height: 1)
    }
  }

  @ViewBuilder
  private func logjnButton() -> some View {
    HStack(alignment: .center, spacing: 32) {
      ForEach(SocialType.allCases) { type in
        SocialCircleButtonView(
          store: store,
          type: type
        ) {
          store.send(.view(.signInWithSocial(social: type)))
        }
      }
    }
    .padding(.top, 32)
  }
}
