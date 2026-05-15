//
//  HeroCarouselView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import DesignSystem
import Entity

import Kingfisher

/// 최상단 Editor Pick 캐러셀. 좌우 스와이프 + 3초마다 자동 스크롤, 마지막 뒤엔 처음으로 wrap.
struct HeroCarouselView: View {
  let heroes: [HeroBattle]
  @Binding var currentIndex: Int

  private static let autoScrollInterval: TimeInterval = 3
  private let timer = Timer.publish(every: autoScrollInterval, on: .main, in: .common).autoconnect()

  var body: some View {
    TabView(selection: $currentIndex) {
      ForEach(Array(heroes.enumerated()), id: \.element.id) { index, hero in
        HeroCardView(
          hero: hero,
          position: index + 1,
          total: heroes.count
        )
        .tag(index)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .frame(height: 341) // .pen 합: control(53) + thumbnail(167) + subject(121)
    .background(Color.neutral800)
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

  var body: some View {
    VStack(spacing: 0) {
      controlRow
      thumbnail
      subject
    }
    .background(Color.neutral800)
    .frame(maxWidth: .infinity)
  }

  private var controlRow: some View {
    HStack {
      Text(hero.badge)
        .pretendardFont(family: .SemiBold, size: 11)
        .foregroundStyle(.secondary200)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(.primary500, in: RoundedRectangle(cornerRadius: 2))

      Spacer()

      HStack(spacing: 0) {
        Text("\(position)")
          .pretendardFont(family: .SemiBold, size: 10)
          .foregroundStyle(.secondary50)
        Text("/\(total)")
          .pretendardFont(family: .SemiBold, size: 10)
          .foregroundStyle(.secondary50)
          .opacity(0.4)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 2)
      .background(.neutral500, in: Capsule())
    }
    .padding(16)
  }

  private var thumbnail: some View {
    ZStack {
      if let url = hero.thumbnailURL {
        KFImage(url)
          .resizable()
          .scaledToFill()
          .frame(height: 167)
          .clipped()
        Color.black.opacity(0.4) // .pen 의 "#00000066" 오버레이
      } else {
        Color.neutral500.opacity(0.4)
      }

      HStack(spacing: 24) {
        Text(hero.optionA)
          .pretendardFont(family: .SemiBold, size: 14)
          .foregroundStyle(.beige100)
        ZStack {
          Circle()
            .stroke(.secondary50.opacity(0.2), lineWidth: 2)
            .frame(width: 32, height: 32)
          Text("VS")
            .pretendardFont(family: .SemiBold, size: 11)
            .foregroundStyle(.secondary50)
        }
        Text(hero.optionB)
          .pretendardFont(family: .SemiBold, size: 14)
          .foregroundStyle(.beige100)
      }
      .opacity(0.85)
    }
    .frame(height: 167)
    .clipped()
  }

  private var subject: some View {
    HStack(alignment: .bottom) {
      VStack(alignment: .leading, spacing: 4) {
        Text(hero.title)
          .pretendardFont(family: .SemiBold, size: 16)
          .foregroundStyle(.beige100)
        Text(hero.summary)
          .pretendardFont(family: .Medium, size: 12)
          .foregroundStyle(.neutral200)
          .lineLimit(2)
        HStack(spacing: 4) {
          ForEach(hero.tags) { tag in
            Text(tag.name)
              .pretendardFont(family: .Medium, size: 11)
              .foregroundStyle(.neutral200)
          }
        }
        .padding(.top, 2)
      }
      Spacer()
      MetaLabelView(systemImage: "eye", text: "\(hero.viewCount)")
    }
    .padding(20)
  }
}
