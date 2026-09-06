import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "ServiceAssembly"),
  bundleId: .appBundleID(name: ".ServiceAssembly"),
  product: .staticFramework,
  settings: .settings(),
  // SDK 를 링크하는 서비스 구현을 한곳에서 묶는 조립 경계.
  dependencies: [
    .coreAssembly,
    .Service(.Ad),
    .Service(.Analytics),
    .Service(.AudioPlayer),
    .Service(.Device),
  ],
  sources: ["Sources/**"],
  hasTests: false
)
