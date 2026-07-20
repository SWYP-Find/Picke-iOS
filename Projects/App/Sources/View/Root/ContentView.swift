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
  AppAuthCoordinatorView(store: .init(initialState: AppAuthCoordinator.State(), reducer: {
    AppAuthCoordinator()
  }))
}

