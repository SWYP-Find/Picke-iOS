//
//  HomeSkeletonView.swift
//  Home
//
//  Created by Picke on 5/16/26.
//

import SwiftUI

import PickeDesignKit

struct HomeSkeletonView: View {
  var body: some View {
    VStack(spacing: 32) {
      HomeHeroSkeletonView()
      HomeHotBattlesSkeletonView()
      HomeBestBattlesSkeletonView()
      HomeBestCommentsSkeletonView()
      HomeNewBattlesSkeletonView()
    }
    .padding(.bottom, 24)
    .allowsHitTesting(false)
  }
}

private struct HomeHeroSkeletonView: View {
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        SkeletonBlock(width: 82, height: 18, cornerRadius: .radiusDefault, color: .primary500.opacity(0.45))
        Spacer()
        SkeletonBlock(width: 36, height: 18, cornerRadius: 9, color: .neutral500.opacity(0.5))
      }
      .padding(16)

      ZStack {
        Rectangle()
          .fill(.neutral700.opacity(0.8))
        HStack(spacing: 24) {
          SkeletonBlock(width: 58, height: 14, color: .beige100.opacity(0.24))
          SkeletonBlock(width: 32, height: 32, cornerRadius: 16, color: .beige100.opacity(0.18))
          SkeletonBlock(width: 58, height: 14, color: .beige100.opacity(0.24))
        }
      }
      .frame(height: 167)

      VStack(alignment: .leading, spacing: 8) {
        SkeletonBlock(width: 210, height: 18, color: .beige100.opacity(0.22))
        SkeletonBlock(width: 260, height: 12, color: .neutral200.opacity(0.2))
        HStack {
          SkeletonBlock(width: 92, height: 12, color: .neutral200.opacity(0.18))
          Spacer()
          SkeletonBlock(width: 48, height: 12, color: .neutral200.opacity(0.18))
        }
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(height: 341)
    .background(.neutral800)
  }
}

private struct HomeHotBattlesSkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      SkeletonSectionHeader(width: 132)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          ForEach(0 ..< 2, id: \.self) { _ in
            VStack(alignment: .leading, spacing: 12) {
              SkeletonBlock(width: 196, height: 124)
              VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(width: 42, height: 20, color: .primary50)
                SkeletonBlock(width: 150, height: 16)
                SkeletonBlock(width: 104, height: 12)
              }
            }
            .padding(12)
            .frame(width: 220, alignment: .leading)
            .pickeCard(.beige50, border: .beige600)
          }
        }
        .padding(.horizontal, 16)
      }
    }
  }
}

private struct HomeBestBattlesSkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      SkeletonSectionHeader(width: 88)
      VStack(spacing: 0) {
        ForEach(0 ..< 3, id: \.self) { index in
          HStack(alignment: .top, spacing: 16) {
            SkeletonBlock(width: 16, height: 28, color: index == 0 ? .primary500.opacity(0.35) : .neutral100)
            VStack(alignment: .leading, spacing: 10) {
              SkeletonBlock(width: 76, height: 18, color: .primary50)
              SkeletonBlock(width: 214, height: 16)
              HStack(spacing: 8) {
                SkeletonBlock(width: 40, height: 12)
                SkeletonBlock(width: 44, height: 12)
                Spacer()
                SkeletonBlock(width: 96, height: 12)
              }
            }
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 16)

          PickeDivider(.cardBaseBorderDefault)
        }
      }
      .padding(.horizontal, 16)
    }
  }
}

private struct HomeBestCommentsSkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      SkeletonSectionHeader(width: 100)
      VStack(spacing: 0) {
        ForEach(0 ..< 3, id: \.self) { index in
          VStack(alignment: .leading, spacing: 8) {
            SkeletonBlock(width: 220, height: 12)
            HStack(spacing: 4) {
              SkeletonBlock(width: 16, height: 16)
              SkeletonBlock(width: 48, height: 16, color: .beige600)
              SkeletonBlock(width: 210, height: 12)
            }
          }
          .padding(16)
          if index < 2 {
            PickeDivider(.cardBaseBorderDefault)
          }
        }
      }
      .padding(.horizontal, 16)
    }
  }
}

private struct HomeNewBattlesSkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      SkeletonSectionHeader(width: 104)
      VStack(spacing: 12) {
        ForEach(0 ..< 3, id: \.self) { _ in
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              SkeletonBlock(width: 42, height: 20, color: .primary50)
              Spacer()
              SkeletonBlock(width: 92, height: 12)
            }
            SkeletonBlock(width: 240, height: 16)
            SkeletonBlock(width: 300, height: 12)
            HStack(spacing: 8) {
              SkeletonBattleOption()
              SkeletonBlock(width: 32, height: 32, cornerRadius: 16, color: .secondary100)
              SkeletonBattleOption()
            }
          }
          .padding(12)
          .pickeCard(.beige50, border: .beige600)
        }
      }
      .padding(.horizontal, 16)
    }
  }
}

private struct SkeletonBattleOption: View {
  var body: some View {
    HStack(spacing: 8) {
      SkeletonBlock(width: 28, height: 28, cornerRadius: 14, color: .beige500)
      VStack(alignment: .leading, spacing: 4) {
        SkeletonBlock(width: 46, height: 12)
        SkeletonBlock(width: 28, height: 10)
      }
      Spacer(minLength: 0)
    }
    .padding(8)
    .frame(maxWidth: .infinity)
    .pickeCard(.beige300, border: .beige600)
  }
}

private struct SkeletonSectionHeader: View {
  let width: CGFloat

  var body: some View {
    HStack {
      SkeletonBlock(width: width, height: 22, color: .neutral100)
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }
}

private struct SkeletonBlock: View {
  var width: CGFloat?
  var height: CGFloat
  var cornerRadius: CGFloat
  var color: Color

  init(
    width: CGFloat? = nil,
    height: CGFloat,
    cornerRadius: CGFloat = 2,
    color: Color = .beige600.opacity(0.55)
  ) {
    self.width = width
    self.height = height
    self.cornerRadius = cornerRadius
    self.color = color
  }

  var body: some View {
    SkeletonView(.round(cornerRadius: cornerRadius), base: color)
      .frame(width: width, height: height)
      .frame(maxWidth: width == nil ? .infinity : nil)
  }
}
