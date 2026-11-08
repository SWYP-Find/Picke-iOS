//
//  HeroCarouselView.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import HomeDomainInterface
import PickeDesignKit
import PickeSharedUI
import SwiftUI

/// 최상단 EDITOR PICK 캐러셀 — Android `EditorPickSection` 시안.
/// 위 배지·쪽 번호 줄은 고정이고, 아래 이미지 + 설명만 넘어간다. 3초마다 자동 넘김, 마지막 뒤엔 처음으로.
struct HeroCarouselView: View {
  let heroes: [HeroBattle]
  @Binding var currentIndex: Int
  var onTap: (HeroBattle) -> Void = { _ in }

  private static let autoScrollInterval: TimeInterval = 3
  private let timer = Timer.publish(every: autoScrollInterval, on: .main, in: .common).autoconnect()

  var body: some View {
    VStack(spacing: 0) {
      controlRow()
      pager
    }
    .background(.black)
    .onReceive(timer) { _ in advance() }
  }

  private func advance() {
    guard heroes.count > 1 else { return }
    // Android tween(600, FastOutSlowInEasing)
    withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.6)) {
      currentIndex = (currentIndex + 1) % heroes.count
    }
  }
}

// MARK: - Sections

extension HeroCarouselView {
  @ViewBuilder
  private func controlRow() -> some View {
    HStack(spacing: 0) {
      editorPickBadge
      Spacer(minLength: 0)
      pageCounter
    }
    .padding(16)
  }

  private var editorPickBadge: some View {
    Text("EDITOR PICK")
      .pretendardFont(.semiBold11)
      .foregroundStyle(.secondary200)
      .padding(.horizontal, 8)
      .padding(.vertical, 2)
      .roundedBackground(.primary500)
  }

  /// 현재 쪽은 흰색 Bold, "/전체"는 베이지 60% — 10pt, 배경 textSubtler 80% radius 12.
  private var pageCounter: some View {
    let current = Text("\(min(currentIndex, heroes.count - 1) + 1)")
      .font(.pretendardFontFamily(family: .Bold, size: 10))
      .foregroundStyle(.white)
    let total = Text("/\(heroes.count)")
      .font(.pretendardFontFamily(family: .SemiBold, size: 10))
      .foregroundStyle(.surfaceBeigeDefault.opacity(0.6))
    return Text("\(current)\(total)")
      .padding(.horizontal, 8)
      .padding(.vertical, 2)
      .background(.textSubtler.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
  }

  /// 높이는 투명 기준 레이아웃(폭 ÷ 1.8 이미지 + 빈 설명)에서 정하고 그 위에 페이지를 겹친다.
  private var pager: some View {
    VStack(spacing: 0) {
      Color.clear
        .aspectRatio(1.8, contentMode: .fit)
      HeroSubjectView(
        title: " ",
        summary: " ",
        tagsText: " ",
        viewCountText: " "
      )
      .hidden()
    }
    .overlay {
      TabView(selection: $currentIndex) {
        ForEach(Array(heroes.enumerated()), id: \.element.id) { index, hero in
          HeroPageView(hero: hero)
            .contentShape(Rectangle())
            .onTapGesture { onTap(hero) }
            .tag(index)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
    }
  }
}

// MARK: - Page

/// 캐러셀 한 쪽 — 이미지(폭 ÷ 1.8) + 설명.
private struct HeroPageView: View {
  let hero: HeroBattle

  var body: some View {
    VStack(spacing: 0) {
      thumbnail
      HeroSubjectView(
        title: hero.title,
        summary: hero.summary,
        tagsText: hero.tags.map { "#\($0.name)" }.joined(separator: " "),
        viewCountText: "\(hero.viewCount.formatted())"
      )
    }
    .frame(maxHeight: .infinity, alignment: .top)
  }

  /// 이미지 위 검정 30% 덮개 + 가운데 선택지 · VS.
  private var thumbnail: some View {
    Color.clear
      .aspectRatio(1.8, contentMode: .fit)
      .overlay {
        if let url = hero.thumbnailURL {
          PickeRemoteImage(url: url) {
            SkeletonView(
              .rect,
              base: .gray600,
              highlight: .gray400
            )
          }
        }
      }
      .clipped()
      .overlay {
        Color.black.opacity(0.3)
      }
      .overlay {
        versusRow()
      }
  }

  @ViewBuilder
  private func versusRow() -> some View {
    HStack(spacing: 16) {
      optionText(hero.optionA)
      Image(asset: .vs)
        .renderingMode(.template)
        .resizable()
        .frame(width: 18, height: 32)
        .foregroundStyle(.white)
      optionText(hero.optionB)
    }
  }

  /// Android 그림자 offset 2px·blur 4px → 3x 기준 pt.
  private func optionText(_ text: String) -> some View {
    Text(text)
      .pretendardFont(.headingMedium)
      .foregroundStyle(.white)
      .shadow(
        color: .black,
        radius: 4.0 / 3,
        x: 2.0 / 3,
        y: 2.0 / 3
      )
  }
}

/// 이미지 아래 설명 — 제목 1줄, 요약 항상 2줄 높이, 태그 + 조회수.
private struct HeroSubjectView: View {
  let title: String
  let summary: String
  let tagsText: String
  let viewCountText: String

  /// Android `minLines = 2` — 자연 높이 + 줄높이(12 × 1.4). `reservesSpace` 는 줄 간격을 빼고 잡아 쓰지 않는다.
  private static let summaryMinHeight: CGFloat = {
    let natural = UIFont.pretendardFontFamily(family: .Medium, size: 12).lineHeight
    return natural + 12 * 1.4
  }()

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(title)
        .pretendardFont(.headingMedium)
        .foregroundStyle(.white)
        .lineLimit(1)
        .truncationMode(.tail)
      Text(summary)
        .pretendardFont(.labelSmall, lineSpacingMultiple: 1.4)
        .foregroundStyle(.gray400)
        .lineLimit(2)
        .truncationMode(.tail)
        .frame(minHeight: Self.summaryMinHeight, alignment: .topLeading)
        .padding(.top, 4)
      metaRow()
        .padding(.top, 8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
  }

  @ViewBuilder
  private func metaRow() -> some View {
    HStack(spacing: 0) {
      // 기준 레이아웃 높이를 넘지 않게 태그는 한 줄로 둔다.
      Text(tagsText)
        .pretendardFont(.labelSmall)
        .foregroundStyle(.textMuted)
        .lineLimit(1)
      Spacer(minLength: 0)
      MetaLabelView(
        asset: .eye,
        text: viewCountText,
        iconSize: 16,
        spacing: 4,
        iconColor: .gray400,
        textColor: .textMuted
      )
    }
  }
}
