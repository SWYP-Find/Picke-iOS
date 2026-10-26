//
//  ClassTicketView.swift
//  Class
//

import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassTicketFeature.self)
public struct ClassTicketView: View {
  @Bindable public var store: StoreOf<ClassTicketFeature>

  public init(store: StoreOf<ClassTicketFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(
        onBack: { send(.backTapped) },
        centerTitle: store.navigationTitle
      )
      .foregroundStyle(.gray800)

      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          switch store.phase {
          case .entry:
            entryContent()
          case .preview:
            previewContent()
          case .registered:
            registeredContent()
          case .overview:
            overviewContent()
          }
        }
        .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize)
    }
    .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    .screenBackground(.surfaceBeigeDefault)
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
  }
}

private extension ClassTicketView {
  @ViewBuilder
  func entryContent() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      entryHeading()
        .padding(.bottom, 36)
      codeSection()
        .padding(.bottom, 24)
      faqSection()
      bottomSection()
        .padding(.top, 40)
    }
    .padding(.horizontal, 16)
    .padding(.top, 20)
  }

  @ViewBuilder
  func entryHeading() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("클래스 이용권을 등록하세요")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)

      Text("이메일을 통해 리워드로 받은 코드를 입력해 주세요\n등록 전에 이용권 내용을 확인할 수 있어요")
        .pretendardFont(.bodyMedium)
        .lineSpacing(4)
        .foregroundStyle(.gray300)
    }
  }

  @ViewBuilder
  func codeSection() -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 3) {
        Text("이용권 코드")
          .foregroundStyle(.gray800)
        Text("*")
          .foregroundStyle(.errorDefault)
      }
      .pretendardFont(.labelSmall)

      TextField("", text: $store.code, prompt: Text("전달 받은 코드를 입력해주세요").foregroundStyle(.gray300))
        .textInputAutocapitalization(.characters)
        .autocorrectionDisabled()
        .keyboardType(.asciiCapable)
        .pickeTextField(height: 44)
        .accessibilityIdentifier("class-ticket-code")

      if let errorMessage = store.errorMessage {
        Text(errorMessage)
          .pretendardFont(.bodySmall)
          .foregroundStyle(.errorDefault)
          .accessibilityIdentifier("class-ticket-error")
      }
    }
  }

  @ViewBuilder
  func faqSection() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      faqRow(
        index: 0,
        question: "이용권 코드는 어디서 확인하나요?",
        answer: "리워드로 받은 이메일에서 이용권 코드를 확인할 수 있어요."
      )
      faqRow(
        index: 1,
        question: "클래스 참여 코드와 다른가요?",
        answer: "이용권 코드는 클래스를 개설할 때 사용해요. 참여 코드는 다른 사람의 클래스에 들어갈 때 사용해요."
      )
    }
  }

  @ViewBuilder
  func faqRow(
    index: Int,
    question: String,
    answer: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Button {
        send(.faqTapped(index))
      } label: {
        HStack(spacing: 8) {
          Text(question)
            .pretendardFont(.bodySmall)
            .foregroundStyle(.gray300)
          Image(systemName: "chevron.down")
            .pretendardFont(.medium11)
            .foregroundStyle(.gray300)
            .rotationEffect(.degrees(store.expandedFAQ == index ? 180 : 0))
        }
        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      if store.expandedFAQ == index {
        Text(answer)
          .pretendardFont(.bodySmall)
          .foregroundStyle(.gray500)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, 4)
          .padding(.bottom, 12)
      }
    }
    .accessibilityIdentifier("class-ticket-faq-\(index)")
  }

  @ViewBuilder
  func previewContent() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("이용권 내용을 확인해 주세요")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
        .padding(.bottom, 8)

      Text("확인 후 등록하면 이용 기간이 바로 시작돼요")
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.gray300)
        .padding(.bottom, 36)

      ticketCard()

      if let errorMessage = store.errorMessage {
        Text(errorMessage)
          .pretendardFont(.bodySmall)
          .foregroundStyle(.errorDefault)
          .padding(.top, 12)
          .accessibilityIdentifier("class-ticket-error")
      }

      bottomSection()
        .padding(.top, 40)
    }
    .padding(.horizontal, 16)
    .padding(.top, 20)
  }

  @ViewBuilder
  func registeredContent() -> some View {
    VStack(spacing: 0) {
      registeredHeading()
        .padding(.bottom, 38)
      ticketCard()
      Text("등록 후 마이페이지에서 이용권을 확인할 수 있어요")
        .pretendardFont(.bodySmall)
        .foregroundStyle(.gray300)
        .padding(.top, 40)
      bottomSection()
        .padding(.top, 10)
    }
    .padding(.horizontal, 16)
    .padding(.top, 10)
  }

  @ViewBuilder
  func registeredHeading() -> some View {
    VStack(spacing: 8) {
      Text("이용권이 등록됐어요")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)

      Text("이제 우리만의 클래스를 열고\n사람들을 초대해보세요")
        .pretendardFont(.bodyMedium)
        .lineSpacing(4)
        .multilineTextAlignment(.center)
        .foregroundStyle(.gray300)
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  func overviewContent() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(store.overviewTitle)
        .pretendardFont(family: .SemiBold, size: 16)
        .foregroundStyle(.gray800)
        .padding(.bottom, 16)

      ticketCard()

      overviewBottomSection()
        .padding(.top, 40)
    }
    .padding(.horizontal, 16)
    .padding(.top, 20)
  }

  @ViewBuilder
  func overviewBottomSection() -> some View {
    VStack(spacing: 10) {
      Button("이용권 추가등록하기") {
        send(.addRegistrationTapped)
      }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .accessibilityIdentifier("class-ticket-add-registration")
    }
  }

  @ViewBuilder
  func ticketCard() -> some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          Image(asset: .tabClassActive)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
          Text(store.ticketTitle)
            .pretendardFont(family: .SemiBold, size: 18)
            .foregroundStyle(.gray800)
        }
        Text("함께 생각을 나누는 모임을 시작하세요")
          .pretendardFont(.bodySmall)
          .foregroundStyle(.primary500)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .background(.beige400)

      VStack(spacing: 16) {
        ticketDetail(label: "참여 인원", value: store.capacityDetail)
        ticketDetail(label: "이용 기간", value: store.ticketPeriodText)
        if store.phase == .preview, let registerBy = store.preview?.registerBy {
          ticketDetail(label: "등록 기한", value: registerBy.formatted(.yearMonthDayDotted))
        }
        ticketDetail(label: "클래스 생성", value: "이용 기간 내 무제한")
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 20)
    }
    .background(.surfaceBeigeDefault)
    .clipShape(RoundedRectangle(cornerRadius: 2))
    .overlay {
      RoundedRectangle(cornerRadius: 2)
        .strokeBorder(.borderGraySubtle, lineWidth: 1)
    }
    .accessibilityIdentifier("class-ticket-card")
  }

  @ViewBuilder
  func ticketDetail(
    label: String,
    value: String
  ) -> some View {
    HStack(spacing: 8) {
      Text(label)
        .foregroundStyle(.gray300)
      Spacer(minLength: 0)
      Text(value)
        .foregroundStyle(.gray500)
    }
    .pretendardFont(.bodySmall)
  }

  @ViewBuilder
  func bottomSection() -> some View {
    VStack(spacing: 10) {
      if (store.phase == .entry && !store.canCheckCode)
        || (store.phase == .preview && !store.canRegister)
      {
        Button(store.primaryButtonTitle) {}
          .pretendardFont(.headingMedium)
          .foregroundStyle(.gray300)
          .frame(maxWidth: .infinity)
          .frame(height: 52)
          .background(.gray100, in: RoundedRectangle(cornerRadius: 2))
          .buttonStyle(.plain)
          .disabled(true)
          .accessibilityIdentifier("class-ticket-primary")
      } else {
        Button {
          send(store.phase == .entry ? .checkTapped : .confirmTapped)
        } label: {
          Text(store.primaryButtonTitle)
        }
        .ctaButtonStyle(.primary, size: .large, height: 52)
        .accessibilityIdentifier("class-ticket-primary")
      }
    }
  }
}
