//
//  ClassManagementSheet.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import PickeDesignKit
import SwiftUI

struct ClassManagementSheet: View {
  let room: ClassRoom
  let onEdit: () -> Void
  let onShare: () -> Void
  let onDelete: () -> Void
  let onLeave: (() -> Void)?

  init(
    room: ClassRoom,
    onEdit: @escaping () -> Void,
    onShare: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    onLeave: (() -> Void)? = nil
  ) {
    self.room = room
    self.onEdit = onEdit
    self.onShare = onShare
    self.onDelete = onDelete
    self.onLeave = onLeave
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Capsule()
        .fill(.gray50)
        .frame(width: 40, height: 4)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)

      Text("클래스 관리")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)

      VStack(spacing: 0) {
        if room.role == .owner {
          row("클래스 정보 수정", detail: "클래스명, 기본 정보를 수정해요.", icon: .edit, action: onEdit)
          Rectangle().fill(.beige600).frame(height: 1)
        }
        // Android ClassManageSheet: 참여 코드 공유는 ClassShare 화면으로 이동한다.
        row("참여 코드 공유", detail: "클래스 참여 코드를 공유해요.", icon: .arrowUpRight, action: onShare)
        Rectangle().fill(.beige600).frame(height: 1)
        if room.role == .owner {
          row("클래스 삭제", detail: "삭제 후에는 복구할 수 없어요.", icon: .trash, action: onDelete)
        } else if let onLeave {
          row("클래스 나가기", detail: "나간 후에는 데이터를 복구할 수 없어요.", icon: .logOut, action: onLeave)
        }
      }
    }
    .padding(.top, 12)
    .padding(.horizontal, 16)
    .padding(.bottom, 32)
  }

  private func row(_ title: String, detail: String, icon: ImageAsset, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      rowContent(title, detail: detail, icon: icon)
    }
    .buttonStyle(.plain)
  }

  private func rowContent(_ title: String, detail: String, icon: ImageAsset) -> some View {
    HStack(spacing: 12) {
      // Android ClassManageSheet: 24pt 에셋 아이콘(iconPrimaryDefault)을 40pt 원 안에 둔다.
      Image(asset: icon)
        .resizable()
        .renderingMode(.template)
        .scaledToFit()
        .frame(width: 24, height: 24)
        .foregroundStyle(.iconPrimaryDefault)
        .frame(width: 40, height: 40)
        .background(.surfacePrimarySubtle, in: Circle())
      VStack(alignment: .leading, spacing: 2) {
        Text(title).pretendardFont(.semiBold15).foregroundStyle(.gray800)
        Text(detail).pretendardFont(.medium13).foregroundStyle(.gray300)
      }
      Spacer()
      Image(asset: .arrowRight)
        .resizable()
        .renderingMode(.template)
        .scaledToFit()
        .frame(width: 16, height: 16)
        .foregroundStyle(.iconGrayDefault)
    }
    .frame(height: 72)
    .contentShape(Rectangle())
  }
}
