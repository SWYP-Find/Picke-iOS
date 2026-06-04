//
//  TermsAgreementView.swift
//  Auth
//
//  .pen `애플 구글_약관 동의` — Apple/Google 신규 가입자 약관 동의 커스텀 바텀시트.
//  Picke `.customAlert` / Attendance `.attendanceModal` 과 동일한 오버레이 방식.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity

struct TermsAgreementView: View {
  @Bindable var store: StoreOf<TermsAgreementFeature>

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .onTapGesture { store.send(.view(.dismissTapped)) }

      sheet()
    }
  }

  @ViewBuilder
  private func sheet() -> some View {
    VStack(spacing: 20) {
      grabber()
      logo()
      header()
      VStack(spacing: 4) {
        ForEach(TermsDocument.allCases) { document in
          agreementRow(document)
        }
      }
      agreeButton()
    }
    .padding(.top, 16)
    .padding(.horizontal, 16)
    .padding(.bottom, 40)
    .frame(maxWidth: .infinity)
    .background(
      UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
        .fill(Color.beige50)
        .ignoresSafeArea(edges: .bottom)
    )
  }

  @ViewBuilder
  private func grabber() -> some View {
    RoundedRectangle(cornerRadius: 2)
      .fill(.beige600)
      .frame(width: 40, height: 4)
  }

  @ViewBuilder
  private func logo() -> some View {
    Image(asset: .appLogo)
      .resizable()
      .scaledToFit()
      .frame(width: 50, height: 32)
  }

  @ViewBuilder
  private func header() -> some View {
    VStack(spacing: 6) {
      Text("픽케 약관 동의서")
        .pretendardFont(family: .SemiBold, size: 24)
        .foregroundStyle(.neutral900)
      Text("편리한 서비스 이용을 위해 약관에 동의해 주세요")
        .pretendardFont(family: .Regular, size: 14)
        .foregroundStyle(.neutral400)
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  private func agreementRow(_ document: TermsDocument) -> some View {
    let isChecked = store.agreed.contains(document)
    HStack(spacing: 12) {
      Button { store.send(.view(.toggled(document))) } label: {
        HStack(spacing: 12) {
          checkbox(isChecked: isChecked)
          Text(document.title)
            .pretendardFont(family: .Regular, size: 14)
            .foregroundStyle(.neutral900)
        }
      }
      .buttonStyle(.plain)

      Spacer()

      Button { store.send(.view(.detailTapped(document))) } label: {
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .regular))
          .foregroundStyle(.neutral900)
          .frame(width: 24, height: 24)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .padding(16)
    .background(.beige300, in: RoundedRectangle(cornerRadius: 6))
    .overlay {
      RoundedRectangle(cornerRadius: 6).stroke(.beige600, lineWidth: 1)
    }
  }

  @ViewBuilder
  private func checkbox(isChecked: Bool) -> some View {
    ZStack {
      Circle()
        .fill(isChecked ? Color.primary500 : Color.primary50)
        .overlay { Circle().stroke(isChecked ? Color.primary500 : Color.primary100, lineWidth: 1) }
      if isChecked {
        Image(systemName: "checkmark")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(.beige50)
      }
    }
    .frame(width: 24, height: 24)
  }

  @ViewBuilder
  private func agreeButton() -> some View {
    Button { store.send(.view(.agreeTapped)) } label: {
      Text("동의")
        .pretendardFont(family: .SemiBold, size: 16)
        .foregroundStyle(.beige50)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(.primary500, in: RoundedRectangle(cornerRadius: 2))
    }
    .buttonStyle(.plain)
    .disabled(!store.canAgree)
    .opacity(store.canAgree ? 1 : 0.5)
  }
}
