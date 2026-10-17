//
//  ClassOwnerDashboardFeedbackViewState.swift
//  Class
//
//  Created by Picke on 10/12/26.
//

import ClassDomainInterface

public enum ClassOwnerDashboardFeedbackViewState: Equatable {
  case unavailable, loading, ready(ClassAIPersonalFeedback), retryableFailure, failure
}
