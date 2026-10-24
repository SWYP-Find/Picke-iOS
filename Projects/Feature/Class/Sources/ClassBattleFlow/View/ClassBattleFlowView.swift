import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassBattleFlowFeature.self)
public struct ClassBattleFlowView: View {
  @Bindable public var store: StoreOf<ClassBattleFlowFeature>

  public init(store: StoreOf<ClassBattleFlowFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      navigationBar
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          artwork
          contentSection()
        }
      }
      .scrollIndicators(.hidden)
      footerSection()
    }
    .background { Color.white.ignoresSafeArea() }
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
    .onDisappear { send(.onDisappear) }
  }
}

private extension ClassBattleFlowView {
  var navigationBar: some View {
    PickeNavigationBar(
      onBack: { send(.backTapped) },
      centerTitle: store.room.name
    )
  }

  var artwork: some View {
    Group {
      if let url = store.session?.battle.thumbnailURL ?? store.room.battle.thumbnailURL {
        AsyncImage(url: url) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Color.beige600
        }
      } else {
        Image(asset: .classAIVoteArtwork)
          .resizable()
          .scaledToFill()
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 220)
    .clipped()
    .accessibilityHidden(true)
  }

  @ViewBuilder
  func contentSection() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      titleSection()
      switch store.viewState {
      case .loading:
        loadingSection()
      case .error:
        errorSection()
      case .loaded:
        participationSection()
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 24)
    .padding(.bottom, 28)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  func titleSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(store.session?.battle.title ?? store.room.battle.title)
        .pretendardFont(.bold24)
        .foregroundStyle(.gray800)
        .fixedSize(horizontal: false, vertical: true)
      Text(store.session?.battle.summary ?? store.room.battle.summary)
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.gray400)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder
  func loadingSection() -> some View {
    VStack(spacing: 12) {
      SkeletonView(.rect)
        .frame(height: 64)
      SkeletonView(.rect)
        .frame(height: 64)
    }
    .accessibilityLabel("클래스 배틀을 불러오는 중")
  }

  @ViewBuilder
  func errorSection() -> some View {
    VStack(spacing: 12) {
      Text(store.errorMessage ?? "배틀 정보를 불러오지 못했어요.")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray500)
      Button("다시 시도") { send(.retryTapped) }
        .pretendardFont(.semiBold13)
        .foregroundStyle(.primary500)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 30)
  }

  @ViewBuilder
  func participationSection() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      Text(store.stageDescription)
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.gray500)

      if store.shouldShowOptions {
        optionSection()
      }
      if store.isAudioStep {
        audioSection()
      }
      if store.shouldShowComposer {
        composerSection()
      }
      if store.step == .some(.completed), !store.shouldShowComposer {
        completionSection()
      }
      if store.step == .some(.completed) {
        perspectiveSection()
      }
    }
  }

  @ViewBuilder
  func optionSection() -> some View {
    VStack(spacing: 10) {
      ForEach(store.options) { option in
        optionCard(option)
      }
    }
  }

  @ViewBuilder
  func optionCard(_ option: ClassBattleOption) -> some View {
    Button {
      send(.optionTapped(option.id))
    } label: {
      HStack(spacing: 12) {
        Text(option.label ?? "")
          .pretendardFont(family: .SemiBold, size: 16)
          .frame(width: 24)
        VStack(alignment: .leading, spacing: 3) {
          Text(option.title)
            .pretendardFont(family: .SemiBold, size: 16)
          if !option.stance.isEmpty {
            Text(option.stance)
              .pretendardFont(.regular13)
              .foregroundStyle(.gray500)
          }
        }
        Spacer(minLength: 0)
      }
      .foregroundStyle(.gray800)
      .padding(16)
      .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
      .background(
        store.selectedOptionID == option.id ? Color.primary50 : Color.white,
        in: RoundedRectangle(cornerRadius: 12)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .strokeBorder(
            store.selectedOptionID == option.id ? Color.primary500 : Color.gray200,
            lineWidth: 1
          )
      }
    }
    .buttonStyle(.plain)
    .disabled(!store.canParticipate)
  }

  @ViewBuilder
  func audioSection() -> some View {
    VStack(spacing: 18) {
      ProgressView(value: store.audioProgress)
        .tint(.primary500)
      HStack {
        Text(store.currentTimeText)
        Spacer()
        Text(store.audioDurationText)
      }
      .pretendardFont(.regular13)
      .foregroundStyle(.gray500)

      AudioPlayerControlView(
        isPlaying: .constant(store.isPlaying),
        onBackward: { send(.seekBy(-15)) },
        onTogglePlay: { send(.playbackTapped) },
        onForward: { send(.seekBy(15)) },
        onReplay: { send(.replayTapped) },
        isReplayEnabled: store.hasListened,
        tint: .primary500,
        playbackRateTitle: store.playbackRateTitle,
        onPlaybackRateSelected: { send(.playbackRateSelected($0)) }
      )
      .disabled(!store.isAudioReady)
    }
    .padding(20)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 16))
  }

  @ViewBuilder
  func composerSection() -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("내 의견")
        .pretendardFont(family: .SemiBold, size: 16)
        .foregroundStyle(.gray800)
      TextField(
        "선택한 입장의 이유를 적어 주세요.",
        text: Binding(
          get: { store.draft },
          set: { send(.draftChanged($0)) }
        ),
        axis: .vertical
      )
      .lineLimit(4 ... 8)
      .pretendardFont(.bodyMedium)
      .padding(14)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 12))
    }
  }

  @ViewBuilder
  func completionSection() -> some View {
    HStack(spacing: 10) {
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(.primary500)
      Text("사후투표를 완료했어요.")
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.gray800)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(.primary50, in: RoundedRectangle(cornerRadius: 12))
  }

  @ViewBuilder
  func perspectiveSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("클래스 의견")
        .pretendardFont(family: .SemiBold, size: 16)
        .foregroundStyle(.gray800)

      ForEach(store.perspectives) { perspective in
        perspectiveCard(perspective)
      }

      if store.isLoadingPerspectives {
        SkeletonView(.rect)
          .frame(height: 80)
      } else if store.perspectives.isEmpty, store.perspectiveErrorMessage == nil {
        Text("아직 등록된 의견이 없어요.")
          .pretendardFont(.bodyMedium)
          .foregroundStyle(.gray500)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 24)
      }

      if let error = store.perspectiveErrorMessage {
        Text(error)
          .pretendardFont(.regular13)
          .foregroundStyle(.primary500)
      }
      if store.hasMorePerspectives, !store.isLoadingPerspectives {
        Button("의견 더 보기") { send(.loadMorePerspectivesTapped) }
          .pretendardFont(.semiBold13)
          .foregroundStyle(.primary500)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
      }
    }
  }

  @ViewBuilder
  func perspectiveCard(_ perspective: ClassPerspectiveItem) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(perspective.author.nickname)
        .pretendardFont(.semiBold13)
        .foregroundStyle(.gray800)
      Text(perspective.content)
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.gray800)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 12))
  }

  @ViewBuilder
  func footerSection() -> some View {
    if store.viewState == .loaded {
      VStack(spacing: 8) {
        if let error = store.errorMessage {
          Text(error)
            .pretendardFont(.regular13)
            .foregroundStyle(.primary500)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        Button(store.buttonTitle) { send(.submitTapped) }
          .ctaButtonStyle(.primary, size: .large, height: 52)
          .disabled(!store.canSubmit)
      }
      .padding(.horizontal, 16)
      .padding(.top, 12)
      .padding(.bottom, 16)
      .background(.white)
    }
  }
}
