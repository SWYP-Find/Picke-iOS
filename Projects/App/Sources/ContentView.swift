import SwiftUI
import Presentation
import Auth
import Web

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


