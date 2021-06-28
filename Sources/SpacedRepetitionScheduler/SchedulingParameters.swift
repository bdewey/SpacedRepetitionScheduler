// Copyright © 2020  Brian Dewey. Covered by the Apache 2.0 license.

import Foundation

public extension TimeInterval {
  static let minute: TimeInterval = 60
  static let day: TimeInterval = 60 * 60 * 24
}

/// Holds parameters used to determine the optimum time to schedule the next review of a prompt.
///
/// In a learning system that uses [active recall](https://en.wikipedia.org/wiki/Active_recall), learners are presented with a *prompt* and rate their ability
/// to recall the corresponding information. `SpacedRepetitionScheduler` determines the optimum time for the learner to see a *prompt* again, given his/her
/// history of recalling the information associated with this prompt and how well he/she did recalling the associated information this time.
///
/// A *prompt* can be either in a *learning* state or a *review* state.
///
/// - In the *learning* state, the learner must successfully recall the corresponding information a specific number of times, at which point the prompt graduates to the *review* state.
/// - In the *review* state, the amount of time between successive reviews of a prompt increases by a geometric progression with each successful recall.
public struct SchedulingParameters {
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
}
