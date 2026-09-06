//
//  FileHeaderTemplate+.swift
//  ProjectDescriptionHelpers
//
//  Xcode 파일 헤더(IDETemplateMacros). 새 파일 생성 시 자동 삽입된다.
//  ___FILENAME___/___PACKAGENAME___/___DATE___ 는 Xcode 가 채운다.
//  작성자는 기여자와 무관하게 프로젝트명으로 고정한다.
//

import ProjectDescription

public extension FileHeaderTemplate {
  /// 프로젝트 공통 파일 헤더.
  static var `default`: FileHeaderTemplate {
    """
    //
    //  ___FILENAME___
    //  ___PACKAGENAME___
    //
    //  Created by Picke on ___DATE___.
    //
    """
  }
}
