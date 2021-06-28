// Copyright © 2020  Brian Dewey. Covered by the Apache 2.0 license.

import Foundation

/// Information needed to determine the optimum time to review a prompt again.
public struct PromptSchedulingMetadata: Hashable {
  /// The learning state of this prompt.
  public var learningState: LearningState

  /// How many times this prompt has been reviewed.
  public var reviewCount: Int

  /// How many times this prompt regressed from "review" back to "learning"
  public var lapseCount: Int

  /// The ideal amount of time until seeing this prompt again.
  public var interval: TimeInterval

  /// The multiplicative factor for increasing the delay for seeing this prompt again, if ``learningState`` is `.review`.
  public var reviewSpacingFactor: Double

  /// Creates prompt metadata with specific values.
  public init(
    learningState: LearningState = .learning(step: 0),
    reviewCount: Int = 0,
    lapseCount: Int = 0,
    interval: TimeInterval = 0,
    reviewSpacingFactor: Double = 2.5
  ) {
    self.learningState = learningState
    self.reviewCount = reviewCount
    self.lapseCount = lapseCount
    self.reviewSpacingFactor = reviewSpacingFactor
    self.interval = interval
  }

  enum SchedulingError: Error {
    /// Error when we try to say that recall was "hard" for an item in the `learning` state.  This is not a valid scheduling option and should not be shown to a learner.
    case noHardRecallForLearningItems
  }

  /// Updates the receiver given the prompt was recalled with specified `recallEase` after `timeIntervalSincePastReview`.
  /// - Parameters:
  ///   - schedulingParameters: Parameters used to compute the ideal time to review a prompt again.
  ///   - recallEase: A value representing how easy the learner recalled the information associated with the prompt.
  ///   - timeIntervalSincePriorReview: The duration of time since the prompt was last reviewed.
  /// - Returns: An updated value for ``PromptSchedulingMetadata``
  public mutating func update(
    with schedulingParameters: SchedulingParameters,
    recallEase: RecallEase,
    timeIntervalSincePriorReview: TimeInterval
  ) throws {
    reviewCount += 1
    switch (learningState, recallEase) {
    case (.learning, .again):
      moveToFirstStep(schedulingParameters: schedulingParameters)
    case (.learning, .easy):
      // Immediate graduation!
      learningState = .review
      interval = schedulingParameters.easyGraduatingInterval
    case (.learning, .hard):
      // Not a valid answer -- no "hard" for something we're learning
      throw SchedulingError.noHardRecallForLearningItems
    case (.learning(let step), .good):
      // Move to the next step.
      if step < (schedulingParameters.learningIntervals.count - 1) {
        interval = schedulingParameters.learningIntervals[step + 1]
        learningState = .learning(step: step + 1)
      } else {
        // Graduate to "review"
        learningState = .review
        interval = schedulingParameters.goodGraduatingInterval
      }
    case (.review, .again):
      lapseCount += 1
      reviewSpacingFactor = max(1.3, reviewSpacingFactor - 0.2)
      moveToFirstStep(schedulingParameters: schedulingParameters)
    case (.review, .hard):
      interval *= 1.2
      reviewSpacingFactor = max(1.3, reviewSpacingFactor - 0.15)
    case (.review, .good):
      // Expand interval by factor, fuzzing the result, and ensuring that it at least moves forward
      // by the "hard" amount.
      interval = (interval + timeIntervalSincePriorReview / 2) * reviewSpacingFactor
    case (.review, .easy):
      interval = (interval + timeIntervalSincePriorReview) * reviewSpacingFactor * schedulingParameters.easyBoost
      reviewSpacingFactor += 0.15
    }
  }

  /// Updates the receiver given the prompt was recalled with specified `recallEase` after `timeIntervalSincePastReview`.
  /// - Parameters:
  ///   - schedulingParameters: Parameters used to compute the ideal time to review a prompt again.
  ///   - recallEase: A value representing how easy the learner recalled the information associated with the prompt.
  ///   - timeIntervalSincePastReview: The duration of time since the prompt was last reviewed.
  /// - Returns: An updated value for ``PromptSchedulingMetadata``
  public func updating(
    with schedulingParameters: SchedulingParameters,
    recallEase: RecallEase,
    timeIntervalSincePriorReview: TimeInterval
  ) throws -> PromptSchedulingMetadata {
    var copy = self
    try copy.update(
      with: schedulingParameters,
      recallEase: recallEase,
      timeIntervalSincePriorReview: timeIntervalSincePriorReview
    )
    return copy
  }

  /// Returns a mapping of possible ``RecallEase`` values to updated ``PromptSchedulingMetadata`` values.
  /// - Parameters:
  ///   - promptSchedulingMetadata: The current ``PromptSchedulingMetadata`` for a prompt.
  ///   - timeIntervalSincePastReview: The duration of time since the prompt was last reviewed.
  /// - Returns: An array of key/value pairs associating a valid ``RecallEase`` to an updated ``PromptSchedulingMetadata`` if the prompt was recalled with that ease value.
  public func allPossibleUpdates(
    with schedulingParameters: SchedulingParameters,
    timeIntervalSincePriorReview: TimeInterval = 0
  ) -> [(key: RecallEase, value: PromptSchedulingMetadata)] {
    let result = RecallEase.allCases.compactMap { recallEase -> (RecallEase, PromptSchedulingMetadata)? in
      guard let updatedMetadata = try? self.updating(with: schedulingParameters, recallEase: recallEase, timeIntervalSincePriorReview: timeIntervalSincePriorReview) else {
        return nil
      }
      return (recallEase, updatedMetadata)
    }
    return result
  }

  private mutating func moveToFirstStep(schedulingParameters: SchedulingParameters) {
    // Go back to the initial learning step, schedule out a tiny bit.
    learningState = .learning(step: 0)
    interval = schedulingParameters.learningIntervals.first ?? .minute
  }
}
