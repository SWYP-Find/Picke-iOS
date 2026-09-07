//
//  WorkSpace.swift
//  Manifests
//
//  Created by 서원지 on 6/7/24.
//

import ProjectDescription
import ProjectTemplatePlugin

// 이름은 Project.Environment.appName 하나로만 정한다.
// PROJECT_NAME 환경변수 폴백은 이미 그 안에 있어서 여기서 또 분기하면 로직만 두 벌이 된다.
let workspace = Workspace(
  name: Project.Environment.appName,
  projects: [
    "Projects/**"
  ]
)
