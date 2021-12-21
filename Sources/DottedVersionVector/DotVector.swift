// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation

/// Container of Dot instances that makes up a version vector.
internal typealias DotVector = Array<Dot>

extension DotVector {
  
  /**
   Search for a given counter key in the version vector.
   
   - parameter key: the counter to locate
   - returns: the index in the vector where the counter key should be to stay ordered
   */
  internal func search(_ key: String) -> Index {
    var low = startIndex
    var high = endIndex
    while low != high {
      let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
      if self[mid].key < key {
        low = index(after: mid)
      } else {
        high = mid
      }
    }
    return low
  }
}

extension DotVector {
  
  /**
   Locate the counter for the given key, returning 0 if not found
   
   - parameter key: the key to look for
   - returns: the counter value if found or nil
   */
  internal func counter(of key: String) -> UInt64 {
    let index = search(key)
    return (index < count && self[index].key == key) ? self[index].counter : 0
  }
  
  /**
   Create new instance holding a version vector with the counter for the given key incremented by one.
   
   - parameter key: the key of the counter to increment
   - returns: new VersionVector instance
   */
  internal func inc(_ key: String) -> Self { .init(merge([.init(key: key, counter: counter(of: key) + 1)])) }
  
  /**
   Determine if this version vector descends from another.
   
   - parameter rhs: the version vector to check against
   - returns: true if this instance descends from or is equal to `other`
   */
  internal func descends(_ other: Self) -> Bool {
    other.first { counter(of: $0.key) < $0.counter } == nil
  }
  
  /**
   Generate a Dot instance using the counter + 1 for the given key
   
   - parameter key: the key of the counter to use
   - returns: new Dot instance
   */
  internal func dot(of key: String) -> Dot { .init(key: key, counter: counter(of: key) + 1) }
  
  /**
   Merge two Dot collections. Resulting collection of Dot entities will be ordered by their `id` value and counters
   will be the max value found in both collections.
   
   - parameter other: the collection to merge with
   - returns: new collection of Dot instances
   */
  internal func merge(_ other: Self) -> Self { .init(MergingDotIterator(self, other)) }
}

extension DotVector {
  
  private struct DotIterator {
    private let sequence: [Dot]
    private var index = 0
    
    var hasValue: Bool { index < sequence.count }
    var value: Dot { sequence[index] }
    
    init(sequence: [Dot]) { self.sequence = sequence }
    
    mutating func fetchAndIterate() -> Dot {
      next()
      return sequence[index - 1]
    }
    
    mutating func next() { index += 1 }
  }
  
  private struct MergingDotIterator: Sequence, IteratorProtocol {
    private var v1: DotIterator
    private var v2: DotIterator
    
    init(_ v1: [Dot], _ v2: [Dot]) {
      self.v1 = DotIterator(sequence: v1)
      self.v2 = DotIterator(sequence: v2)
    }
    
    mutating func next() -> Dot? {
      while v1.hasValue && v2.hasValue {
        let dot1 = v1.value
        let dot2 = v2.value
        
        if dot1.key < dot2.key {
          v1.next()
          return dot1
        }
        
        if dot1.key > dot2.key {
          v2.next()
          return dot2
        }
        
        v1.next()
        v2.next()
        return Dot(key: dot1.key, counter: Swift.max(dot1.counter, dot2.counter))
      }
      
      while v1.hasValue { return v1.fetchAndIterate() }
      while v2.hasValue { return v2.fetchAndIterate() }
      
      return nil
    }
  }
}
