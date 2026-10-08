import ClassDomainInterface
import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassAIVoteFeature.self)
public struct ClassAIVoteView: View {
  @Bindable public var store: StoreOf<ClassAIVoteFeature>

  public init(store: StoreOf<ClassAIVoteFeature>) {
    self.store = store
  }

  public var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .top) {
        Color.white.ignoresSafeArea()
        artwork(
          width: geometry.size.width,
          height: geometry.size.height * 0.66 + geometry.safeAreaInsets.top
        )
        .offset(y: -geometry.safeAreaInsets.top)

        VStack(spacing: 0) {
          navigationBar
          Spacer(minLength: 0)
          voteContent()
        }
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
  }
}

private extension ClassAIVoteView {
  var navigationBar: some View {
    PickeNavigationBar(
      onBack: { send(.backTapped) },
      centerTitle: store.room.name
    )
    .foregroundStyle(.white)
  }

  @ViewBuilder
  func artwork(width: CGFloat, height: CGFloat) -> some View {
    Group {
      if store.room.battle.thumbnailURL == nil {
        Image(asset: .classAIVoteArtwork)
          .resizable()
          .scaledToFill()
      } else {
        AsyncImage(url: store.room.battle.thumbnailURL) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Color.beige600
        }
      }
    }
    .frame(width: width, height: height)
    .clipped()
    .overlay {
      LinearGradient(
        colors: [.black.opacity(0.35), .black.opacity(0.28), .clear],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .overlay {
      LinearGradient(
        stops: [
          .init(color: .clear, location: 0.52),
          .init(color: .white, location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .accessibilityHidden(true)
  }

  @ViewBuilder
  func voteContent() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("#\(store.room.battle.categoryDisplayTitle)")
        .pickeBadge(.filled, size: .tag)
        .padding(.bottom, 20)

      Text(store.room.battle.title)
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 12)

      Text(store.room.battle.summary)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 26)

      voteOptions()
        .padding(.bottom, 22)

      if let errorMessage = store.errorMessage {
        Text(errorMessage)
          .pretendardFont(.regular13)
          .foregroundStyle(.primary500)
          .padding(.bottom, 8)
      }

      Button(store.hasSubmitted ? "의견 보기" : "투표하기") {
        send(.submitTapped)
      }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .disabled(!store.canSubmit)

      deadlineLabel
        .padding(.top, 8)
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  func voteOptions() -> some View {
    HStack(spacing: 0) {
      optionCard(
        id: 1,
        title: store.room.battle.optionATitle,
        subtitle: store.room.battle.optionADescription
          ?? store.room.battle.philosopherA
      )
      Text("vs")
        .pretendardFont(.semiBold13)
        .foregroundStyle(.gray500)
        .frame(width: 28, height: 28)
        .background(.beige600, in: Circle())
        .padding(.horizontal, -10)
        .zIndex(1)
      optionCard(
        id: 2,
        title: store.room.battle.optionBTitle,
        subtitle: store.room.battle.optionBDescription
          ?? store.room.battle.philosopherB
      )
    }
  }

  func optionCard(id: Int, title: String, subtitle: String) -> some View {
    let isSelected = store.selectedOptionID == id
    return Button { send(.optionTapped(id)) } label: {
      VStack(spacing: 5) {
        Text(title)
          .pretendardFont(.semiBold15)
          .foregroundStyle(.gray800)
          .lineLimit(2)
        Text(subtitle)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 78)
      .pickeCard(
        isSelected ? .primary50 : .beige300,
        border: isSelected ? .primary500 : .beige600,
        lineWidth: isSelected ? 2 : 1,
        radius: 0
      )
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  var deadlineLabel: some View {
    Label(
      store.room.deadline == .distantFuture
        ? "마감일 없음"
        : store.room.deadline.formatted(.dottedDateTimeWithWeekday) + "까지",
      systemImage: "clock"
    )
    .pretendardFont(.regular13)
    .foregroundStyle(.gray300)
    .frame(maxWidth: .infinity)
  }
}
