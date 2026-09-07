import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "APIEndpoint"),
  bundleId: .appBundleID(name: ".APIEndpoint"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .service(.api),
    // Auth 엔드포인트가 SocialType 을 경로에 쓴다.
    .domain(.auth, .interface),
    .core(.network, .interface),
  ],
  sources: ["Sources/**"],
  hasTests: true
)
