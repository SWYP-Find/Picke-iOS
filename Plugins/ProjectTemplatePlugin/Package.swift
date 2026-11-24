// swift-tools-version: 6.0
//
//  Package.swift
//  ProjectTemplatePlugin
//
//  Created by Picke on 10/11/26.
//


import PackageDescription

let package = Package(
    name: "MyPlugin",
    products: [
        .executable(name: "tuist-my-cli", targets: ["tuist-my-cli"]),
    ],
    targets: [
        .executableTarget(
            name: "tuist-my-cli"
        ),
    ]
)
