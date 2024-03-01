import ComposableArchitecture
import Dependencies
import Foundation
import SpacedRepetitionScheduler
import Utilities



/// A Reducer in charge of prompting the user over one particular study session.
///
/// >Note: This Reducer is currently specific to studying Hawaiian words, but I hope to generalize it in the future.
/// ## Inspiration
/// - [StudySession.swift from  bdewey/LibraryNotes](https://github.com/bdewey/LibraryNotes/blob/master/LibraryNotes/StudySession.swift#L7)
/// ## Purpose
/// ### User Story
/// As a user, I want to:
/// - choose and select words to study, and have the app pick the next item to study.
@Reducer public struct StudySessionReducer {
  public init() {}
  @ObservableState public struct State: Equatable {
    public init(mode: Mode, promptsToStudy: IdentifiedArrayOf<SpacedPrompt<HawWord>>) {
      self.mode = mode
      @Dependency(\.date) var makeDate
      self.startDate = makeDate()
      self.promptsToStudy = promptsToStudy
      self.queue = promptsToStudy.elements
      self.mode = mode
      self.currentPrompt = self.queue.first
    }
    
    /// The current mode of the study session. e.g. learning or reviewing
    ///
    /// >Note: Not sure if I like this in the design.
    public var mode: Mode
    
    public var status: Status = .active
    
    /// The parameters for this particular study session
    public var params: SchedulingParameters = .standard
    /// The current set of prompts to study
    public var promptsToStudy: IdentifiedArrayOf<SpacedPrompt<HawWord>>
    public var queue: [SpacedPrompt<HawWord>]
    
    /// The prompt that the user is currently answering.
    ///
    /// If nil, then the StudySession is finished
    public var currentPrompt: SpacedPrompt<HawWord>?
    public var currentPromptIsLearning: Bool {
      guard let currentPrompt else { return false }
      let mode = currentPrompt.promptSchedulingMetadata.mode
      switch mode {
        case .learning: return true
        case .review: return false
      }
    }
    public var currentIndex: Int = 0
    
    /// When the person started this particular study session.
    public var startDate: Date
    
    /// When the person ended this particular study session.
    public var endDate: Date?
  }
  
  // MARK: Actions
  public indirect enum Action: Equatable, BindableAction {
    public typealias ParentReducer = StudySessionReducer
    case binding(BindingAction<State>)
    
    /// Call this when the user recalled an item, and the Reducer must update
    case didRecall(id: HawWord.ID, RecallEase)
    
    /// Tell the Reducer to respond to an Error.
    case throwError(ParentReducer.Error, ParentReducer.State, ParentReducer.Action)
    
    case copyPromptsToQueue
    case delegate(Delegate)
    public enum Delegate: Equatable {
      case didError(ParentReducer.Error)
    }
  }
  
