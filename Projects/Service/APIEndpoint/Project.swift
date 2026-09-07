import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "APIEndpoint",
  bundleId: .appBundleID(name: ".APIEndpoint"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    // 엔드포인트가 HTTPMethod·HTTPHeaders 를 직접 쓴다. PickeNetwork 가 더는 재노출하지 않는다.
    .SPM.alamofire,
    .service(.api),
    // Auth 엔드포인트가 SocialType 을 경로에 쓴다.
    .domain(.auth, .interface),
    .core(.network, .interface),
  ],
  hasTests: true
)