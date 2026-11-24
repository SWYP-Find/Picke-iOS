import ClassDomainInterface
import ComposableArchitecture

extension ClassUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassInterface { ClassUseCaseImpl() }
}

extension ClassRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassInterface { ClassRepositoryImpl() }
}

extension ClassRoomUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassRoomInterface { ClassUseCaseImpl() }
}

extension ClassRoomRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassRoomInterface { ClassRepositoryImpl() }
}

extension ClassRecommendationUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassRecommendationInterface { ClassUseCaseImpl() }
}

extension ClassRecommendationRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassRecommendationInterface { ClassRepositoryImpl() }
}

extension ClassBattleUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassBattleInterface { ClassUseCaseImpl() }
}

extension ClassBattleRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassBattleInterface { ClassRepositoryImpl() }
}

extension ClassMemberUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassMemberInterface { ClassUseCaseImpl() }
}

extension ClassMemberRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassMemberInterface { ClassRepositoryImpl() }
}

extension ClassDebateUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassDebateInterface { ClassUseCaseImpl() }
}

extension ClassDebateRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassDebateInterface { ClassRepositoryImpl() }
}

extension ClassTicketUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassTicketInterface { ClassUseCaseImpl() }
}

extension ClassTicketRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassTicketInterface { ClassRepositoryImpl() }
}

extension ClassResultUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassResultInterface { ClassUseCaseImpl() }
}

extension ClassResultRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassResultInterface { ClassRepositoryImpl() }
}

extension ClassTopicDraftUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassTopicDraftInterface { ClassUseCaseImpl() }
}

extension ClassTopicDraftRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassTopicDraftInterface { ClassRepositoryImpl() }
}

extension ClassReportUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassReportInterface { ClassUseCaseImpl() }
}

extension ClassReportRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassReportInterface { ClassRepositoryImpl() }
}

extension ClassLocalAIUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassLocalAIInterface { ClassUseCaseImpl() }
}

extension ClassLocalAIRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassLocalAIInterface { ClassRepositoryImpl() }
}
