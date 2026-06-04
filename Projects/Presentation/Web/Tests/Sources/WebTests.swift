//
//  WebTests.swift
//  Presentation.WebTests
//
//  Created by Roy on 2026-06-04.
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
        // Add your test logic here.
        let result = true
        #expect(result == true)
    }

}

