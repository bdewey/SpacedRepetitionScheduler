// Copyright © 2020  Brian Dewey. Covered by the Apache 2.0 license.

import Foundation

public extension TimeInterval {
  static let minute: TimeInterval = 60
  static let day: TimeInterval = 60 * 60 * 24
}

/// Holds parameters used to determine the recommended time to schedule the next review of a prompt.
public struct SchedulingParameters: Codable, Equatable {
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
