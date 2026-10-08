import ClassDomainInterface
import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassClosedBattleFeature.self)
public struct ClassClosedBattleView: View {
  @Bindable public var store: StoreOf<ClassClosedBattleFeature>

  public init(store: StoreOf<ClassClosedBattleFeature>) {
    self.store = store
  }

  public var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .top) {
        Color.white.ignoresSafeArea()
        artwork(height: geometry.size.height * 0.66 + geometry.safeAreaInsets.top)
          .offset(y: -geometry.safeAreaInsets.top)

        VStack(spacing: 0) {
          navigationBar
          Spacer(minLength: 0)
          battleInformation()
        }
      }
    }
    .toolbar(.hidden, for: .navigationBar)
  }
}

private extension ClassClosedBattleView {
  var navigationBar: some View {
    PickeNavigationBar(
      onBack: { send(.backTapped) },
      centerTitle: store.room.name
    )
    .foregroundStyle(.white)
  }

  @ViewBuilder
  func artwork(height: CGFloat) -> some View {
    Group {
      #if DEBUG
        if store.room.id == ClassRoom.mockClosedSociety.id {
          Image(asset: .classClosedBattle)
            .resizable()
            .scaledToFill()
        } else {
          remoteArtwork
        }
      #else
        remoteArtwork
      #endif
    }
    .frame(maxWidth: .infinity)
    .frame(height: height)
    .clipped()
    .overlay {
      LinearGradient(
        stops: [
          .init(color: .clear, location: 0.52),
          .init(color: .white, location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .accessibilityHidden(true)
  }

  var remoteArtwork: some View {
    AsyncImage(url: store.room.battle.thumbnailURL) { image in
      image.resizable().scaledToFill()
    } placeholder: {
      Color.beige600
    }
  }

  @ViewBuilder
  func battleInformation() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("#\(store.room.battle.category.title)")
          .pickeBadge(.filled, size: .tag)
        Spacer()
        if store.room.battle.commentCount > 0 {
          Label("\(store.room.battle.commentCount)", systemImage: "bubble")
            .pretendardFont(.regular13)
            .foregroundStyle(.gray300)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .overlay {
              RoundedRectangle(cornerRadius: 2)
                .stroke(.gray100, lineWidth: 1)
            }
            .accessibilityLabel("댓글 \(store.room.battle.commentCount)개")
        }
      }
      .padding(.bottom, 24)

      Text(store.room.battle.title)
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
        .padding(.bottom, 16)

      Text(store.room.battle.summary)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray500)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 28)

      resultButton
      deadlineLabel
        .padding(.top, 8)
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  var resultButton: some View {
    Button("결과 보기") { send(.resultTapped) }
      .ctaButtonStyle(.primary, size: .large, height: 52)
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

#if DEBUG
  #Preview("마감 배틀 결과 진입") {
    ClassClosedBattleView(store: Store(initialState: .init(room: .mockClosedSociety)) {
      ClassClosedBattleFeature()
    })
  }
#endif
