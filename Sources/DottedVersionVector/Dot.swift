// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation

/**
 A pairing of a entity ID with an immutable counter value.
 
 NOTE: the `dot` definition in the `dvv.erl` Erlang file also has a timestamp value to disambiguate when the counter is the same.
 This implementation assumes that a server can keep that from happening, since this counter is by definition held and managed by a
 specific server.
 */
public struct Dot: Equatable {
  
  /// The key associated with the counter.
  public let key: String
  
  /// The counter value. Active counters start at 1 (zero is used to indicate a non-existant counter)
  public let counter: UInt64
  
  /**
   Obtain a new Dot instance with an incremented counted
   
   - returns: new Dot instance
   */
  func increment() -> Dot { Dot(key: self.key, counter: self.counter + 1) }
}

extension Dot: CustomStringConvertible {
  
  public var description: String { "•\(key):\(counter)" }
}
