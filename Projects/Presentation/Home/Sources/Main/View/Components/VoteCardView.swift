//
//  VoteCardView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import Entity
import HomeDomainInterface
import PickeDesignKit

/// "오늘의 Pické — 투표" 카드. 옵션 탭 시 result 모드로 전환되어
/// 빈칸에 선택지 텍스트가 채워지고 옵션 박스 아래에 percentage bar 들이 표시된다.
struct VoteCardView: View {
  let question: VoteQuestion

  @State private var selectedIndex: Int?
  @State private var animatedFill: Bool = false

  private var isResultMode: Bool { selectedIndex != nil }

  private var selectedLabel: String? {
    guard let idx = selectedIndex else { return nil }
    return question.options[safe: idx]?.title
  }

  private let columns = [
    GridItem(.flexible(), spacing: 8),
    GridItem(.flexible(), spacing: 8),
  ]

  /// API 가 결과 비율을 내려주기 전까지 사용하는 임시 mock 비율.
  private static let mockPercentages: [Int] = [45, 25, 20, 10]

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      header()
      heading()
      grid()
      if isResultMode {
        resultBars()
      }
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 16)
    .pickeCard(.beige50, border: .beige600)
  }

  @ViewBuilder
  private func header() -> some View {
    HStack {
      Text("투표")
        .pretendardFont(.headingSmall)
        .foregroundStyle(.primary500)
        .frame(width: 35, height: 21)
        .roundedBackground(.beige600)

      Spacer()

      Text("\(question.participantCount.formatted())명 참여")
        .pretendardFont(.medium11)
        .foregroundStyle(.neutral300)
    }
  }

  @ViewBuilder
  private func heading() -> some View {
    VStack(spacing: 6) {
      HStack(spacing: 4) {
        Text(question.titlePrefix)
          .pretendardFont(.semiBold15)
          .foregroundStyle(.neutral500)

        answerSlot()

        Text(question.titleSuffix)
          .pretendardFont(.semiBold15)
          .foregroundStyle(.neutral500)
      }

      Text(question.summary)
        .pretendardFont(.labelSmall)
        .foregroundStyle(.neutral300)
    }
    .frame(maxWidth: .infinity)
  }

  /// 빈칸: 선택 전엔 빈 placeholder, 선택 후엔 선택된 옵션 텍스트 표시.
  /// 선택된 라벨 길이에 맞춰 가변 폭 — 글자가 잘리지 않도록 horizontal padding 만 두고
  /// 최소 폭을 placeholder(52pt) 와 동일하게 유지한다.
  @ViewBuilder
  private func answerSlot() -> some View {
    if let label = selectedLabel {
      Text(label)
        .pretendardFont(.semiBold15)
        .foregroundStyle(.primary500)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 8)
        .frame(minWidth: 52, minHeight: 24)
        .pickeCard(.beige200, border: .primary500)
    } else {
      RoundedRectangle(cornerRadius: .radiusDefault)
        .fill(.beige200)
        .frame(width: 52, height: 24)
        .roundedBorder(.beige600)
    }
  }

  @ViewBuilder
  private func grid() -> some View {
    LazyVGrid(columns: columns, spacing: 7) {
      ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
        optionButton(index: idx, label: option.title)
      }
    }
  }

  @ViewBuilder
  private func optionButton(
    index: Int,
    label: String
  ) -> some View {
    let isSelected = selectedIndex == index

    Button {
      withAnimation(.easeInOut(duration: 0.2)) {
        selectedIndex = isSelected ? nil : index
      }
    } label: {
      Text(label)
        .pretendardFont(.semiBold13)
        .foregroundStyle(.neutral900)
        .frame(maxWidth: .infinity, minHeight: 44)
        .roundedBackground(.beige400)
        .overlay(
          RoundedRectangle(cornerRadius: .radiusDefault)
            .stroke(isSelected ? .primary500 : .beige600, lineWidth: isSelected ? 1.5 : 1)
        )
    }
    .buttonStyle(.plain)
  }

  /// Result mode 옵션 박스 아래 별도 영역 — 4 row (옵션명 + bar + percentage).
  /// .pen `Radar Wrap` 디자인을 2-column 으로 재배치.
  @ViewBuilder
  private func resultBars() -> some View {
    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
        resultBarRow(
          label: option.title,
          percentage: Self.mockPercentages[safe: idx] ?? 0
        )
      }
    }
    .padding(.top, 4)
    .onAppear {
      animatedFill = false
      withAnimation(.easeOut(duration: 0.6)) {
        animatedFill = true
      }
    }
    .onDisappear {
      animatedFill = false
    }
  }

  @ViewBuilder
  private func resultBarRow(
    label: String,
    percentage: Int
  ) -> some View {
    HStack(spacing: 6) {
      Text(label)
        .pretendardFont(.medium10)
        .foregroundStyle(.neutral400)
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 1)
          .fill(.secondary100)
          .frame(width: 48, height: 4)
        RoundedRectangle(cornerRadius: 1)
          .fill(.secondary500)
          .frame(width: animatedFill ? 48 * CGFloat(percentage) / 100 : 0, height: 4)
      }
      Spacer(minLength: 0)
      Text("\(percentage)%")
        .pretendardFont(.bold11)
        .foregroundStyle(.neutral500)
    }
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
