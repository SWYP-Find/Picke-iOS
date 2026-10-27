import ClassDomainInterface
import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassBattleFlowFeature.self)
public struct ClassBattleFlowView: View {
  @Bindable public var store: StoreOf<ClassBattleFlowFeature>
  @State private var isEditingPreVote = false
  @State private var preVoteDraftOptionID: Int?

  public init(store: StoreOf<ClassBattleFlowFeature>) {
    self.store = store
  }

  public var body: some View {
    Group {
      switch store.viewState {
      case .loading: loadingScreen()
      case .error: errorScreen()
      case .loaded:
        switch store.step {
        case .some(.none), .some(.postVote): voteScreen()
        case .some(.preVote): listeningScreen()
        case .some(.ttsListening): listeningScreen()
        case .some(.completed):
          if store.showsPreVoteLanding { voteScreen() }
          else { perspectiveScreen() }
        case nil: loadingScreen()
        }
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
    .onDisappear { send(.onDisappear) }
  }
}

private extension ClassBattleFlowView {
  var isFinalVote: Bool { store.step == .some(.postVote) }
  var isPreVoteLanding: Bool { store.step == .some(.completed) && store.showsPreVoteLanding }
  var voteBackground: Color { isFinalVote ? .black : .white }

  @ViewBuilder
  func loadingScreen() -> some View {
    VStack(spacing: 16) {
      plainNavigationBar
      SkeletonView(.rect).frame(height: 360)
      SkeletonView(.rect).frame(height: 120).padding(20)
      Spacer()
    }
    .background(.white)
    .accessibilityLabel("클래스 배틀을 불러오는 중")
  }

  @ViewBuilder
  func errorScreen() -> some View {
    VStack(spacing: 16) {
      plainNavigationBar
      Spacer()
      Text(store.errorMessage ?? "배틀 정보를 불러오지 못했어요.")
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.gray500)
      Button("다시 시도") { send(.retryTapped) }
        .pretendardFont(.semiBold13)
        .foregroundStyle(.primary500)
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .background(.white)
  }

  @ViewBuilder
  func voteScreen() -> some View {
    GeometryReader { proxy in
      ZStack(alignment: .top) {
        voteArtwork()
          .frame(
            width: proxy.size.width,
            height: max(470, proxy.size.height * 0.65) + proxy.safeAreaInsets.top
          )
          .clipped()
          .offset(y: -proxy.safeAreaInsets.top)

        ScrollView(showsIndicators: false) {
          VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(
              height: isPreVoteLanding
                ? max(420, min(510, proxy.size.height * 0.63))
                : isFinalVote
                  ? max(370, min(446, proxy.size.height * 0.56))
                  : max(315, min(390, proxy.size.height * 0.48))
            )
            voteIntroduction()
            if !isPreVoteLanding {
              optionSection()
                .padding(.top, isFinalVote ? 36 : 40)
            }
          }
          .padding(.horizontal, 16)
          .frame(minHeight: max(0, proxy.size.height - 110), alignment: .top)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
          voteFooter()
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .background(voteBackground)
        }

        voteNavigationBar()
      }
      .background(voteBackground.ignoresSafeArea())
    }
  }

  @ViewBuilder
  func voteArtwork() -> some View {
    Group {
      if let url = store.displayArtworkURL {
        AsyncImage(url: url) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Color.beige600
        }
      } else {
        Image(asset: store.room?.battleType == .custom ? .classAIVoteArtwork : .classClosedBattle)
          .resizable()
          .scaledToFill()
      }
    }
    .overlay {
      LinearGradient(
        colors: [.black.opacity(0.48), .clear],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .overlay(alignment: .bottom) {
      LinearGradient(
        colors: [.clear, voteBackground],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 210)
    }
    .accessibilityHidden(true)
  }

  @ViewBuilder
  func voteNavigationBar() -> some View {
    HStack(spacing: 12) {
      Button { send(.backTapped) } label: {
        Image(systemName: "chevron.left")
          .font(.title3)
          .frame(width: 32, height: 44)
      }
      .buttonStyle(.plain)
      Spacer()
      Text(store.room?.name ?? "")
        .pretendardFont(.headingMedium)
        .lineLimit(1)
      Spacer()
      if !isFinalVote,
         store.room?.battleType == .tts,
         let shareURL = store.session?.battle.shareURL {
        ShareLink(item: shareURL) {
          Image(systemName: "square.and.arrow.up")
            .frame(width: 32, height: 44)
        }
      } else {
        Color.clear.frame(width: 32, height: 44)
      }
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 12)
  }

  @ViewBuilder
  func voteIntroduction() -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        if let category = store.room?.battle.categoryDisplayTitle, !category.isEmpty {
          Text("#\(category)")
            .pretendardFont(.medium11)
            .foregroundStyle(isFinalVote ? .beige200 : .primary500)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(isFinalVote ? Color.clear : .beige200)
        }
        Spacer(minLength: 0)
        if !isFinalVote, let commentCount = store.room?.battle.commentCount {
          Label("\(commentCount)", systemImage: "bubble.right")
            .pretendardFont(.medium11)
            .foregroundStyle(.gray500)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .overlay(Rectangle().stroke(.beige500, lineWidth: 1))
        }
      }

      Text(store.displayTitle)
        .pretendardFont(.bold24)
        .foregroundStyle(isFinalVote ? .white : .gray800)
        .fixedSize(horizontal: false, vertical: true)
      Text(store.displaySummary)
        .pretendardFont(.bodyMedium)
        .foregroundStyle(isFinalVote ? .beige200 : .gray500)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  func optionSection(isPreVoteDraft: Bool = false) -> some View {
    ZStack {
      HStack(alignment: .top, spacing: 8) {
        ForEach(store.options) { option in
          optionCard(option, isPreVoteDraft: isPreVoteDraft)
        }
      }

      if store.options.count == 2 {
        Text("VS")
          .pretendardFont(.bold11)
          .foregroundStyle(.neutral800)
          .frame(width: 28, height: 28)
          .background(.secondary200, in: Circle())
          .overlay(Circle().stroke(.beige50, lineWidth: 1.5))
          .allowsHitTesting(false)
      }
    }
  }

  @ViewBuilder
  func optionCard(
    _ option: ClassBattleOption,
    isPreVoteDraft: Bool
  ) -> some View {
    Button {
      if isPreVoteDraft { preVoteDraftOptionID = option.id }
      else { send(.optionTapped(option.id)) }
    } label: {
      VStack(spacing: 8) {
        Group {
          if let url = option.imageURL {
            AsyncImage(url: url) { image in
              image.resizable().scaledToFill()
            } placeholder: {
              Circle().fill(.beige400)
            }
          } else {
            Circle().fill(.beige400)
              .overlay {
                Text(option.label ?? "")
                  .pretendardFont(.semiBold13)
              }
          }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        Text(option.title)
          .pretendardFont(.headingSmall)
          .foregroundStyle(.neutral600)
          .lineLimit(2)
          .multilineTextAlignment(.center)
        Text(option.representative)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.neutral300)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 106)
      .background(
        .beige300,
        in: RoundedRectangle(cornerRadius: 3)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 3)
          .strokeBorder(
            (isPreVoteDraft ? preVoteDraftOptionID : store.selectedOptionID) == option.id
              ? (isFinalVote ? Color.secondary500 : .beige700)
              : .beige500,
            lineWidth: 1
          )
      }
    }
    .buttonStyle(.plain)
    .disabled(!store.canParticipate)
  }

