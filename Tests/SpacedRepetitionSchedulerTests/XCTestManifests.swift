// Copyright © 2020  Brian Dewey. Covered by the Apache 2.0 license.

import XCTest

#if !canImport(ObjectiveC)
  public func allTests() -> [XCTestCaseEntry] {
    return [
      testCase(SpacedRepetitionSchedulerTests.allTests),
    ]
  }
#endif
