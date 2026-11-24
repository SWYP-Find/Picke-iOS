//
//  StorybookView.swift
//  PickeDesignKitDemo
//
//  Created by Picke on 10/11/26.
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
