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
        case .some(.none): voteScreen()
        case .some(.postVote):
          if store.needsMidVoteRecovery { listeningScreen() }
          else { voteScreen() }
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
    .onChange(of: store.toastMessage) { _, message in
      guard let message else { return }
      ToastManager.shared.showInfo(message)
      send(.toastShown)
    }
  }
}

private extension ClassBattleFlowView {
  var isFinalVote: Bool { store.step == .some(.postVote) }
  var isPreVoteLanding: Bool { store.step == .some(.completed) && store.showsPreVoteLanding }
  var voteBackground: Color { isFinalVote ? .gray900 : .white }

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
                  ? max(330, min(405, proxy.size.height * 0.5 + 15))
                  : max(315, min(390, proxy.size.height * 0.5))
            )
            voteIntroduction()
            if !isPreVoteLanding {
              optionSection()
                .padding(.top, 40)
            }
          }
          .padding(.horizontal, 16)
          .frame(minHeight: max(0, proxy.size.height - 110), alignment: .top)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
          voteFooter(bottomPadding: voteFooterBottomPadding(hasBottomSafeArea: proxy.safeAreaInsets.bottom > 0))
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
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        if let category = store.voteCategoryLabel {
          voteCategoryBadge(category)
        }
        Spacer(minLength: 0)
        if !isFinalVote, let commentCount = store.voteCommentCountLabel {
          voteCommentCountBadge(commentCount)
        }
      }

      Text(store.displayTitle)
        .pretendardFont(.bold24, lineHeightMultiple: 1.3)
        .foregroundStyle(isFinalVote ? .white : .gray800)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 20)
      Text(store.displaySummary)
        .pretendardFont(.bodyMedium, lineHeightMultiple: 1.4)
        .foregroundStyle(isFinalVote ? .gray300 : .gray400)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 12)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  func voteCategoryBadge(_ category: String) -> some View {
    Text(category)
      .pretendardFont(.semiBold12)
      .foregroundStyle(.badgeFilledText)
      .lineLimit(1)
      .frame(height: 16)
      .padding(.horizontal, 4)
      .padding(.vertical, 2)
      .background(.badgeFilledBackground, in: RoundedRectangle(cornerRadius: 2))
  }

  @ViewBuilder
  func voteCommentCountBadge(_ count: String) -> some View {
    HStack(spacing: 2) {
      Image(asset: .commentMessage)
        .resizable()
        .frame(width: 16, height: 16)
        .accessibilityHidden(true)
      Text(count)
        .pretendardFont(.labelSmall)
        .fixedSize()
    }
    .foregroundStyle(.gray300)
    .padding(.horizontal, 6)
    .padding(.vertical, 4)
    .background(.white, in: RoundedRectangle(cornerRadius: 2))
    .overlay {
      RoundedRectangle(cornerRadius: 2)
        .strokeBorder(.gray100, lineWidth: 1)
    }
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
          .pretendardFont(.semiBold11)
          .foregroundStyle(.gray800)
          .frame(width: 28, height: 28)
          .background(.secondary200, in: Circle())
          .allowsHitTesting(false)
      }
    }
  }

  @ViewBuilder
  func optionCard(
    _ option: ClassBattleOption,
    isPreVoteDraft: Bool
  ) -> some View {
    let isSelected = (isPreVoteDraft ? preVoteDraftOptionID : store.selectedOptionID) == option.id
    Button {
      if isPreVoteDraft { preVoteDraftOptionID = option.id }
      else { send(.optionTapped(option.id)) }
    } label: {
      VStack(spacing: 0) {
        Group {
          if let url = option.imageURL {
            AsyncImage(url: url) { image in
              image.resizable().scaledToFill()
            } placeholder: {
              Circle().fill(.beige600)
            }
          } else {
            Circle().fill(.beige600)
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
          .foregroundStyle(.gray800)
          .lineLimit(2)
          .multilineTextAlignment(.center)
          .frame(minHeight: 20)
          .padding(.top, 12)
        Text(option.representative)
          .pretendardFont(.labelSmall, lineHeightMultiple: 1.4)
          .foregroundStyle(.neutral300)
          .lineLimit(1)
          .padding(.top, 2)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 109)
      .background(
        isSelected ? Color.beige400 : .beige300,
        in: RoundedRectangle(cornerRadius: 2)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 2)
          .strokeBorder(isSelected ? Color.secondary500 : .beige600, lineWidth: 1)
      }
      .opacity(isSelected ? 1 : 0.88)
    }
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .buttonStyle(.plain)
    .disabled(!store.canParticipate)
  }

  @ViewBuilder
  func voteFooter(bottomPadding: CGFloat) -> some View {
    VStack(spacing: 8) {
      if let error = store.errorMessage {
        Text(error)
          .pretendardFont(.regular13)
          .foregroundStyle(.primary500)
      }
      Button(store.voteFooterButtonTitle) {
        send(isPreVoteLanding ? .preVoteResultTapped : .submitTapped)
      }
        .ctaButtonStyle(.primary, size: .large, height: 52)
        .disabled(!isPreVoteLanding && !store.canSubmit)
      if !isFinalVote, let deadline = store.voteDeadlineLabel {
        Label(
          deadline,
          systemImage: "clock"
        )
          .pretendardFont(.regular13, lineHeightMultiple: 1.4)
          .foregroundStyle(.gray300)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.bottom, bottomPadding)
  }

  func voteFooterBottomPadding(hasBottomSafeArea: Bool) -> CGFloat {
    if isFinalVote { return hasBottomSafeArea ? 6 : 10 }
    // 홈 인디케이터가 있는 기기에서는 Figma처럼 마지막 줄인 마감 문구만 그 영역에 10pt 걸친다.
    guard hasBottomSafeArea, store.voteDeadlineLabel != nil else { return 20 }
    return -10
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
          let rows = store.visibleTranscriptRows
          LazyVStack(alignment: .leading, spacing: 6) {
            ForEach(rows) { row in
              transcriptRow(row)
                .padding(.top, row.hasTopSpacing ? 14 : 0)
                .id(row.id)
            }
          }
          .padding(.horizontal, 16)
          .padding(.top, 8)
          .padding(.bottom, 40)
        }
        .onChange(of: store.currentTime) { _, _ in
          if let row = store.visibleTranscriptRows.last {
            withAnimation(.easeInOut(duration: 0.2)) {
              proxy.scrollTo(row.id, anchor: .bottom)
            }
          }
        }
      }
      if store.pendingCheckpointID != nil {
        midVoteChoiceSection()
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
  func midVoteChoiceSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("선택의 시간")
        .pretendardFont(.headingMedium)
        .foregroundStyle(.neutral900)
      ForEach(store.midVoteOptions) { option in
        Button {
          send(.midVoteOptionTapped(option.nextNodeId))
        } label: {
          VStack(alignment: .leading, spacing: 4) {
            if let title = option.title, !title.isEmpty, title != option.label {
              Text(option.label)
                .pretendardFont(.labelSmall)
                .foregroundStyle(.neutral600)
            }
            Text(option.title.flatMap { $0.isEmpty ? nil : $0 } ?? option.label)
              .pretendardFont(.bodyMedium)
              .foregroundStyle(.neutral900)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(12)
            .background(
              store.selectedMidOptionID == option.nextNodeId ? .beige300 : .white,
              in: RoundedRectangle(cornerRadius: 4)
            )
            .overlay {
              RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                  store.selectedMidOptionID == option.nextNodeId ? .primary500 : .beige600,
                  lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
      }
      Button("입장 선택하기") { send(.confirmMidVoteTapped) }
        .ctaButtonStyle(.primary, size: .large, height: 52)
        .disabled(!store.canConfirmMidVote)
    }
    .padding(16)
    .background(.beige200)
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
  func transcriptRow(_ row: ClassBattleTranscriptRow) -> some View {
    let line = row.line
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
      let bubbleBackground: Color = line.side == "B" ? .beige400 : .white
      let bubbleBorder: Color = .beige600
      HStack(alignment: .top, spacing: 6) {
        if line.side != "B" {
          transcriptAvatar(row)
        }
        VStack(alignment: line.side == "B" ? .trailing : .leading, spacing: 6) {
          if row.showsHeader {
            Text(line.speakerName)
              .pretendardFont(.headingSmall, lineHeightMultiple: 1.4)
              .foregroundStyle(.gray800)
          }
          Text(line.text)
            .pretendardFont(.regular13, lineHeightMultiple: 1.4)
            .foregroundStyle(.gray400)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, line.side == "B" ? 8 : 6)
            .pickeCard(bubbleBackground, border: bubbleBorder)
            .overlay(alignment: line.side == "B" ? .leading : .trailing) {
              if row.isActive && store.isPlaying {
                AudioEqualizerView()
                  .frame(width: 24, height: 24)
                  .offset(x: line.side == "B" ? -36 : 36)
              }
            }
        }
        .frame(maxWidth: 272, alignment: line.side == "B" ? .trailing : .leading)
        if line.side == "B" {
          transcriptAvatar(row)
        }
      }
      .frame(maxWidth: .infinity, alignment: line.side == "B" ? .trailing : .leading)
    }
  }

  @ViewBuilder
  func transcriptAvatar(_ row: ClassBattleTranscriptRow) -> some View {
    ZStack {
      if row.showsHeader {
        Group {
          if let url = row.line.speakerImageURL, !url.isEmpty {
            PickeRemoteImage(url: url, shape: .round(cornerRadius: 16))
              .content(.fit)
              .frame(width: 32, height: 36)
          } else {
            Text(row.avatarFallback)
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
          if store.pendingCheckpointID == nil {
            Button("다시 시도") { send(.retryAudioTapped) }
          }
        }
      }
      VStack(spacing: 0) {
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
        .disabled(!store.isAudioReady || store.pendingCheckpointID != nil)
      }
      if store.hasListened {
        Button(store.buttonTitle) { send(.submitTapped) }
          .ctaButtonStyle(.primary, size: .large, height: 52)
          .disabled(!store.canSubmit)
      }
    }
    .padding(.horizontal, 24)
    .padding(.top, 24)
    .padding(.bottom, 8)
    .background(.white)
  }

  @ViewBuilder
  func audioProgressBar() -> some View {
    VStack(spacing: 0) {
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule().fill(.gray300).frame(height: 3)
          Capsule()
            .fill(.primary500)
            .frame(width: geometry.size.width * store.audioProgress, height: 3)
          Circle()
            .fill(.primary500)
            .frame(width: 11, height: 11)
            .offset(x: max(0, geometry.size.width * store.audioProgress - 5.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle().inset(by: -8))
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
      .frame(height: 11)
      HStack {
        Text(store.currentTimeText)
        Spacer()
        Text(store.audioDurationText)
      }
      .pretendardFont(.regular13, lineHeightMultiple: 1.4)
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
          if let row = store.hiddenMyPerspectiveRow {
            perspectiveCard(row)
          }
          ForEach(store.perspectiveRows) { row in
            perspectiveCard(row)
          }
          if store.isLoadingPerspectives {
            SkeletonView(.rect).frame(height: 90)
          } else if store.perspectives.isEmpty && store.perspectiveErrorMessage == nil
            && store.hiddenMyPerspectiveRow == nil {
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
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
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
    .padding(.top, 8)
    .padding(.bottom, 8)
    .frame(maxWidth: .infinity)
    .background(.beige200)
  }

  @ViewBuilder
  func voteStatsSummary(_ stats: ClassVoteStats) -> some View {
    let rows = store.voteStatsOptionRows
    HStack(alignment: .top, spacing: 0) {
      if let first = rows.first {
        voteStatsOption(first)
      }
      // Figma는 높이 76 열에서 막대 영역(35)을 아래에 붙여 배지와 11 떨어진다.
      VStack(spacing: 11) {
        if let opinionChangeLabel = store.opinionChangeLabel {
          Label(
            opinionChangeLabel,
            systemImage: "lightbulb"
          )
          .pretendardFont(.semiBold12)
          .foregroundStyle(.primary500)
          .padding(.horizontal, 4)
          .frame(height: 20)
          .background(.primary50, in: RoundedRectangle(cornerRadius: 2))
          .fixedSize()
        } else {
          Color.clear.frame(height: 20)
        }
        voteRatioBar(stats)
          .padding(.horizontal, 8)
          .frame(height: 35)
      }
      .padding(.top, 10)
      .frame(maxWidth: .infinity)
      if rows.count > 1 {
        voteStatsOption(rows[1])
      }
    }
  }

  @ViewBuilder
  func voteRatioBar(_ stats: ClassVoteStats) -> some View {
    GeometryReader { geometry in
      RoundedRectangle(cornerRadius: 2)
        .fill(.beige500)
        .overlay(alignment: .leading) {
          RoundedRectangle(cornerRadius: 2)
            .fill(.primary500)
            .frame(
              width: geometry.size.width * CGFloat(min(max(stats.options.first?.ratio ?? 0, 0), 100) / 100)
            )
        }
    }
    .frame(height: 6)
  }

  @ViewBuilder
  func voteStatsOption(_ row: ClassVoteStatsOptionRow) -> some View {
    let option = row.option
    VStack(spacing: 0) {
      AsyncImage(url: option.imageURL) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        Text(row.avatarFallback)
          .pretendardFont(.semiBold13)
          .foregroundStyle(.gray800)
      }
      .frame(width: 40, height: 40)
      .background(.beige600, in: Circle())
      .clipShape(Circle())
      Text(option.title)
        .pretendardFont(.medium11, lineHeightMultiple: 1.4)
        .foregroundStyle(.gray500)
        .lineLimit(1)
        .padding(.top, 4)
      Text(row.percentageLabel)
        .pretendardFont(.semiBold12, lineHeightMultiple: 1.4)
        .foregroundStyle(.gray500)
    }
    .frame(width: 70)
  }

  @ViewBuilder
  func perspectiveFilters() -> some View {
    HStack(spacing: 0) {
      perspectiveFilter(title: "전체", optionID: nil)
      ForEach(store.options) { option in
        perspectiveFilter(title: option.title, optionID: option.id)
      }
    }
    .background(.beige200)
  }

  @ViewBuilder
  func perspectiveFilter(
    title: String,
    optionID: Int?
  ) -> some View {
    Button { send(.perspectiveOptionTapped(optionID)) } label: {
      Text(title)
        .pretendardFont(.labelMedium)
        .lineLimit(1)
        .foregroundStyle(store.selectedPerspectiveOptionID == optionID ? .primary500 : .gray300)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .overlay(alignment: .bottom) {
          if store.selectedPerspectiveOptionID == optionID {
            Rectangle().fill(.primary500).frame(height: 2)
          } else {
            Rectangle().fill(.gray100).frame(height: 1)
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
    .padding(.top, 16)
    .padding(.bottom, 6)
  }

  @ViewBuilder
  func sortButton(
    _ title: String,
    value: String
  ) -> some View {
    Button { send(.perspectiveSortTapped(value)) } label: {
      Text(title)
        .pretendardFont(.medium13)
        .foregroundStyle(store.perspectiveSort == value ? .white : .primary500)
        .frame(width: 58, height: 30)
        .background(store.perspectiveSort == value ? Color.primary500 : .primary50, in: RoundedRectangle(cornerRadius: 2))
        .overlay {
          RoundedRectangle(cornerRadius: 2)
            .stroke(.primary500, lineWidth: 1)
        }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func perspectiveCard(_ row: ClassPerspectiveRow) -> some View {
    let perspective = row.perspective
    VStack(alignment: .leading, spacing: 8) {
      perspectiveHeader(row)
      VStack(alignment: .leading, spacing: 4) {
        Button { send(.perspectiveTapped(perspective.id)) } label: {
          Text(perspective.content)
            .pretendardFont(.regular13, lineHeightMultiple: 1.4)
            .foregroundStyle(.gray300)
            .lineLimit(3)
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(row.statusBadgeTitle != nil)
        Button("자세히 보기") { send(.perspectiveTapped(perspective.id)) }
          .pretendardFont(.labelSmall, lineHeightMultiple: 1.4)
          .foregroundStyle(.gray200)
          .padding(.horizontal, 2)
          .buttonStyle(.plain)
          .disabled(row.statusBadgeTitle != nil)
      }
      perspectiveActions(row)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(row.isPendingReview ? Color.secondary50 : row.isRejected ? .primary50 : .white)
    .overlay(alignment: .bottom) {
      Rectangle().fill(.beige600).frame(height: 1)
    }
    .overlay(alignment: .bottomTrailing) {
      if store.menuTargetPerspectiveID == perspective.id {
        perspectiveMenu(row)
          .padding(.bottom, 40)
          .padding(.trailing, 16)
      }
    }
    .zIndex(store.menuTargetPerspectiveID == perspective.id ? 1 : 0)
  }

  /// 더보기 메뉴 — Android 순서(내 의견: 삭제·수정, 거절: 수정, 남 의견: 신고).
  @ViewBuilder
  func perspectiveMenu(_ row: ClassPerspectiveRow) -> some View {
    let id = row.perspective.id
    VStack(alignment: .trailing, spacing: 8) {
      switch row.menuKind {
      case .report:
        PickeActionPill(title: "신고", systemImage: "light.beacon.max.fill") { send(.perspectiveReportTapped(id)) }
      case .editOnly:
        PickeActionPill(title: "수정", systemImage: "pencil") { send(.perspectiveEditTapped(id)) }
      case .editAndDelete:
        PickeActionPill(title: "삭제", systemImage: "trash") { send(.perspectiveDeleteTapped(id)) }
        PickeActionPill(title: "수정", systemImage: "pencil") { send(.perspectiveEditTapped(id)) }
      case .hidden:
        EmptyView()
      }
    }
  }

  @ViewBuilder
  func perspectiveHeader(_ row: ClassPerspectiveRow) -> some View {
    let perspective = row.perspective
    HStack(spacing: 8) {
      PickeAvatarView(
        imageURL: perspective.author.characterImageURL?.absoluteString,
        fallback: perspective.author.nickname,
        size: 36
      )
      VStack(alignment: .leading, spacing: 2) {
        Text(perspective.author.nickname)
          .pretendardFont(.semiBold12, lineHeightMultiple: 1.4)
          .foregroundStyle(.gray800)
        Text(row.createdAtLabel)
          .pretendardFont(.labelXSmall, lineHeightMultiple: 1.4)
          .foregroundStyle(.gray300)
      }
      Spacer()
      if let statusTitle = row.statusBadgeTitle {
        Text(statusTitle)
          .pretendardFont(.semiBold12)
          .foregroundStyle(.white)
          .lineLimit(1)
          .frame(height: 16)
          .padding(.horizontal, 4)
          .padding(.vertical, 2)
          .background(row.isRejected ? Color.primary400 : .secondary500, in: RoundedRectangle(cornerRadius: 2))
      } else {
        Text(perspective.option.title)
          .pretendardFont(.semiBold12)
          .foregroundStyle(.badgeFilledText)
          .lineLimit(1)
          .frame(height: 16)
          .padding(.horizontal, 4)
          .padding(.vertical, 2)
          .background(.badgeFilledBackground, in: RoundedRectangle(cornerRadius: 2))
      }
    }
  }

  @ViewBuilder
  func perspectiveActions(_ row: ClassPerspectiveRow) -> some View {
    let perspective = row.perspective
    HStack(spacing: 10) {
      Button { send(.perspectiveLikeTapped(perspective.id)) } label: {
        HStack(spacing: 2) {
          Image(asset: .heartPlus)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
          Text(row.likeCountLabel)
            .pretendardFont(.labelSmall)
        }
        .foregroundStyle(perspective.isLiked ? .primary500 : .gray300)
      }
      .disabled(perspective.isMyPerspective != false)
      Button { send(.perspectiveTapped(perspective.id)) } label: {
        HStack(spacing: 2) {
          Image(asset: .commentMessage)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
          Text(row.commentCountLabel)
            .pretendardFont(.labelSmall)
        }
        .foregroundStyle(.gray300)
      }
      // Android처럼 검수 중·거절된 의견은 상세로 이동하지 않는다.
      .disabled(row.statusBadgeTitle != nil)
      Spacer()
      if row.menuKind.hasMenu {
        Button { send(.perspectiveMoreTapped(perspective.id)) } label: {
          Image(systemName: "ellipsis")
            .resizable()
            .scaledToFit()
            .frame(width: 15, height: 3)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle().inset(by: -10))
        }
        .foregroundStyle(.gray300)
        .accessibilityLabel("더보기")
      }
    }
    .frame(height: 24)
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func composerBar() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      if store.editingPerspectiveID != nil {
        editingBanner()
      }
      if let error = store.errorMessage {
        Text(error)
          .pretendardFont(.regular13)
          .foregroundStyle(.primary500)
          .padding(.horizontal, 16)
          .padding(.top, 12)
      }
      HStack(spacing: 8) {
        TextField(
          "의견을 남겨보세요...",
          text: Binding(
            get: { store.draft },
            set: { send(.draftChanged($0)) }
          ),
          prompt: Text("의견을 남겨보세요...").foregroundStyle(.gray300)
        )
        .pretendardFont(.medium13)
        .padding(.horizontal, 12)
        .frame(height: 52)
        .background(.white, in: RoundedRectangle(cornerRadius: 2))
        .overlay {
          RoundedRectangle(cornerRadius: 2)
            .strokeBorder(.beige600, lineWidth: 1)
        }
        Button { send(.submitTapped) } label: {
          Image(systemName: "paperplane.fill")
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(.primary500, in: Circle())
            .contentShape(Rectangle().inset(by: -2))
        }
        .buttonStyle(.plain)
        .disabled(!store.canSubmit)
      }
      .padding(16)
    }
    .background(.beige600)
    .overlay(alignment: .top) {
      Rectangle().fill(.beige700).frame(height: 1)
    }
  }

  @ViewBuilder
  func editingBanner() -> some View {
    HStack {
      Text("의견 수정 중")
        .pretendardFont(.semiBold12)
        .foregroundStyle(.primary500)
      Spacer()
      Button("취소") { send(.cancelEditTapped) }
        .pretendardFont(.medium13)
        .foregroundStyle(.gray400)
        .buttonStyle(.plain)
    }
    .padding(.horizontal, 16)
    .padding(.top, 12)
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
      onBack: { send(.backTapped) },
      centerTitle: store.displayTitle
    ) {
      Button { send(.reportTapped) } label: {
        Label("리포트", systemImage: "list.bullet.rectangle")
          .pretendardFont(.bold11)
      }
      .buttonStyle(.plain)
      .foregroundStyle(.primary500)
    }
    .background(.beige200)
    .accessibilityAction(named: "뒤로 가기") { send(.backTapped) }
  }
}
