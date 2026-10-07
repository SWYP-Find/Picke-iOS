import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassDetailFeature.self)
public struct ClassDetailView: View {
  @Bindable public var store: StoreOf<ClassDetailFeature>

  public init(store: StoreOf<ClassDetailFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "클래스 상세") {
        if store.room.role == .owner {
          Button { send(.managementTapped) } label: {
            Image(systemName: "ellipsis")
              .font(.system(size: 20))
              .frame(width: 24, height: 24)
          }
          .accessibilityLabel("클래스 관리")
        }
      }
      .foregroundStyle(.gray800)

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          VStack(alignment: .leading, spacing: 16) {
            headerSection()
            classInformation()
          }
          battleSection()
          actionButtons()
        }
        .padding(16)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .pickeModal(
      $store.scope(state: \.modal, action: \.modal),
      dimOpacity: 0.28
    ) { modalStore in
      switch modalStore.kind {
      case .management:
        modalBackdrop({ send(.managementDismissed) }) {
          ClassManagementSheet(
            room: store.room,
            onEdit: { send(.deadlineTapped) },
            onDelete: { send(.deleteTapped) }
          )
        }
      case .deadline:
        modalBackdrop({ modalStore.send(.dismissTapped) }) { deadlineSheet() }
      case .code:
        modalBackdrop({ send(.codeDismissed) }) { codeSheet() }
      }
    }
    .customAlert($store.scope(state: \.customAlert, action: \.customAlert))
  }
}

private extension ClassDetailView {
  @ViewBuilder
  func headerSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(store.room.status == .open ? "진행 중" : "종료")
        .pretendardFont(.medium13)
        .foregroundStyle(.primary500)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.beige600, in: RoundedRectangle(cornerRadius: 2))

      Text(store.room.name)
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
    }
  }

  @ViewBuilder
  func classInformation() -> some View {
    VStack(spacing: 0) {
      Button { send(.membersTapped) } label: {
        informationRow(
          "클래스 멤버",
          detail: "총 \(store.room.memberCount)명이 참여하고 있어요",
          actionTitle: "보기"
        )
      }
      .buttonStyle(.plain)
      Rectangle().fill(.beige600).frame(height: 1)
      Button { send(.deadlineTapped) } label: {
        informationRow(
          "참여 마감일",
          detail: store.deadlineText,
          actionTitle: "수정"
        )
      }
      .buttonStyle(.plain)
      .disabled(store.room.role != .owner)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }

  @ViewBuilder
  func informationRow(_ title: String, detail: String, actionTitle: String) -> some View {
    HStack(spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .pretendardFont(.semiBold15)
          .foregroundStyle(.gray800)
        Text(detail)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
      }
      Spacer(minLength: 0)
      HStack(spacing: 4) {
        Text(actionTitle)
          .pretendardFont(family: .Bold, size: 12)
        Image(systemName: "chevron.right")
          .font(.system(size: 10, weight: .semibold))
      }
      .foregroundStyle(.primary500)
    }
    .frame(height: 64)
  }

  @ViewBuilder
  func battleSection() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("이번 클래스 배틀")
        .pretendardFont(.semiBold15)
        .foregroundStyle(.gray300)

      Button { send(.battleTapped) } label: {
        HStack(spacing: 8) {
          AsyncImage(url: store.room.battle.thumbnailURL) { image in
            image.resizable().scaledToFill()
          } placeholder: {
            Color.beige600
          }
          .frame(width: 76, height: 94)
          .clipShape(RoundedRectangle(cornerRadius: 2))

          VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
              HStack(spacing: 6) {
                Text("#\(store.room.battle.category.title)")
                  .pickeBadge(.filled, size: .tag)
                Text(store.room.battle.title)
                  .pretendardFont(family: .SemiBold, size: 14)
                  .foregroundStyle(.gray500)
                  .lineLimit(1)
              }
              Text(store.room.battle.summary)
                .pretendardFont(.regular13)
                .foregroundStyle(.gray300)
                .lineLimit(2)
            }
            HStack(spacing: 2) {
              Spacer(minLength: 0)
              Image(systemName: "clock")
                .font(.system(size: 12))
              Text("\(store.room.battle.durationMinutes)분")
                .pretendardFont(family: .Medium, size: 12)
            }
            .foregroundStyle(.gray300)
          }
          .frame(height: 94)
          Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  func actionButtons() -> some View {
    VStack(spacing: 12) {
      Button { send(.codeTapped) } label: {
        Text("참여 코드 보기")
          .pretendardFont(.headingMedium)
          .foregroundStyle(.primary500)
          .frame(maxWidth: .infinity)
          .frame(height: 52)
          .background(.primary50, in: RoundedRectangle(cornerRadius: 2))
      }
      .buttonStyle(.plain)
      Button("결과 보기") { send(.reportTapped) }
        .ctaButtonStyle(.primary, size: .large, height: 52)
    }
  }

  @ViewBuilder
  func modalBackdrop(
    _ onDismiss: @escaping () -> Void,
    @ViewBuilder content: () -> some View
  ) -> some View {
    ZStack(alignment: .bottom) {
      Color.clear
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
      content()
        .frame(maxWidth: .infinity)
        .background(
          UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
            .fill(.beige50)
            .ignoresSafeArea(edges: .bottom)
        )
    }
  }

  var sheetHandle: some View {
    Capsule()
      .fill(.gray50)
      .frame(width: 40, height: 4)
      .frame(maxWidth: .infinity)
      .padding(.bottom, 10)
  }

  @ViewBuilder
  func deadlineSheet() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      sheetHandle
      Text("마감일 수정")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)

      DatePicker("마감일", selection: $store.draftDeadline, displayedComponents: [.date, .hourAndMinute])
        .datePickerStyle(.compact)

      Button("수정하기") { send(.deadlineSaved) }
        .ctaButtonStyle(.primary, size: .large, height: 52)
        .disabled(store.isLoading)
    }
    .padding(.top, 16)
    .padding(.horizontal, 16)
    .padding(.bottom, 40)
  }

  @ViewBuilder
  func codeSheet() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      sheetHandle
      Text("참여 코드")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
      Text(store.room.joinCode)
        .pretendardFont(.semiBold24)
        .foregroundStyle(.primary500)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.beige600, in: RoundedRectangle(cornerRadius: 2))
      ShareLink(item: "[Picke] '\(store.room.name)' 클래스 참여 코드: \(store.room.joinCode)") {
        Text("코드 공유하기")
          .frame(maxWidth: .infinity)
      }
      .ctaButtonStyle(.primary, size: .large, height: 52)
    }
    .padding(.top, 16)
    .padding(.horizontal, 16)
    .padding(.bottom, 40)
  }
}
