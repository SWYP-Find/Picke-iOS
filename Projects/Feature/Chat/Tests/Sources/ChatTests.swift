//
//  ChatTests.swift
//  Feature.ChatTests
//
//  Created by Roy on 2026-05-21.
//

@testable import Chat
import Testing

struct ChatTests {
  @Test
  func chatExample() {
    // This is an example of a test case.
    #expect(true)
  }

  @Test
  func chatLogicTest() {
    let result = true
    #expect(result == true)
  }
}
