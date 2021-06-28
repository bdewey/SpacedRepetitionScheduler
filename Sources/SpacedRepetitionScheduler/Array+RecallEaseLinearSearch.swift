//
//  File.swift
//  
//
//  Created by Brian Dewey on 6/27/21.
//

import Foundation

public extension Array where Element == (key: RecallEase, value: SpacedRepetitionScheduler.PromptSchedulingMetadata) {
  /// Performs a linear search through the receiver for a given ``RecallEase`` and returns the associated ``SpacedRepetitionScheduler.PromptSchedulingMetadata``.
  subscript(_ answer: RecallEase) -> SpacedRepetitionScheduler.PromptSchedulingMetadata? {
    for (candidateAnswer, item) in self where candidateAnswer == answer {
      return item
    }
    return nil
  }
}
