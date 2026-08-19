import ComposableArchitecture
import SentrySwiftUI
import SwiftUI

@main
struct PickeApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  init() {}

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
      } withDependencies: {
        AppDependencyFactory.configure(&$0)
      }

      SentryTracedView("AppRoot") {
        AppView(store: store)
      }
      .onOpenURL { url in
        // picke://... 커스텀 스킴 / 유니버설 링크 → 딥링크 라우팅.
        PushDeeplinkBridge.handleURL(url)
      }
    }
  }
}
