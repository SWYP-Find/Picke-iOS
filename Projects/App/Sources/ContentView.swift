import SwiftUI
import Presentation

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
