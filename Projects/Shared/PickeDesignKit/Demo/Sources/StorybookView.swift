//
//  StorybookView.swift
//  PickeDesignKitDemo
//
//  PickeDesignKit 토큰/컴포넌트 카탈로그. 섹션별로 컴포넌트 프리뷰를 추가해 확장한다.
//

import SwiftUI

import PickeDesignKit

struct StorybookView: View {
  var body: some View {
    NavigationStack {
      List {
        Section("Token") {
          Text("Color")
          Text("Typography")
          Text("Image")
        }
        Section("UI Components") {
          Text("Button")
          Text("Alert / Modal")
          Text("Toast / Floating")
          Text("Skeleton / Empty")
        }
      }
      .navigationTitle("Picke 스토리북")
    }
  }
}

#Preview {
  StorybookView()
}
