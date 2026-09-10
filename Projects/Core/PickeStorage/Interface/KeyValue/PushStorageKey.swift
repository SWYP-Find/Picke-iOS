//
//  PushStorageKey.swift
//  PickeStorageInterface
//

public enum PushStorageKey {
  public static let deviceToken = KeyValueStorageKey<String>("PickeDeviceToken")
  public static let pendingDeeplink = KeyValueStorageKey<String>("PickePendingDeeplink")
}
