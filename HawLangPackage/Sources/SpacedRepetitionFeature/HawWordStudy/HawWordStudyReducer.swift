
import ComposableArchitecture
import Dependencies
import Foundation
import SpacedRepetitionScheduler



@Reducer public struct HawWordStudyReducer {
  public init() {}
  @ObservableState public struct State: Equatable {
    public init() {
    }
    public var studySession: StudySessionReducer.State = .init(
      mode: .auto,
      promptsToStudy: [.init(
        value: HawWord(),
        lastReviewed: nil,
        metadata: .init()
      )]
    )
    public var errorMessage: String?
    
  }
  
  public indirect enum Action: Equatable, BindableAction, ViewAction {
    public typealias ParentReducer = HawWordStudyReducer
    case studySession(StudySessionReducer.Action)
    
    case binding(BindingAction<State>)
    
    case view(View)
    public enum View {
      case onTapAgain, onTapHard, onTapGood, onTapEasy
    }
    
    /// Tell the Reducer to respond to an Error.
    case throwError(ParentReducer.Error, State, Action)
    
  }
  
  public typealias HawSpacedPromptSorter = (SpacedPrompt<HawWord>, SpacedPrompt<HawWord>) -> Bool
  
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Scope(state: \.studySession, action: \.studySession) {
      StudySessionReducer()
    }
    
    Reduce<State, Action> { state, action in
      switch action {
        case .binding, .studySession:
          return .none
          
          
        // MARK: View Actions
        case .view(let viewAction):
          guard let currentPromptID = state.studySession.currentPrompt?.value.id else {
            return .send(.throwError(.idNotFound, state, action))
          }
          switch viewAction {
            case.onTapAgain:
              return .send(.studySession(.didRecall(id: currentPromptID, .again)))
            case .onTapHard:
              return .send(.studySession(.didRecall(id: currentPromptID, .hard)))
            case .onTapGood:
              return .send(.studySession(.didRecall(id: currentPromptID, .good)))
            case .onTapEasy:
              return .send(.studySession(.didRecall(id: currentPromptID, .easy)))
          }
          
          
        case let .throwError(message, erroredAction, erroredState):
          let errorString = "🔴 Error from Action: \(erroredAction) \n Message: \(message) \n State: \(erroredState)"
          print(errorString)
          state.errorMessage = errorString
          return .none
      }
    }
  }
}

// MARK: Errors
extension HawWordStudyReducer {
  public struct Error: Swift.Error, Equatable {
    public let message: String
    
    public static let idNotFound: Self = .init(message: "ID not found")
    public static func invalidState(_ message: String) -> Self {
      return  .init(message: "The Reducer is in an invalid state: Message:\(message)")
    }
    public static func unknown(error: Swift.Error) -> Self {
      Self.init(message: "Unknown Error: \(error)")
    }
  }
}

// MARK: Shared Computation
extension StudySessionReducer {
  
  
//  public static func sortingAlgo(_ first:SpacedPrompt<HawWord>, _ second:SpacedPrompt<HawWord>) -> Bool {
//    Self.lastReviewedAlgo(first, second)
//  }
}