  @ViewBuilder
  func voteFooter() -> some View {
    VStack(spacing: 8) {
      if let error = store.errorMessage {
        Text(error)
          .pretendardFont(.regular13)
          .foregroundStyle(.primary500)
      }
      Button(isPreVoteLanding ? "결과 보기" : store.buttonTitle) {
        send(isPreVoteLanding ? .preVoteResultTapped : .submitTapped)
      }
        .ctaButtonStyle(.primary, size: .large, height: 52)
        .disabled(!isPreVoteLanding && !store.canSubmit)
      if !isFinalVote, let closeAt = store.session?.closeAt {
        Label(
          closeAt.formatted(.dottedDateTimeWithWeekday) + "까지",
          systemImage: "clock"
        )
          .pretendardFont(.regular13)
          .foregroundStyle(isFinalVote ? .beige200 : .gray500)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.bottom, isFinalVote ? 10 : 20)
  }

  @ViewBuilder
  func listeningScreen() -> some View {
    VStack(spacing: 0) {
      PickeNavigationBar(
        onBack: { send(.backTapped) },
        centerTitle: store.displayTitle
      ) {
        if store.step == .some(.preVote), store.canParticipate {
          Button("투표 변경") {
            preVoteDraftOptionID = store.selectedOptionID
            isEditingPreVote = true
          }
            .pretendardFont(.medium11)
            .foregroundStyle(.primary500)
        }
      }
      .foregroundStyle(.neutral800)
      .background(.beige200)
      ScrollViewReader { proxy in
        ScrollView(showsIndicators: false) {
          let lines = store.visibleTranscript
          LazyVStack(alignment: .leading, spacing: 6) {
            ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
              transcriptRow(
                line,
                showsHeader: index == 0 || lines[index - 1].speakerName != line.speakerName,
                isActive: index == lines.count - 1
              )
                .padding(.top, index > 0 && lines[index - 1].speakerName != line.speakerName ? 16 : 0)
                .id(line.id)
            }
          }
          .padding(.horizontal, 16)
          .padding(.top, 24)
          .padding(.bottom, 40)
        }
        .onChange(of: store.currentTime) { _, time in
          if let line = store.visibleTranscript.last(where: { $0.startTime <= time }) {
            withAnimation(.easeInOut(duration: 0.2)) {
              proxy.scrollTo(line.id, anchor: .bottom)
            }
          }
        }
      }
      audioFooter()
    }
    .screenBackground()
    .sheet(isPresented: $isEditingPreVote, onDismiss: { preVoteDraftOptionID = nil }) {
      preVoteEditor()
        .presentationDetents([.medium])
    }
  }

