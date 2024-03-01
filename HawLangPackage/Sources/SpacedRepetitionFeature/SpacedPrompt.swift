import Foundation
import SpacedRepetitionScheduler


/// A wrapper type around a value with the info necessary to use the "spaced repetition" algorithm
public struct SpacedPrompt<Value: Equatable>: Equatable {
  public var value: Value
  /// the last time this prompt was reviewed, if ever
  public var lastReviewed: Date?
  /// the next time that the algo recommends to review this prompt
  public var idealNextReviewDate: Date?
  private(set) var promptSchedulingMetadata: PromptSchedulingMetadata
  
  public init(value: Value, lastReviewed: Date? = nil, idealNextReviewDate: Date? = nil, metadata: PromptSchedulingMetadata) {
    self.value = value
    self.lastReviewed = lastReviewed
    self.promptSchedulingMetadata = metadata
  }
  
  public mutating func update(
    with schedulingParameter: SchedulingParameters,
    recallEase: RecallEase,
    timeIntervalSincePriorReview: TimeInterval
  ) throws {
    try self.promptSchedulingMetadata.update(
      with: schedulingParameter,
      recallEase: recallEase,
      timeIntervalSincePriorReview: timeIntervalSincePriorReview
    )
    let nextTimeInterval = self.promptSchedulingMetadata.interval
    self.lastReviewed = .now
    self.idealNextReviewDate = .now.addingTimeInterval(nextTimeInterval)
    
  }
  
  public func updating(
    with schedulingParameter: SchedulingParameters,
    recallEase: RecallEase,
    timeIntervalSincePriorReview: TimeInterval
  ) throws -> Self {
    var copy = self
    try copy.update(
      with: schedulingParameter,
      recallEase: recallEase,
      timeIntervalSincePriorReview: timeIntervalSincePriorReview
    )
    return copy
  }
}

extension SpacedPrompt: Identifiable where Value: Identifiable {
  public var id: Value.ID { self.value.id }
}


