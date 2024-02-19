
import Dependencies
import Foundation

public struct HawWord: Identifiable, Equatable, Codable {
  public let id: UUID
  public var question: String = "inoa"
  public var answer: String = "name"
  
  public init() {
    @Dependency(\.uuid) var makeUUID
    self.id = makeUUID()
  }
}
