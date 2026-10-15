//
//  ClassDeadlinePicker.swift
//  Class
//
//  Created by Picke on 10/15/26.
//

import PickeCoreUtility
import SwiftUI

struct ClassDeadlinePicker: View {
  @Binding var selection: Date
  let minimumDate: Date

  var body: some View {
    DatePicker(
      "참여 마감일",
      selection: $selection,
      in: minimumDate...,
      displayedComponents: [.date, .hourAndMinute]
    )
    .datePickerStyle(.wheel)
    .labelsHidden()
    .frame(maxWidth: .infinity)
    .frame(height: 216)
    .environment(\.timeZone, AppDateFormat.timeZone)
    .environment(\.calendar, AppDateFormat.calendar)
  }
}
