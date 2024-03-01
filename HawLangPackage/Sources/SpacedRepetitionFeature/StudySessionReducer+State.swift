extension StudySessionReducer.State {
  public enum Mode: CustomDebugStringConvertible, Equatable {
    /// Only study learning cards
    case learning
    /// Only study reviewing cards
    case reviewing
    /// Study learning and reviewing cards, and let the reducer decide the priority and order
    case auto
    
    public var debugDescription: String {
      switch self {
        case .learning: ".learning"
        case .reviewing: ".reviewing"
        case .auto: ".auto"
      }
    }
  }
  
  public enum Status: CustomDebugStringConvertible, Equatable {
    public var debugDescription: String {
      switch self {
        case .active: ".active"
        case .finished: ".finished"
      }
    }
    
    /// We are still in a study session
    case active
    /// The study session has finished. We have run out of prompts.
    case finished
  }
}
