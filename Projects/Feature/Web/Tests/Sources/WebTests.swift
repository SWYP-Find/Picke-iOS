//
//  WebTests.swift
//  WebTests
//
//  Created by Picke on 2026-06-04.
//

import Testing
@testable import Web

struct WebTests {

    @Test
    func webExample() {
        // This is an example of a test case.
        #expect(true)
    }

    @Test
    func webLogicTest() {
        let result = true
        #expect(result == true)
    }

}

