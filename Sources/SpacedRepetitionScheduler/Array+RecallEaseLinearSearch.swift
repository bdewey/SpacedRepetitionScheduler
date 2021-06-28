// Copyright © 2020  Brian Dewey. Covered by the Apache 2.0 license.

import Foundation

public extension Array where Element == (key: RecallEase, value: PromptSchedulingMetadata) {
  /// Performs a linear search through the receiver for a given ``RecallEase`` and returns the associated ``PromptSchedulingMetadata``.
  subscript(_ answer: RecallEase) -> PromptSchedulingMetadata? {
    for (candidateAnswer, item) in self where candidateAnswer == answer {
      return item
    }
    return nil
  }
}
