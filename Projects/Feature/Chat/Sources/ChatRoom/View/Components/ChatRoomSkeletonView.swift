//
//  ChatRoomSkeletonView.swift
//  Home
//

import SwiftUI

import PickeDesignKit

struct ChatRoomSkeletonView: View {
  var body: some View {
    VStack(spacing: 0) {
      navigationBarSkeleton()
      messageListSkeleton()
      playerBarSkeleton()
    }
    .screenBackground(.beige50)
  }
}

// MARK: - Navigation

private extension ChatRoomSkeletonView {
  @ViewBuilder
  func navigationBarSkeleton() -> some View {
    HStack(spacing: 12) {
      SkeletonView(.round(cornerRadius: 6))
        .frame(width: 20, height: 24)
      Spacer()
      SkeletonView(.round(cornerRadius: 6))
        .frame(width: 24, height: 24)
    }
    .padding(.horizontal, 20)
    .frame(height: 60)
    .bottomDivider(.beige600)
  }
}

// MARK: - Messages

private extension ChatRoomSkeletonView {
  @ViewBuilder
  func messageListSkeleton() -> some View {
    VStack(alignment: .leading, spacing: 24) {
      leftGroup()
      rightGroup()
      leftGroup()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 20)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  @ViewBuilder
  func leftGroup() -> some View {
    HStack(alignment: .top, spacing: 8) {
      SkeletonView(.round(cornerRadius: 20))
        .frame(width: 40, height: 40)
      VStack(alignment: .leading, spacing: 8) {
        SkeletonView(.round(cornerRadius: 6))
          .frame(width: 37, height: 20)
        SkeletonView(.round(cornerRadius: 6))
          .frame(width: 256, height: 54)
        SkeletonView(.round(cornerRadius: 6))
          .frame(width: 256, height: 36)
        SkeletonView(.round(cornerRadius: 6))
          .frame(width: 256, height: 36)
      }
      Spacer(minLength: 0)
    }
  }

  @ViewBuilder
  func rightGroup() -> some View {
    HStack(alignment: .top, spacing: 8) {
      Spacer(minLength: 0)
      VStack(alignment: .trailing, spacing: 8) {
        SkeletonView(.round(cornerRadius: 6))
          .frame(width: 49, height: 20)
        SkeletonView(.round(cornerRadius: 6))
          .frame(width: 256, height: 54)
        SkeletonView(.round(cornerRadius: 6))
          .frame(width: 256, height: 36)
        SkeletonView(.round(cornerRadius: 6))
          .frame(width: 256, height: 54)
      }
      SkeletonView(.round(cornerRadius: 20))
        .frame(width: 40, height: 40)
    }
  }
}

// MARK: - Player bar

private extension ChatRoomSkeletonView {
  @ViewBuilder
  func playerBarSkeleton() -> some View {
    VStack(spacing: 16) {
      SkeletonView(.round(cornerRadius: 6))
        .frame(height: 18)

      HStack(alignment: .top, spacing: 32) {
        SkeletonView(.round(cornerRadius: 6))
          .frame(width: 24, height: 55)
        SkeletonView(.round(cornerRadius: 6))
          .frame(width: 55, height: 55)
        SkeletonView(.round(cornerRadius: 6))
          .frame(width: 24, height: 55)
      }
    }
    .padding(.horizontal, 24)
    .padding(.top, 16)
    .padding(.bottom, 8)
    .background(.beige50)
    .topDivider(.beige600)
  }
}
