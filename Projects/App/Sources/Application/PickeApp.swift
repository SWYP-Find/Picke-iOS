import SwiftUI
import ComposableArchitecture

@main
struct PickeApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  init() {
    
  }
  
  var body: some Scene {
    WindowGroup {
      let store = Store(initialState: AppReducer.State()) {
#if DEBUG
        AppReducer()
          ._printChanges()
          ._printChanges(.actionLabels)
#else
        AppReducer()
#endif
      }
      
      AppView(store: store)
    }
  }
}
