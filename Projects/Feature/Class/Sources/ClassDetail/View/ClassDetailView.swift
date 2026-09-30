import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassDetailFeature.self)
public struct ClassDetailView: View {
  @Bindable public var store: StoreOf<ClassDetailFeature>

  public init(store: StoreOf<ClassDetailFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "클래스 상세")
        .foregroundStyle(.gray500)

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          headerSection()
          classInformation()
          battleSection()
          if store.room.role == .owner {
            deleteButton
          }
        }
        .padding(16)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .hidesSystemBars()
    .sheet(isPresented: $store.isDeadlineSheetPresented) {
      deadlineSheet()
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }
    .alert("클래스를 삭제할까요?", isPresented: $store.isDeleteAlertPresented) {
      Button("취소", role: .cancel) {}
      Button("삭제", role: .destructive) { send(.deleteConfirmed) }
    } message: {
      Text("삭제한 클래스는 다시 복구할 수 없어요.")
    }
  }
}

private extension ClassDetailView {
  @ViewBuilder
  func headerSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(store.room.status == .open ? "진행 중" : "종료")
        .pretendardFont(.medium13)
        .foregroundStyle(.gray500)

      Text(store.room.name)
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)

      HStack(spacing: 16) {
        Text("멤버 \(store.room.memberCount)명")
          .pretendardFont(.medium15)
          .foregroundStyle(.gray500)

        if store.room.role == .owner {
          Button("멤버 보기") { send(.membersTapped) }
            .pretendardFont(.semiBold15)
        }
      }
    }
  }

  @ViewBuilder
  func classInformation() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      informationRow("참여 코드", value: store.room.joinCode)

      if store.room.role == .owner {
        ShareLink(item: "[Picke] '\(store.room.name)' 클래스 참여 코드: \(store.room.joinCode)") {
          Text("코드 공유하기")
        }
        .pretendardFont(.semiBold15)
      }

      informationRow(
        "마감일",
        value: store.deadline.formatted(date: .numeric, time: .shortened)
      )

      if store.room.role == .owner {
        Button("마감일 수정") { send(.deadlineTapped) }
          .pretendardFont(.semiBold15)
      }

      informationRow("익명 의견", value: store.room.allowsAnonymousOpinion ? "허용" : "허용 안 함")
      informationRow("댓글 필수", value: store.room.requiresComment ? "필수" : "선택")
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.white, in: RoundedRectangle(cornerRadius: 12))
  }

  @ViewBuilder
  func informationRow(_ title: String, value: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
      Text(title)
        .pretendardFont(.medium15)
        .foregroundStyle(.gray300)
        .frame(width: 80, alignment: .leading)

      Text(value)
        .pretendardFont(.medium15)
        .foregroundStyle(.gray800)
    }
  }

  @ViewBuilder
  func battleSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("이번 클래스 배틀")
        .pretendardFont(.bold18)
        .foregroundStyle(.gray800)

      Button { send(.battleTapped) } label: {
        VStack(alignment: .leading, spacing: 8) {
          Text(store.room.battle.title)
            .pretendardFont(.bold18)
            .foregroundStyle(.gray800)
          Text(store.room.battle.summary)
            .pretendardFont(.medium15)
            .foregroundStyle(.gray500)
            .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
      }
      .buttonStyle(.plain)
    }
  }

  var deleteButton: some View {
    Button("클래스 삭제") { send(.deleteTapped) }
      .pretendardFont(.medium15)
      .foregroundStyle(.textError)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
  }

  @ViewBuilder
  func deadlineSheet() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("마감일 수정")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)

      DatePicker("마감일", selection: $store.draftDeadline, displayedComponents: [.date, .hourAndMinute])
        .datePickerStyle(.compact)

      Spacer(minLength: 0)

      Button("수정하기") { send(.deadlineSaved) }
        .ctaButtonStyle(.primary, size: .large, height: 52)
    }
    .padding(20)
    .screenBackground()
  }
}
