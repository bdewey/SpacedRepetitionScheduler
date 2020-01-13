// Copyright © 2019-present Brian's Brain. All rights reserved.

import XCTest

#if !canImport(ObjectiveC)
  public func allTests() -> [XCTestCaseEntry] {
    return [
      testCase(SpacedRepetitionSchedulerTests.allTests),
    ]
  }
#endif
