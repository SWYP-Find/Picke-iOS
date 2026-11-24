//
//  SecureStorageError.swift
//  PickeStorageInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public enum SecureStorageError: Error {
  case invalidData
  case unexpectedStatus(OSStatus)
}
