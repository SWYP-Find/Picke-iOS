//
//  ChatRoomSkeletonView.swift
//  Chat
//
//  Created by Picke on 10/11/26.
//

import PickeDesignKit
import SwiftUI

/// Android `PickeChatSkeleton` — 상단 바·플레이어 바는 그대로 두고 대화 자리만 3줄
/// (왼쪽 260×96, 오른쪽 220×64, 왼쪽 260×96), 패딩 16, 간격 16.
struct ChatRoomSkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      SkeletonView.line(width: 260, height: 96)
      SkeletonView.line(width: 220, height: 64)
        .frame(maxWidth: .infinity, alignment: .trailing)
      SkeletonView.line(width: 260, height: 96)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .allowsHitTesting(false)
  }
}
