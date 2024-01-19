// Copyright © 2020  Brian Dewey. Covered by the Apache 2.0 license.

import Foundation

/// Rating for how easy it is to recall the information associated with a prompt.
public enum RecallEase: Int, CaseIterable, Codable, Hashable {
  /// The learner was not able to recall the information associated with a prompt.
  case again

  /// The learner had difficulty recalling the information associated with a prompt and would like to review the corresponding prompt more frequently.
  case hard

  /// The learner could recall the information associated with a prompt with the expected amount of difficulty, and would like to normally space out future reviews of this prompt.
  case good

  /// The learner effortlessly recalled the information associated with a prompt, and would like to greatly space out future reviews of the prompt.
  case easy
}
