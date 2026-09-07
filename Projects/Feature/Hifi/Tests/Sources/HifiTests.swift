//
//  HifiTests.swift
//  Feature.HifiTests
//
//  Created by Roy on 2026-06-04.
//

import Testing
@testable import Hifi

struct HifiTests {

    @Test
    func hifiExample() {
        // This is an example of a test case.
        #expect(true)
    }

    @Test
    func hifiLogicTest() {
        let result = true
        #expect(result == true)
    }

}

