import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .module(name: "PickeDesignKit"),
  bundleId: .appBundleID(name: ".PickeDesignKit"),
  // 동적 프레임워크: 정적이면 리소스 번들 접근자(TuistBundle+PickeDesignKit)의
  // BundleFinder 가 앱 메인 바이너리로 병합되는데 번들은 Shared.framework 안에만
  // 복사되어 Bundle(for:) 이 앱 루트로 해석 → "unable to find bundle" 크래시가 났다.
  // 동적이면 BundleFinder·번들이 PickeDesignKit.framework 에만 존재해 정확히 찾는다.
  // TCA 중복 클래스는 Tuist/Package.swift 에서 ComposableArchitecture/Dependencies/
  // Perception/Sharing/IssueReporting 를 .framework(동적)로 전환해 단일 사본으로 해소한다.
  product: .framework,
  settings: .settings(),
  dependencies: [
    .core(.coreUI),
    .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"],
  resources: ["Resources/**"],
  hasTests: true,
  demoDisplayName: "Picke 스토리북"
)
