//
//  AdBannerSkeletonView.swift
//  AdService
//

import SwiftUI

struct AdBannerSkeletonView: View {
  /// 배너와 동일한 고정 크기(폭 320) — 로드 후 실제 배너로 바뀔 때 위치가 어긋나지 않게 한다.
  let size: CGSize

  @State private var animating = false

  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color(white: 0.91))
      .frame(width: size.width, height: size.height)
      .overlay {
        GeometryReader { geometry in
          LinearGradient(
            colors: [.clear, Color.white.opacity(0.65), .clear],
            startPoint: .leading,
            endPoint: .trailing
          )
          .frame(width: geometry.size.width * 0.6)
          // 좌 → 우로 흐르는 빛 반사. Date/Random 없이 offset 만 무한 반복한다.
          .offset(x: animating ? geometry.size.width : -geometry.size.width * 0.6)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .onAppear {
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
          animating = true
        }
      }
  }
}
