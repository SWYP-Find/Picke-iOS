//
//  BattleVersusBadge.swift
//  PickeSharedUI
//
//  Created by Picke on 11/10/26.
//

import PickeDesignKit
import SwiftUI

/// Android 배틀 카드 VS — 40 영역 안 28 원(secondary200) + 10 SemiBold "VS".
public struct BattleVersusBadge: View {
  public init() {}

  public var body: some View {
    Text("VS")
      .pretendardFont(.labelXSmall)
      .foregroundStyle(.textDefault)
      .frame(width: 28, height: 28)
      .background(.secondary200, in: Circle())
      .frame(width: 40, height: 40)
  }
}
