//
//  PickeTests.swift
//  PickeTests
//
//  Created by Picke on 10/11/26.
//

@testable import Picke
import XCTest

final class PickeTests: XCTestCase {
  override func setUpWithError() throws {}

  override func tearDownWithError() throws {
    // Put teardown code here.
  }

  func testExample() {
    // This is an example of a functional test case.
  }

  func testHostedUnitTestsUseIsolatedAppStartup() {
    XCTAssertTrue(PickeApp.isRunningHostedUnitTests)
  }

  func testPerformanceExample() {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
}
