//
//  ContentView.swift
//  Picke
//
//  Created by Picke on 10/11/26.
//

import FeatureAssembly
import SwiftUI

public struct ContentView: View {
  public init() {}

  public var body: some View {
    Text("Hello, World!")
      .padding()
  }
}

#Preview {
  ContentView()
}

#Preview {
  AuthCoordinatorView(store: .init(initialState: AuthCoordinator.State(), reducer: {
    AuthCoordinator()
  }))
}
