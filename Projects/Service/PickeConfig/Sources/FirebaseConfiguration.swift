//
//  FirebaseConfiguration.swift
//  PickeAnalytics
//

import Firebase

/// Firebase 기동. 앱은 이 타입만 호출하고 Firebase 심볼은 여기 밖으로 새어 나가지 않는다.
public enum FirebaseConfiguration {
  public static func configure() {
    FirebaseApp.configure()
  }
}
