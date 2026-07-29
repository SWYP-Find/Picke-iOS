//
//  RecapSkeletonView.swift
//  Profile
//

import SwiftUI

import PickeDesignKit

struct RecapSkeletonView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // 내 카드
        cardBox {
          VStack(spacing: 16) {
            block(width: 100, height: 13)
            block(width: 120, height: 24)
            SkeletonBlock(cornerRadius: 34, tone: .light).frame(width: 68, height: 68)
            block(width: nil, maxWidth: true, height: 40)
            HStack(spacing: 8) {
              ForEach(0 ..< 3, id: \.self) { _ in block(width: 56, height: 20) }
            }
          }
          .padding(20)
        }

        // 성향 분석
        VStack(spacing: 12) {
          block(width: 70, height: 13)
          cardBox {
            VStack(spacing: 12) {
              SkeletonBlock(cornerRadius: 8, tone: .light).frame(height: 160)
              LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(0 ..< 6, id: \.self) { _ in block(width: nil, maxWidth: true, height: 28) }
              }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
          }
        }

        // 취향 리포트
        VStack(spacing: 12) {
          block(width: 90, height: 13)
          cardBox {
            VStack(spacing: 16) {
              HStack(spacing: 24) {
                ForEach(0 ..< 3, id: \.self) { _ in
                  VStack(spacing: 6) { block(width: 30, height: 16); block(width: 44, height: 10) }
                    .frame(maxWidth: .infinity)
                }
              }
              ForEach(0 ..< 4, id: \.self) { _ in block(width: nil, maxWidth: true, height: 16) }
            }
            .padding(16)
          }
        }

        // 궁합
        VStack(spacing: 12) {
          block(width: 60, height: 13)
          HStack(spacing: 8) {
            ForEach(0 ..< 2, id: \.self) { _ in
              cardBox {
                VStack(spacing: 8) {
                  block(width: 40, height: 12)
                  SkeletonBlock(cornerRadius: 20, tone: .light).frame(width: 40, height: 40)
                  block(width: 60, height: 13)
                  block(width: nil, maxWidth: true, height: 22)
                }
                .padding(16)
              }
            }
          }
        }

        SkeletonBlock(cornerRadius: .radiusDefault, tone: .light).frame(height: 52)
      }
      .padding(.top, 20)
      .padding(.horizontal, 16)
      .padding(.bottom, 32)
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private func cardBox(@ViewBuilder _ content: () -> some View) -> some View {
    content()
      .frame(maxWidth: .infinity)
      .roundedBackground(.beige50)
      .overlay(
        RoundedRectangle(cornerRadius: .radiusDefault)
          .stroke(.beige600, lineWidth: 1)
      )
  }

  @ViewBuilder
  private func block(width: CGFloat?, maxWidth: Bool = false, height: CGFloat) -> some View {
    SkeletonBlock(cornerRadius: 4, tone: .light)
      .frame(width: width)
      .frame(maxWidth: maxWidth ? .infinity : nil)
      .frame(height: height)
  }
}
