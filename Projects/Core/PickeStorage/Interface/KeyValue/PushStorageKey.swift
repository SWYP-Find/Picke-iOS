//
//  PushStorageKey.swift
//  PickeStorageInterface
//
//  Created by Picke on 10/11/26.
//

public enum PushStorageKey {
  public static let deviceToken = KeyValueStorageKey<String>("PickeDeviceToken")
  public static let pendingDeeplink = KeyValueStorageKey<String>("PickePendingDeeplink")
}
