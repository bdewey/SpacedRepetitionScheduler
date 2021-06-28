// Copyright © 2020  Brian Dewey. Covered by the Apache 2.0 license.

import Foundation

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
