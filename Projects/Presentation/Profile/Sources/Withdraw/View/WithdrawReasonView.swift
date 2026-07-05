//
//  WithdrawReasonView.swift
//  Profile
//
//  회원 탈퇴 UI — picke.pen `탈퇴하기`.
//  타이틀 + 안내문 + 탈퇴 사유(복수 선택) + 제출하기/픽케로 다시 돌아가기.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem

@ViewAction(for: WithdrawReasonFeature.self)
public struct WithdrawReasonView: View {
  @Bindable public var store: StoreOf<WithdrawReasonFeature>

  public init(store: StoreOf<WithdrawReasonFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      PickeNavigationBar(onBack: { send(.backTapped) })
        .foregroundStyle(.gray500)

      title()
      subtitle()
      reasonList()
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.beige200.ignoresSafeArea())
    .safeAreaInset(edge: .bottom, spacing: 0) { bottomButtons() }
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }
}

private extension WithdrawReasonView {
  // MARK: 타이틀

  @ViewBuilder
  func title() -> some View {
    Text("\(store.nickname.isEmpty ? "회원" : store.nickname)님 정말 떠나시나요? 아쉬워요 🥲")
      .pretendardCustomFont(textStyle: .bold18)
      .foregroundStyle(.primary500)
      .kerning(-0.45)
      .padding(.horizontal, 20)
  }

  // MARK: 안내문

  @ViewBuilder
  func subtitle() -> some View {
    Text("지금까지 픽케를 이용해주셔서 감사합니다.\n더 나은 서비스를 만들기 위해, 탈퇴 이유를 알려주세요.")
      .pretendardCustomFont(textStyle: .labelMedium)
      .foregroundStyle(.gray400)
      .lineSpacing(4)
      .padding(.horizontal, 20)
  }

  // MARK: 탈퇴 사유

  @ViewBuilder
  func reasonList() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      ForEach(WithdrawReasonFeature.Reason.allCases) { reason in
        reasonRow(reason)
      }
    }
    .padding(.horizontal, 20)
  }

  @ViewBuilder
  func reasonRow(_ reason: WithdrawReasonFeature.Reason) -> some View {
    let isSelected = store.selectedReasons.contains(reason)

    Button {
      send(.reasonTapped(reason))
    } label: {
      HStack(spacing: 8) {
        checkbox(isSelected: isSelected)

        Text(reason.rawValue)
          .pretendardCustomFont(textStyle: .labelMedium)
          .foregroundStyle(isSelected ? .gray800 : .gray300)

        Spacer(minLength: 0)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func checkbox(isSelected: Bool) -> some View {
    ZStack {
      Circle()
        .fill(isSelected ? Color.primary500 : Color.primary50)
        .overlay(
          Circle().stroke(isSelected ? Color.primary700 : Color.primary100, lineWidth: 1)
        )

      if isSelected {
        Image(systemName: "checkmark")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(.beige50)
      }
    }
    .frame(width: 24, height: 24)
  }

  // MARK: 하단 버튼

  @ViewBuilder
  func bottomButtons() -> some View {
    HStack(spacing: 0) {
      Button {
        send(.submitTapped)
      } label: {
        Text("제출하기")
          .pretendardCustomFont(textStyle: .headingMedium)
          .foregroundStyle(.primary500)
          .frame(maxWidth: .infinity)
          .frame(height: 60)
          .background(.secondary50)
      }
      .buttonStyle(.plain)
      .disabled(store.isProcessing)

      Button {
        send(.backTapped)
      } label: {
        Text("픽케로 다시 돌아가기")
          .pretendardCustomFont(textStyle: .headingMedium)
          .foregroundStyle(.beige50)
          .frame(maxWidth: .infinity)
          .frame(height: 60)
          .background(.primary500)
      }
      .buttonStyle(.plain)
    }
  }
}
