//
//  ClassReportFeedbackViewState.swift
//  Class
//
//  Created by Picke on 10/12/26.
//

import ClassDomainInterface

public enum ClassReportFeedbackViewState: Equatable {
  case unavailable, loading, pending, ready(ClassAIPersonalFeedback), retryableFailure, failure
}
