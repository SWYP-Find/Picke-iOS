//
//  PickeAvatar.swift
//  PickeDesignKit
//

import SwiftUI

public extension View {
  /// 원형 아바타 외형(베이지 배경·테두리·원형 클리핑)만 입힌다.
  /// 이미지 로딩 라이브러리는 디자인킷이 알 필요가 없으므로 내용은 호출부가 넣는다.
  func pickeAvatar(size: CGFloat) -> some View {
    frame(width: size, height: size)
      .background(.avatarBackround, in: Circle())
      .clipShape(Circle())
      .overlay(Circle().stroke(.avatarBackround, lineWidth: 1))
  }

  /// 이미지가 없을 때 쓰는 이니셜 텍스트 스타일.
  func pickeAvatarFallback(size: CGFloat) -> some View {
    pretendardFont(size <= 36 ? .semiBold13 : .headingSmall)
      .foregroundStyle(.primary500)
  }
}
