//
//  ClassDeadlinePicker.swift
//  Class
//
//  Created by Picke on 10/15/26.
//

import PickeCoreUtility
import PickeDesignKit
import SwiftUI

struct ClassDeadlinePicker: View {
  @Binding var selection: Date
  let minimumDate: Date
  @Binding var isAdjusting: Bool
  @State private var adjustingColumns: Set<String> = []
  @State private var wheel: ClassDeadlineWheel

  init(
    selection: Binding<Date>,
    minimumDate: Date,
    isAdjusting: Binding<Bool>
  ) {
    _selection = selection
    self.minimumDate = minimumDate
    _isAdjusting = isAdjusting
    _wheel = State(initialValue: ClassDeadlineWheel(
      selection: selection.wrappedValue,
      minimumDate: minimumDate
    ))
  }

  var body: some View {
    Group {
      if #available(iOS 18, *) {
        ZStack {
          selectionBackground
          columns()
        }
      } else {
        nativePicker
      }
    }
    .frame(height: 174)
    .onAppear { resetEditing() }
    .onDisappear { resetEditing() }
  }
}

private extension ClassDeadlinePicker {
  var nativePicker: some View {
    DatePicker(
      "마감일",
      selection: $selection,
      in: minimumDate ... max(minimumDate, wheel.maximumDate),
      displayedComponents: [.date, .hourAndMinute]
    )
    .datePickerStyle(.wheel)
    .labelsHidden()
    .environment(\.calendar, AppDateFormat.calendar)
    .environment(\.timeZone, AppDateFormat.timeZone)
    .environment(\.locale, Locale(identifier: "ko_KR"))
    .frame(height: 174)
    .clipped()
    .contentShape(Rectangle())
  }

  var selectionBackground: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color(white: 245.0 / 255.0))
      .frame(height: 32)
  }

  @available(iOS 18, *)
  @ViewBuilder
  func columns() -> some View {
    HStack(spacing: 8) {
      ClassDeadlineWheelColumn(
        values: wheel.days(including: selection),
        selection: Binding(
          get: { ClassDeadlineWheel.dayID(selection) },
          set: { selection = wheel.selecting(day: $0, from: selection, minimumDate: minimumDate) }
        ),
        label: "날짜",
        text: { ClassDeadlineWheel.date(for: $0).formatted(.pickerDay) },
        onEditingChanged: { updateEditing("date", active: $0) }
      )
      .frame(width: 140)
      ClassDeadlineWheelColumn(
        values: -48 ... 71,
        selection: Binding(
          get: { ClassDeadlineWheel.hour(selection) },
          set: { selection = wheel.selecting(hour: $0, from: selection, minimumDate: minimumDate) }
        ),
        label: "시",
        text: { String($0) },
        cycleLength: 24,
        onEditingChanged: { updateEditing("hour", active: $0) }
      )
      .frame(width: 30)
      ClassDeadlineWheelColumn(
        values: -120 ... 179,
        selection: Binding(
          get: { ClassDeadlineWheel.minute(selection) },
          set: { selection = wheel.selecting(minute: $0, from: selection, minimumDate: minimumDate) }
        ),
        label: "분",
        text: { String(format: "%02d", $0) },
        cycleLength: 60,
        onEditingChanged: { updateEditing("minute", active: $0) }
      )
      .frame(width: 30)
    }
  }

  func updateEditing(
    _ column: String,
    active: Bool
  ) {
    if active { adjustingColumns.insert(column) } else { adjustingColumns.remove(column) }
    isAdjusting = !adjustingColumns.isEmpty
  }

  func resetEditing() {
    adjustingColumns.removeAll()
    isAdjusting = false
  }
}
