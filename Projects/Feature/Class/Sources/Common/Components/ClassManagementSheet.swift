import ClassDomainInterface
import PickeDesignKit
import SwiftUI

struct ClassManagementSheet: View {
  let room: ClassRoom
  let onEdit: () -> Void
  let onDelete: () -> Void

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
        row("클래스 정보 수정", detail: "클래스명, 기본 정보를 수정해요.", icon: "pencil", action: onEdit)
        Rectangle().fill(.beige600).frame(height: 1)
        ShareLink(item: "[Picke] '\(room.name)' 클래스 참여 코드: \(room.joinCode)") {
          rowContent("참여 코드 공유", detail: "클래스 참여 코드를 공유해요.", icon: "arrow.up.right")
        }
        .buttonStyle(.plain)
        Rectangle().fill(.beige600).frame(height: 1)
        row("클래스 삭제", detail: "삭제 후에는 복구할 수 없어요.", icon: "trash", action: onDelete)
      }
    }
    .padding(.top, 12)
    .padding(.horizontal, 16)
    .padding(.bottom, 32)
  }

  private func row(_ title: String, detail: String, icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      rowContent(title, detail: detail, icon: icon)
    }
    .buttonStyle(.plain)
  }

  private func rowContent(_ title: String, detail: String, icon: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 18))
        .foregroundStyle(.primary500)
        .frame(width: 40, height: 40)
        .background(.primary50, in: Circle())
      VStack(alignment: .leading, spacing: 2) {
        Text(title).pretendardFont(.semiBold15).foregroundStyle(.gray800)
        Text(detail).pretendardFont(.medium13).foregroundStyle(.gray300)
      }
      Spacer()
      Image(systemName: "chevron.right")
        .font(.system(size: 12))
        .foregroundStyle(.gray800)
    }
    .frame(height: 72)
    .contentShape(Rectangle())
  }
}
