//
//  ClassOwnerDashboardInsightViewState.swift
//  Class
//
//  Created by Picke on 10/12/26.
//

public enum ClassOwnerDashboardInsightViewState: Equatable {
  case unavailable, loading, pending, ready(String), retryableFailure, failure
}
