// Copyright © 2020  Brian Dewey. Covered by the Apache 2.0 license.

import SpacedRepetitionScheduler
import XCTest

final class SpacedRepetitionSchedulerTests: XCTestCase {
  let scheduler = SpacedRepetitionScheduler(
    learningIntervals: [1 * .minute, 10 * .minute]
  )

  func testScheduleNewCard() {
    let newItem = SpacedRepetitionScheduler.PromptSchedulingMetadata(learningState: .learning(step: 0))
    let results = scheduler.nextPromptSchedulingMetadataOptions(after: newItem)

    // shouldn't be a "hard" answer
    XCTAssertEqual(results.count, RecallEase.allCases.count - 1)
    // Check that the repetition count increased for all items.
    for result in results {
      XCTAssertEqual(result.value.reviewCount, 1)
    }

    XCTAssertEqual(results[.again]?.learningState, .learning(step: 0))
    XCTAssertEqual(results[.again]?.interval, scheduler.learningIntervals[0])

    // Cards that were "easy" immediately leave the learning state.
    XCTAssertEqual(results[.easy]?.learningState, .review)
    XCTAssertEqual(results[.easy]?.interval, scheduler.easyGraduatingInterval)

    // Cards that were "good" move to the next state.
    XCTAssertEqual(results[.good]?.learningState, .learning(step: 1))
    XCTAssertEqual(results[.good]?.interval, scheduler.learningIntervals[1])
  }

  func testScheduleReadyToGraduateCard() {
    let readyToGraduateItem = SpacedRepetitionScheduler.PromptSchedulingMetadata(
      learningState: .learning(step: scheduler.learningIntervals.count - 1)
    )
    let results = scheduler.nextPromptSchedulingMetadataOptions(after: readyToGraduateItem)

    // shouldn't be a "hard" answer
    XCTAssertEqual(results.count, RecallEase.allCases.count - 1)
    // Check that the repetition count increased for all items.
    for result in results {
      XCTAssertEqual(result.value.reviewCount, 1)
    }

    XCTAssertEqual(results[.again]?.learningState, .learning(step: 0))
    XCTAssertEqual(results[.again]?.interval, scheduler.learningIntervals[0])

    // Cards that were "easy" immediately leave the learning state.
    XCTAssertEqual(results[.easy]?.learningState, .review)
    XCTAssertEqual(results[.easy]?.interval, scheduler.easyGraduatingInterval)

    // Cards that were "good" graduate.
    XCTAssertEqual(results[.good]?.learningState, .review)
    XCTAssertEqual(results[.good]?.interval, scheduler.goodGraduatingInterval)
  }

  func testProgressFromNewToReview() {
    var item = SpacedRepetitionScheduler.PromptSchedulingMetadata()

    for _ in 0 ..< scheduler.learningIntervals.count {
      // Answer the item as "good"
      item = scheduler.nextPromptSchedulingMetadataOptions(after: item)[.good]!
    }
    XCTAssertEqual(item.learningState, .review)
    XCTAssertEqual(item.interval, scheduler.goodGraduatingInterval)
  }

  func testScheduleReviewCard() {
    let reviewItem = SpacedRepetitionScheduler.PromptSchedulingMetadata(
      learningState: .review,
      reviewCount: 5,
      interval: 4 * .day
    )
    let delay: TimeInterval = .day
    let results = scheduler.nextPromptSchedulingMetadataOptions(after: reviewItem, timeIntervalSincePastReview: delay)
    XCTAssertEqual(results[.again]?.lapseCount, 1)
    XCTAssertEqual(results[.again]?.interval, scheduler.learningIntervals.first)
    XCTAssertEqual(results[.again]?.learningState, .learning(step: 0))
    XCTAssertEqual(results[.again]!.reviewSpacingFactor, 2.3, accuracy: 0.01)

    XCTAssertEqual(results[.hard]?.lapseCount, 0)
    XCTAssertEqual(results[.hard]?.learningState, .review)
    XCTAssertEqual(results[.hard]!.reviewSpacingFactor, 2.5 - 0.15, accuracy: 0.01)
    XCTAssertEqual(results[.hard]!.interval, reviewItem.interval * 1.2, accuracy: 0.01)

    XCTAssertEqual(results[.good]?.lapseCount, 0)
    XCTAssertEqual(results[.good]?.learningState, .review)
    XCTAssertEqual(results[.good]!.reviewSpacingFactor, 2.5, accuracy: 0.01)
    XCTAssertEqual(results[.good]!.interval, (reviewItem.interval + delay / 2) * reviewItem.reviewSpacingFactor, accuracy: 0.01)

    XCTAssertEqual(results[.easy]?.lapseCount, 0)
    XCTAssertEqual(results[.easy]?.learningState, .review)
    XCTAssertEqual(results[.easy]!.reviewSpacingFactor, 2.5 + 0.15, accuracy: 0.01)
    XCTAssertEqual(results[.easy]!.interval, (reviewItem.interval + delay) * reviewItem.reviewSpacingFactor * scheduler.easyBoost, accuracy: 0.01)
  }
}
