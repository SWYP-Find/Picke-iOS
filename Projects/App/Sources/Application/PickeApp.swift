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
        AppReducer()
          ._printChanges()
          ._printChanges(.actionLabels)
      }
      
      AppView(store: store)
    }
  }
}
