//
//  SecureStorageError.swift
//  PickeStorageInterface
//

import Foundation

public enum SecureStorageError: Error {
  case invalidData
  case unexpectedStatus(OSStatus)
}
