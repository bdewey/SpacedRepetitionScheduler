// Copyright © 2020  Brian Dewey. Covered by the Apache 2.0 license.

import SpacedRepetitionScheduler
import XCTest

final class SpacedRepetitionSchedulerTests: XCTestCase {
  let schedulingParameters = SchedulingParameters(
    learningIntervals: [1 * .minute, 10 * .minute]
  )

  func testScheduleNewCard() {
    let newItem = PromptSchedulingMetadata(mode: .learning(step: 0))
    let results = newItem.allPossibleUpdates(with: schedulingParameters)

    // shouldn't be a "hard" answer
    XCTAssertEqual(results.count, RecallEase.allCases.count - 1)
    // Check that the repetition count increased for all items.
    for result in results {
      XCTAssertEqual(result.value.reviewCount, 1)
    }

    XCTAssertEqual(results[.again]?.mode, .learning(step: 0))
    XCTAssertEqual(results[.again]?.interval, schedulingParameters.learningIntervals[0])

    // Cards that were "easy" immediately leave the learning state.
    XCTAssertEqual(results[.easy]?.mode, .review)
    XCTAssertEqual(results[.easy]?.interval, schedulingParameters.easyGraduatingInterval)

    // Cards that were "good" move to the next state.
    XCTAssertEqual(results[.good]?.mode, .learning(step: 1))
    XCTAssertEqual(results[.good]?.interval, schedulingParameters.learningIntervals[1])
  }

  func testScheduleReadyToGraduateCard() {
    let readyToGraduateItem = PromptSchedulingMetadata(
      mode: .learning(step: schedulingParameters.learningIntervals.count - 1)
    )
    let results = readyToGraduateItem.allPossibleUpdates(with: schedulingParameters)

    // shouldn't be a "hard" answer
    XCTAssertEqual(results.count, RecallEase.allCases.count - 1)
    // Check that the repetition count increased for all items.
    for result in results {
      XCTAssertEqual(result.value.reviewCount, 1)
    }

    XCTAssertEqual(results[.again]?.mode, .learning(step: 0))
    XCTAssertEqual(results[.again]?.interval, schedulingParameters.learningIntervals[0])

    // Cards that were "easy" immediately leave the learning state.
    XCTAssertEqual(results[.easy]?.mode, .review)
    XCTAssertEqual(results[.easy]?.interval, schedulingParameters.easyGraduatingInterval)

    // Cards that were "good" graduate.
    XCTAssertEqual(results[.good]?.mode, .review)
    XCTAssertEqual(results[.good]?.interval, schedulingParameters.goodGraduatingInterval)
  }

  func testProgressFromNewToReview() throws {
    var item = PromptSchedulingMetadata()

    for _ in 0 ..< schedulingParameters.learningIntervals.count {
      // Answer the item as "good"
      try item.update(with: schedulingParameters, recallEase: .good, timeIntervalSincePriorReview: 0)
    }
    XCTAssertEqual(item.mode, .review)
    XCTAssertEqual(item.interval, schedulingParameters.goodGraduatingInterval)
  }

  func testScheduleReviewCard() {
    let reviewItem = PromptSchedulingMetadata(
      mode: .review,
      reviewCount: 5,
      interval: 4 * .day
    )
    let delay: TimeInterval = .day
    let results = reviewItem.allPossibleUpdates(with: schedulingParameters, timeIntervalSincePriorReview: delay)
    XCTAssertEqual(results[.again]?.lapseCount, 1)
    XCTAssertEqual(results[.again]?.interval, schedulingParameters.learningIntervals.first)
    XCTAssertEqual(results[.again]?.mode, .learning(step: 0))
    XCTAssertEqual(results[.again]!.reviewSpacingFactor, 2.3, accuracy: 0.01)

    XCTAssertEqual(results[.hard]?.lapseCount, 0)
    XCTAssertEqual(results[.hard]?.mode, .review)
    XCTAssertEqual(results[.hard]!.reviewSpacingFactor, 2.5 - 0.15, accuracy: 0.01)
    XCTAssertEqual(results[.hard]!.interval, reviewItem.interval * 1.2, accuracy: 0.01)

    XCTAssertEqual(results[.good]?.lapseCount, 0)
    XCTAssertEqual(results[.good]?.mode, .review)
    XCTAssertEqual(results[.good]!.reviewSpacingFactor, 2.5, accuracy: 0.01)
    XCTAssertEqual(results[.good]!.interval, (reviewItem.interval + delay / 2) * reviewItem.reviewSpacingFactor, accuracy: 0.01)

    XCTAssertEqual(results[.easy]?.lapseCount, 0)
    XCTAssertEqual(results[.easy]?.mode, .review)
    XCTAssertEqual(results[.easy]!.reviewSpacingFactor, 2.5 + 0.15, accuracy: 0.01)
    XCTAssertEqual(results[.easy]!.interval, (reviewItem.interval + delay) * reviewItem.reviewSpacingFactor * schedulingParameters.easyBoost, accuracy: 0.01)
  }
}