  @ViewBuilder
  func preVoteEditor() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("사전투표 변경하기")
        .pretendardFont(.headingMedium)
        .foregroundStyle(.gray800)
      optionSection(isPreVoteDraft: true)
      Button("사전투표 변경하기") {
        guard let preVoteDraftOptionID else { return }
        send(.optionTapped(preVoteDraftOptionID))
        send(.submitTapped)
        isEditingPreVote = false
      }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .disabled(
        !store.canParticipate || store.submitRequestID != nil
          || preVoteDraftOptionID == nil
          || preVoteDraftOptionID == store.voteHistory?.preVote.optionID
      )
      Spacer()
    }
    .padding(20)
    .background(.white)
  }

  @ViewBuilder
  func transcriptRow(
    _ line: ClassBattleTranscriptLine,
    showsHeader: Bool,
    isActive: Bool
  ) -> some View {
    if line.side == "NARRATOR" {
      Text(line.text)
        .pretendardFont(.labelSmall)
        .italic()
        .foregroundStyle(.gray700)
        .lineSpacing(4.8)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    } else {
      let bubbleBackground: Color = line.side == "B" ? .beige500 : .white
      let bubbleBorder: Color = line.side == "B" ? .beige700 : .beige500
      HStack(alignment: .top, spacing: 6) {
        if line.side != "B" {
          transcriptAvatar(line, showsAvatar: showsHeader)
        }
        VStack(alignment: line.side == "B" ? .trailing : .leading, spacing: 6) {
          if showsHeader {
            Text(line.speakerName)
              .pretendardFont(.headingSmall)
              .foregroundStyle(.gray400)
          }
          Text(line.text)
            .pretendardFont(.labelSmall)
            .foregroundStyle(.gray700)
            .lineSpacing(4.8)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .pickeCard(bubbleBackground, border: bubbleBorder)
            .overlay(alignment: line.side == "B" ? .leading : .trailing) {
              if isActive && store.isPlaying {
                AudioEqualizerView(isPlaying: true)
                  .frame(width: 24, height: 24)
                  .offset(x: line.side == "B" ? -36 : 36)
              }
            }
        }
        .frame(maxWidth: 272, alignment: line.side == "B" ? .trailing : .leading)
        if line.side == "B" {
          transcriptAvatar(line, showsAvatar: showsHeader)
        }
      }
      .frame(maxWidth: .infinity, alignment: line.side == "B" ? .trailing : .leading)
    }
  }

  @ViewBuilder
  func transcriptAvatar(
    _ line: ClassBattleTranscriptLine,
    showsAvatar: Bool
  ) -> some View {
    ZStack {
      if showsAvatar {
        Group {
          if let url = line.speakerImageURL, !url.isEmpty {
            PickeRemoteImage(url: url, shape: .round(cornerRadius: 16))
              .content(.fit)
              .frame(width: 32, height: 36)
          } else {
            Text(String(line.speakerName.prefix(1)))
              .pretendardFont(.semiBold13)
          }
        }
        .frame(width: 40, height: 40)
        .background(.beige600, in: Circle())
      }
    }
    .frame(width: 40)
  }

  @ViewBuilder
  func audioFooter() -> some View {
    VStack(spacing: 16) {
      if let error = store.errorMessage {
        HStack {
          Text(error)
            .pretendardFont(.regular13)
            .foregroundStyle(.primary500)
          Spacer()
          Button("다시 시도") { send(.retryAudioTapped) }
        }
      }
      audioProgressBar()
      AudioPlayerControlView(
        isPlaying: .constant(store.isPlaying),
        onBackward: { send(.seekBy(-15)) },
        onTogglePlay: { send(.playbackTapped) },
        onForward: { send(.seekBy(15)) },
        onReplay: { send(.replayTapped) },
        isReplayEnabled: store.hasListened,
        tint: .neutral900,
        playbackRateTitle: store.playbackRateTitle,
        onPlaybackRateSelected: { send(.playbackRateSelected($0)) }
      )
      .disabled(!store.isAudioReady)
      if store.hasListened {
        Button(store.buttonTitle) { send(.submitTapped) }
          .ctaButtonStyle(.primary, size: .large, height: 52)
          .disabled(!store.canSubmit)
      }
    }
    .padding(.horizontal, 24)
    .padding(.top, 16)
    .padding(.bottom, 8)
    .background(.white)
    .topDivider(.beige600)
  }

  @ViewBuilder
  func audioProgressBar() -> some View {
    VStack(spacing: 8) {
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule().fill(.beige600).frame(height: 4)
          Capsule()
            .fill(.primary500)
            .frame(width: geometry.size.width * store.audioProgress, height: 4)
          Circle()
            .fill(.primary500)
            .frame(width: 16, height: 16)
            .offset(x: max(0, geometry.size.width * store.audioProgress - 8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              guard store.hasListened, geometry.size.width > 0, store.audioDuration > 0 else { return }
              let ratio = min(max(value.location.x / geometry.size.width, 0), 1)
              send(.scrub(store.audioDuration * Double(ratio)))
            }
        )
        .allowsHitTesting(store.hasListened)
      }
      .frame(height: 16)
      HStack {
        Text(store.currentTimeText)
        Spacer()
        Text(store.audioDurationText)
      }
      .pretendardFont(.medium11)
      .foregroundStyle(.neutral300)
    }
  }

  @ViewBuilder
  func perspectiveScreen() -> some View {
    VStack(spacing: 0) {
      perspectiveNavigationBar
      perspectiveSummary()
      perspectiveFilters()
      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 0) {
          perspectiveSortRow()
          ForEach(store.perspectives) { perspective in
            perspectiveCard(perspective)
          }
          if store.isLoadingPerspectives {
            SkeletonView(.rect).frame(height: 90)
          } else if store.perspectives.isEmpty && store.perspectiveErrorMessage == nil {
            Text("아직 등록된 의견이 없어요.")
              .pretendardFont(.bodyMedium)
              .foregroundStyle(.gray500)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 32)
          }
          if let error = store.perspectiveErrorMessage {
            Text(error)
              .pretendardFont(.regular13)
              .foregroundStyle(.primary500)
          }
          if store.hasPublishedPerspective == nil && store.myPerspectiveRequestID == nil {
            Button("내 의견 확인 다시 시도") { send(.retryMyPerspectiveTapped) }
              .pretendardFont(.semiBold13)
              .foregroundStyle(.primary500)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
          }
          if store.hasMorePerspectives && !store.isLoadingPerspectives {
            Button("의견 더 보기") { send(.loadMorePerspectivesTapped) }
              .pretendardFont(.semiBold13)
              .foregroundStyle(.primary500)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
          }
        }
      }
      if store.shouldShowComposer {
        composerBar()
      }
    }
    .background(.white)
    .simultaneousGesture(
      DragGesture(minimumDistance: 30).onEnded { gesture in
        guard gesture.startLocation.x <= 24,
              gesture.translation.width > 80,
              abs(gesture.translation.height) < gesture.translation.width
        else { return }
        send(.backTapped)
      }
    )
  }

  @ViewBuilder
  func perspectiveSummary() -> some View {
    VStack(spacing: 0) {
      if let stats = store.voteStats, !stats.options.isEmpty {
        voteStatsSummary(stats)
      } else if store.voteStatsRequestID != nil {
        SkeletonView(.rect).frame(height: 92)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 12)
    .padding(.bottom, 16)
    .frame(maxWidth: .infinity)
    .background(.white)
  }

  @ViewBuilder
  func voteStatsSummary(_ stats: ClassVoteStats) -> some View {
    HStack(alignment: .center, spacing: 12) {
      if let first = stats.options.first {
        voteStatsOption(first)
      }
      VStack(spacing: 20) {
        if let opinionChangeLabel = store.opinionChangeLabel {
          Label(
            opinionChangeLabel,
            systemImage: "lightbulb"
          )
          .pretendardFont(.medium11)
          .foregroundStyle(.primary500)
          .padding(.horizontal, 6)
          .padding(.vertical, 4)
          .background(.beige200)
          .fixedSize()
        } else {
          Color.clear.frame(height: 20)
        }
        voteRatioBar(stats)
      }
      .frame(maxWidth: .infinity)
      if stats.options.count > 1 {
        voteStatsOption(stats.options[1])
      }
    }
  }

  @ViewBuilder
  func voteRatioBar(_ stats: ClassVoteStats) -> some View {
    GeometryReader { geometry in
      Capsule()
        .fill(.beige300)
        .overlay(alignment: .leading) {
          Capsule()
            .fill(.primary500)
            .frame(
              width: geometry.size.width * CGFloat(min(max(stats.options.first?.ratio ?? 0, 0), 100) / 100)
            )
        }
    }
    .frame(height: 6)
  }

  @ViewBuilder
  func voteStatsOption(_ option: ClassVoteStatsOption) -> some View {
    VStack(spacing: 2) {
      AsyncImage(url: option.imageURL) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        Text(String(option.title.prefix(1)))
          .pretendardFont(.semiBold13)
          .foregroundStyle(.gray800)
      }
      .frame(width: 40, height: 40)
      .background(.beige200, in: Circle())
      .clipShape(Circle())
      Text(option.title)
        .pretendardFont(.medium11)
        .foregroundStyle(.gray800)
        .lineLimit(1)
      Text("\(option.ratio.formatted(.number.precision(.fractionLength(1))))%")
        .pretendardFont(.semiBold13)
        .foregroundStyle(.gray800)
    }
    .frame(width: 64)
  }

  @ViewBuilder
  func perspectiveFilters() -> some View {
    HStack(spacing: 0) {
      perspectiveFilter(title: "전체", optionID: nil)
      ForEach(store.options) { option in
        perspectiveFilter(title: option.title, optionID: option.id)
      }
    }
    .background(.white)
  }

  @ViewBuilder
  func perspectiveFilter(
    title: String,
    optionID: Int?
  ) -> some View {
    Button { send(.perspectiveOptionTapped(optionID)) } label: {
      Text(title)
        .pretendardFont(.semiBold13)
        .lineLimit(1)
        .foregroundStyle(store.selectedPerspectiveOptionID == optionID ? .primary500 : .gray500)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
          if store.selectedPerspectiveOptionID == optionID {
            Rectangle().fill(.primary500).frame(height: 2)
          }
        }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func perspectiveSortRow() -> some View {
    HStack(spacing: 8) {
      sortButton("인기순", value: "popular")
      sortButton("최신순", value: "latest")
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 16)
  }

  @ViewBuilder
  func sortButton(
    _ title: String,
    value: String
  ) -> some View {
    Button { send(.perspectiveSortTapped(value)) } label: {
      Text(title)
        .pretendardFont(.medium11)
        .foregroundStyle(store.perspectiveSort == value ? .white : .primary500)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(store.perspectiveSort == value ? Color.primary500 : Color.white, in: RoundedRectangle(cornerRadius: 2))
        .overlay {
          RoundedRectangle(cornerRadius: 2)
            .stroke(.primary500, lineWidth: 1)
        }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func perspectiveCard(_ perspective: ClassPerspectiveItem) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      perspectiveHeader(perspective)
      VStack(alignment: .leading, spacing: 4) {
        Button { send(.perspectiveTapped(perspective.id)) } label: {
          Text(perspective.content)
            .pretendardFont(.regular13)
            .foregroundStyle(.gray500)
            .lineSpacing(5)
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        Button("자세히 보기") { send(.perspectiveTapped(perspective.id)) }
          .pretendardFont(.labelSmall)
          .foregroundStyle(.gray200)
          .buttonStyle(.plain)
      }
      perspectiveActions(perspective)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.white)
    .overlay(alignment: .bottom) {
      Rectangle().fill(.beige200).frame(height: 1)
    }
  }

  @ViewBuilder
  func perspectiveHeader(_ perspective: ClassPerspectiveItem) -> some View {
    HStack(spacing: 8) {
      PickeAvatarView(
        imageURL: perspective.author.characterImageURL?.absoluteString,
        fallback: perspective.author.nickname,
        size: 40
      )
      VStack(alignment: .leading, spacing: 2) {
        Text(perspective.author.nickname)
          .pretendardFont(.semiBold13)
          .foregroundStyle(.gray800)
        Text(perspective.createdAt, style: .relative)
          .pretendardFont(.regular11)
          .foregroundStyle(.gray500)
      }
      Spacer()
      Text(perspective.option.title)
        .pretendardFont(.medium11)
        .foregroundStyle(.primary500)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(.beige200)
    }
  }

  @ViewBuilder
  func perspectiveActions(_ perspective: ClassPerspectiveItem) -> some View {
    HStack(spacing: 10) {
      Button { send(.perspectiveLikeTapped(perspective.id)) } label: {
        HStack(spacing: 2) {
          Image(asset: .heartPlus)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
          Text(perspective.likeCount.decimalFormatted)
            .pretendardFont(.labelSmall)
        }
        .foregroundStyle(perspective.isLiked ? .primary500 : .gray500)
      }
      .disabled(perspective.isMyPerspective != false)
      Button { send(.perspectiveTapped(perspective.id)) } label: {
        HStack(spacing: 2) {
          Image(asset: .commentMessage)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
          Text(perspective.commentCount.decimalFormatted)
            .pretendardFont(.labelSmall)
        }
        .foregroundStyle(.gray500)
      }
      Spacer()
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func composerBar() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      if let error = store.errorMessage {
        Text(error)
          .pretendardFont(.regular13)
          .foregroundStyle(.primary500)
          .padding(.horizontal, 16)
          .padding(.top, 12)
      }
      HStack(spacing: 12) {
        TextField(
          "의견을 입력하세요",
          text: Binding(
            get: { store.draft },
            set: { send(.draftChanged($0)) }
          )
        )
        .pretendardFont(.bodyMedium)
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(.white, in: RoundedRectangle(cornerRadius: 4))
        Button { send(.submitTapped) } label: {
          Image(systemName: "paperplane.fill")
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(.primary500, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!store.canSubmit)
      }
      .padding(16)
    }
    .background(.beige200)
  }

  var plainNavigationBar: some View {
    PickeNavigationBar(
      onBack: { send(.backTapped) },
      centerTitle: store.displayTitle
    )
    .background(.beige50)
  }

  var perspectiveNavigationBar: some View {
    PickeNavigationBar(
      centerTitle: store.displayTitle
    ) {
      Button { send(.reportTapped) } label: {
        Label("리포트", systemImage: "list.bullet.rectangle")
          .pretendardFont(.medium11)
      }
      .buttonStyle(.plain)
      .foregroundStyle(.primary500)
    }
    .background(.beige50)
    .accessibilityAction(named: "뒤로 가기") { send(.backTapped) }
  }
}