  public typealias HawSpacedPromptSorter = (SpacedPrompt<HawWord>, SpacedPrompt<HawWord>) -> Bool
  
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce<State, Action> {
      state,
      action in
      switch action {
        case .binding, .delegate:
          return .none
          
        case .copyPromptsToQueue:
          state.queue = state.promptsToStudy.elements
          return .none
          
        case .didRecall(id: let id, var recallEase):
          guard state.status != .finished else {
            return self.throw(
              error: .invalidState("It's not valid to call .didRecall when StudySessionReducer.mode == .finished"),
              state: &state,
              action: action
            )
          }
          
          do {
            guard state.currentPrompt != nil else {
              let message = "Shouldn't be possible: .didRecall called when the currentPrompt is nil."
              return .send(.throwError(.invalidState(message), state, action))
            }
            guard let oldPromptValue = state.promptsToStudy[id: id] else {
              return self.throw(error: .idNotFound, state: &state, action: action)
            }
// Replace .hard with .again
// Since, SpacedRepetitionScheduler does not allow calling .hard when the mode is .learning.
            if case .hard = recallEase,
               case .learning = state.currentPrompt?.promptSchedulingMetadata.mode {
              recallEase = .again
            }
            
            // 👇🏼 time since last review or 0 if never reviewed before
            let timeIntervalSincePriorReview = abs(oldPromptValue.lastReviewed?.timeIntervalSinceNow ?? 0)
            let params = state.params
            try state.promptsToStudy[id: id]?.update(
              with: params,
              recallEase: recallEase,
              timeIntervalSincePriorReview: timeIntervalSincePriorReview
            )
            state.promptsToStudy[id: id]?.lastReviewed = Date.now
            guard let newPromptValue = state.promptsToStudy[id: id] else { return .none }
            
            state.currentIndex += 1
            
            // if necessary, append prompt to queue
            let mode = newPromptValue.promptSchedulingMetadata.mode
            if case .learning = mode {
              state.queue.append(newPromptValue)
            } else if
              case .review = mode {
              guard let nextReviewDate = newPromptValue.idealNextReviewDate else {
                let message = "It shouldn't be possible to have a .review mode prompt, without an idealNextReviewDate"
                return self.throw(error: .invalidState(message), state: &state, action: action)
              }
              if nextReviewDate < Date.now {
                state.queue.append(newPromptValue)
              }
            }
            
            // update current prompt and status
            state.currentPrompt = state.queue[safe: state.currentIndex]
            if state.currentPrompt == nil {
              state.status = .finished
            }
            return .none
            
          } catch {
            if case PromptSchedulingMetadata.SchedulingError.noHardRecallForLearningItems = error   {
              print("⚠️ From PromptSchedulingMetadata.swift: 'Error when we try to say that recall was 'hard' for an item in the `learning` state.  This is not a valid scheduling option and should not be shown to a learner.'")
              // try again with a .again recallEase
              return .send(.didRecall(id: id, .again))
            }
            return self.throw(error: .unknown(error: error), state: &state, action: action)
          }
          
        case let .throwError(error, state, action):
          print("🔴 Error || Message: \(error.message) \n ||||| Action: \(action) \n ||||| \n State: \(state)")
          return .none
      }
    }
  }
}

// MARK: Errors
extension StudySessionReducer {
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
  func `throw`(error: Self.Error, state: inout State, action: Action) -> Effect<Action> {
    print("🔴 Error || Message: \(error.message) \n ||||| Action: \(action) \n ||||| \n State: \(state)")
    // respond to Errors here
    let shouldNotifyParents = false
    if shouldNotifyParents {
      return .send(.delegate(.didError(error)))
    } else {
      return .none
    }
  }
  
  func refreshCurrentPrompt(_ state: inout State) -> Effect<Action> {
    state.currentPrompt = state.queue[safe: state.currentIndex]
    return .none
  }
  
  
  /// Sorts the prompts by mode and last reviewed date
  ///
  /// Prompts will be grouped by mode. First `learning`, then `review`.
  /// Prompts are further sorted by `lastReviewed` date, from least to most recent.
  func sortPrompts(_ state: inout State) -> Effect<Action> {
    
    var toReview = state.promptsToStudy.filter { $0.promptSchedulingMetadata.mode == .review }
    var toLearn = state.promptsToStudy.filter { // $0.promptSchedulingMetadata.mode == .learning
      if case .learning = $0.promptSchedulingMetadata.mode {
        return true
      } else {
        return false
      }
    }
    
    toReview.sort(by: Self.lastReviewedAlgo)
    toLearn.sort(by: Self.lastReviewedAlgo)
    
    var promptsNewValue: IdentifiedArrayOf<SpacedPrompt<HawWord>> = []
    promptsNewValue.append(contentsOf: toReview)
    promptsNewValue.append(contentsOf: toLearn)
    state.promptsToStudy = promptsNewValue
    return .none
  }
}

// MARK: Sorting
extension StudySessionReducer {
  
  public static func lastReviewedAlgo(_ first:SpacedPrompt<HawWord>, _ second:SpacedPrompt<HawWord>) -> Bool {
    guard let lastReviewed0 = first.lastReviewed,
          let lastReviewed1 = second.lastReviewed else {
      return true
    }
    return lastReviewed0 > lastReviewed1
  }
  
  public static func sortingAlgo(_ first:SpacedPrompt<HawWord>, _ second:SpacedPrompt<HawWord>) -> Bool {
    Self.lastReviewedAlgo(first, second)
  }
}

// MARK: SchedulingParamters
extension SchedulingParameters {
  static let standard: SchedulingParameters = .init(
    learningIntervals: [1 * .minute, 10 * .minute]
  )
}


