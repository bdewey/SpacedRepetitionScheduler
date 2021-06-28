// Copyright © 2020  Brian Dewey. Covered by the Apache 2.0 license.

import Foundation

public extension TimeInterval {
  static let minute: TimeInterval = 60
  static let day: TimeInterval = 60 * 60 * 24
}

/// Implementation of an Anki-style spaced repetition scheduler for active recall items.
///
/// In a learning system that uses [active recall](https://en.wikipedia.org/wiki/Active_recall), learners are presented with a *prompt* and rate their ability
/// to recall the corresponding information. `SpacedRepetitionScheduler` determines the optimum time for the learner to see a *prompt* again, given his/her
/// history of recalling the information associated with this prompt and how well he/she did recalling the associated information this time.
///
/// A *prompt* can be either in a *learning* state or a *review* state.
///
/// - In the *learning* state, the learner must successfully recall the corresponding information a specific number of times, at which point the prompt graduates to the *review* state.
/// - In the *review* state, the amount of time between successive reviews of a prompt increases by a geometric progression with each successful recall.
public struct SpacedRepetitionScheduler {
  /// The state of a particular prompt.
  public enum LearningState: Hashable {
    /// Represents a prompt in the *learning* state.
    ///
    /// An item stays in the learning state until it has been recalled a specific number of times, determined by the number of items in the ``SpacedRepetitionScheduler.learningIntervals`` array.
    /// - parameter step: How many learning steps have been completed. `step == 0` implies a new card.
    case learning(step: Int)

    /// Represents a prompt in the *review* state.
    ///
    /// Items in the review state are scheduled at increasingly longer intervals with each successful recall.
    case review
  }

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
      factor: Double = 2.5
    ) {
      self.learningState = learningState
      self.reviewCount = reviewCount
      self.lapseCount = lapseCount
      self.reviewSpacingFactor = factor
      self.interval = interval
    }
  }

  /// Creates a `SpacedReptitionScheduler` with the specified scheduling parameters.
  ///
  /// - parameter learningIntervals: The time intervals between successive successful recalls of a prompt in *learning* mode. The number of items in this array determines how many times a learner must successfully recall a prompt for it to graduate to the *review* mode.
  /// - parameter easyGraduatingInterval: The ideal interval for reviewing a prompt again after it graduates from *learning* to *review* with a recall ease of *easy*.
  /// - parameter goodGraduatingInterval: The ideal interval for reviewing a prompt again after it graduates from *learning* to *review* with a recall ease of *good*.
  /// - parameter easyBoost: An additional mutiplicative factor for the scheduling interval when a prompt is in *review* mode and its recall ease is *easy*.
  public init(
    learningIntervals: [TimeInterval],
    easyGraduatingInterval: TimeInterval = 4 * .day,
    goodGraduatingInterval: TimeInterval = 1 * .day,
    easyBoost: Double = 1.3
  ) {
    self.learningIntervals = learningIntervals
    self.easyGraduatingInterval = easyGraduatingInterval
    self.goodGraduatingInterval = goodGraduatingInterval
    self.easyBoost = easyBoost
  }

  /// The intervals between successive steps when "learning" an item.
  public let learningIntervals: [TimeInterval]

  /// The ideal interval for reviewing a prompt again after it graduates from *learning* to *review* with a recall ease of *easy*.
  public let easyGraduatingInterval: TimeInterval

  /// The ideal interval for reviewing a prompt again after it graduates from *learning* to *review* with a recall ease of *good*.
  public let goodGraduatingInterval: TimeInterval

  /// An additional mutiplicative factor for the scheduling interval when a prompt is in *review* mode and its recall ease is *easy*.
  public let easyBoost: Double

  /// Returns a mapping of possible ``RecallEase`` values to updated ``PromptSchedulingMetadata`` values.
  /// - Parameters:
  ///   - promptSchedulingMetadata: The current ``PromptSchedulingMetadata`` for a prompt.
  ///   - timeIntervalSincePastReview: The duration of time since the prompt was last reviewed.
  /// - Returns: An array of key/value pairs associating a valid ``RecallEase`` to an updated ``PromptSchedulingMetadata`` if the prompt was recalled with that ease value.
  public func nextPromptSchedulingMetadataOptions(
    after promptSchedulingMetadata: PromptSchedulingMetadata,
    timeIntervalSincePastReview: TimeInterval = 0
  ) -> [(key: RecallEase, value: PromptSchedulingMetadata)] {
    let result = RecallEase.allCases.compactMap { answer in
      // result may be nil; in that case return nil instead of `(answer, nil)`
      self.updatingPromptSchedulingMetadata(after: promptSchedulingMetadata, recallEase: answer, timeIntervalSincePastReview: timeIntervalSincePastReview).flatMap { (answer, $0) }
    }
    return result
  }

  /// Returns the next ``PromptSchedulingMetadata`` for a prompt that was recalled with specified `recallEase` after `timeIntervalSincePastReview`
  /// - Parameters:
  ///   - promptSchedulingMetadata: The current ``PromptSchedulingMetadata`` for a prompt.
  ///   - recallEase: A value representing how easy the learner recalled the information associated with the prompt.
  ///   - timeIntervalSincePastReview: The duration of time since the prompt was last reviewed.
  /// - Returns: An updated value for ``PromptSchedulingMetadata``
  public func updatingPromptSchedulingMetadata(
    after promptSchedulingMetadata: PromptSchedulingMetadata,
    recallEase: RecallEase,
    timeIntervalSincePastReview: TimeInterval
  ) -> PromptSchedulingMetadata? {
    var result = promptSchedulingMetadata
    result.reviewCount += 1
    switch (promptSchedulingMetadata.learningState, recallEase) {
    case (.learning, .again):
      moveToFirstStep(&result)
    case (.learning, .easy):
      // Immediate graduation!
      result.learningState = .review
      result.interval = easyGraduatingInterval
    case (.learning, .hard):
      // Not a valid answer -- no "hard" for something we're learning
      return nil
    case (.learning(let step), .good):
      // Move to the next step.
      if step < (learningIntervals.count - 1) {
        result.interval = learningIntervals[step + 1]
        result.learningState = .learning(step: step + 1)
      } else {
        // Graduate to "review"
        result.learningState = .review
        result.interval = goodGraduatingInterval
      }
    case (.review, .again):
      result.lapseCount += 1
      result.reviewSpacingFactor = max(1.3, result.reviewSpacingFactor - 0.2)
      moveToFirstStep(&result)
    case (.review, .hard):
      result.interval = result.interval * 1.2
      result.reviewSpacingFactor = max(1.3, result.reviewSpacingFactor - 0.15)
    case (.review, .good):
      // Expand interval by factor, fuzzing the result, and ensuring that it at least moves forward
      // by the "hard" amount.
      result.interval = (result.interval + timeIntervalSincePastReview / 2) * result.reviewSpacingFactor
    case (.review, .easy):
      result.interval = (result.interval + timeIntervalSincePastReview) * result.reviewSpacingFactor * easyBoost
      result.reviewSpacingFactor += 0.15
    }
    return result
  }

  private func moveToFirstStep(_ result: inout PromptSchedulingMetadata) {
    // Go back to the initial learning step, schedule out a tiny bit.
    result.learningState = .learning(step: 0)
    result.interval = learningIntervals.first ?? .minute
  }
}
