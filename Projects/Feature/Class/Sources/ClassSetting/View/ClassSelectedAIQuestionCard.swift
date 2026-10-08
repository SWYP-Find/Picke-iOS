//
//  ClassSelectedAIQuestionCard.swift
//  Class
//

import SwiftUI

struct ClassSelectedAIQuestionCard: View {
  let question: ClassAIQuestion

  var body: some View {
    ClassAIQuestionCard(
      question: question,
      isSelected: false,
      showsSelection: false
    )
  }
}
