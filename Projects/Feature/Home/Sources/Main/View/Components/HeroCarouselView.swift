//
//  HeroCarouselView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import HomeDomainInterface
import PickeDesignKit

import PickeSharedUI

/// 최상단 Editor Pick 캐러셀. 좌우 스와이프 + 3초마다 자동 스크롤, 마지막 뒤엔 처음으로 wrap.
struct HeroCarouselView: View {
  let heroes: [HeroBattle]
  @Binding var currentIndex: Int
  var onTap: (HeroBattle) -> Void = { _ in }

  private static let autoScrollInterval: TimeInterval = 3
  private static let controlHeight: CGFloat = 51
  private static let thumbnailHeight: CGFloat = 220
  private static let subjectHeight: CGFloat = 88
  private let timer = Timer.publish(every: autoScrollInterval, on: .main, in: .common).autoconnect()

  var body: some View {
    TabView(selection: $currentIndex) {
      ForEach(Array(heroes.enumerated()), id: \.element.id) { index, hero in
        HeroCardView(
          hero: hero,
          position: index + 1,
          total: heroes.count,
          thumbnailHeight: Self.thumbnailHeight
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap(hero) }
        .tag(index)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .frame(height: Self.controlHeight + Self.thumbnailHeight + Self
      .subjectHeight) // .pen 합: control(53) + thumbnail(167) + subject(121)
    .background(.neutral800)
    .onReceive(timer) { _ in advance() }
  }

  private func advance() {
    guard !heroes.isEmpty else { return }
    withAnimation(.easeInOut(duration: 0.4)) {
      currentIndex = (currentIndex + 1) % heroes.count
    }
  }
}

/// 캐러셀 내부 단일 hero 카드.
struct HeroCardView: View {
  let hero: HeroBattle
  let position: Int
  let total: Int
  let thumbnailHeight: CGFloat

  var body: some View {
    VStack(spacing: 0) {
      controlRow()
      thumbnail()
      subject()
    }
    .background(.neutral800)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  @ViewBuilder
  private func controlRow() -> some View {
    HStack {
      Text(hero.badge)
        .pretendardFont(.semiBold11)
        .foregroundStyle(.secondary200)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .roundedBackground(.primary500)

      Spacer()

      HStack(spacing: 0) {
        Text("\(position)")
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.secondary50)
        Text("/\(total)")
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.secondary50)
          .opacity(0.4)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 2)
      .background(.neutral500, in: Capsule())
    }
    .padding(16)
  }

  @ViewBuilder
  private func thumbnail() -> some View {
    GeometryReader { proxy in
      ZStack {
        Rectangle()
          .fill(.neutral500.opacity(0.4))

        if let url = hero.thumbnailURL {
          PickeRemoteImage(url: url)
            .frame(
              width: proxy.size.width,
              height: proxy.size.height,
              alignment: .top
            )
            .clipped()
        }

        Color.black.opacity(0.4)

        HStack(spacing: 24) {
          Text(hero.optionA)
            .pretendardFont(.headingSmall)
            .foregroundStyle(.beige100)
          Image(asset: .vs)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 32)
          Text(hero.optionB)
            .pretendardFont(.headingSmall)
            .foregroundStyle(.beige100)
        }
        .opacity(0.85)
      }
    }
    .frame(height: thumbnailHeight)
    .clipped()
  }

  @ViewBuilder
  private func subject() -> some View {
    HStack(alignment: .bottom) {
      VStack(alignment: .leading, spacing: 0) {
        Text(hero.title)
          .pretendardFont(.headingMedium)
          .foregroundStyle(.beige100)
          .padding(.bottom, 4)
        Text(hero.summary)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.neutral200)
          .lineLimit(2)

        HStack(spacing: 4) {
          ForEach(hero.tags) { tag in
            Text("#\(tag.name)")
              .pretendardFont(.medium11)
              .foregroundStyle(.neutral200)
          }
        }
        .padding(.top, 6)
      }

      Spacer()

      MetaLabelView(systemImage: "eye", text: "\(hero.viewCount.formatted())")
    }
    .padding(.horizontal, 20)
    .padding(.top, 20)
    .padding(.bottom, 20)
  }
}
