import Foundation

/**
 A _dotted_ version vector. The `dot` represents a server-side counter that is incremented at every write/store/put action.
 */
public struct DVV: Equatable {

    /// The collection of counters that define the version history for key
    internal let vv: DotVector

    /// The server/replica counter
    internal let dot: Dot?

    /**
     Construct new instance with the given (default) values.

     - parameter vv: the version vector to initialize with (default is empty array)
     - parameter dot: the server counter to use (default is nil)
     */
    init(vv: DotVector = [], dot: Dot? = nil) {
        self.vv = vv
        self.dot = dot
    }
}

extension DVV: CustomStringConvertible {
    public var description: String { "<[\(vv.map{$0.description}.joined(separator: ","))] \(dot?.description ?? "nil")>" }
}

extension DVV {

    /**
     Obtain a new DVV with the given key incremented by 1

     - parameter key: the key to increment
     - returns: new DVV instance
     */
    public func increment(key: String) -> DVV { Self.update(client: self, server: self, key: key) }

    /**
     Determine if this DVV descends from another. Note that this is true when `rhs` is nil.

     - parameter rhs: the DVV to check against
     - returns: true if this instance descends from or is equal to `rhs`
     */
    public func descends(_ rhs: DVV?) -> Bool {
        guard let rhs = rhs else { return true }
        return self == rhs || self.descendsStrictly(rhs)
    }

    /**
     Determine if this DVV strictly descends from another, where _strictly_ means the two instances cannot be
     equal. Note that this is true when `rhs` is nil.

     - parameter rhs: the DVV to check against.
     - returns: true if this instance descends from `rhs`
     */
    public func descendsStrictly(_ rhs: DVV?) -> Bool {
        guard let rhs = rhs else { return true }
        guard self != rhs else { return false }
        guard let _ = dot, let dot2 = rhs.dot else { return vv.descends(rhs.vv) }
        return vv.counter(of: dot2.key) >= dot2.counter
    }
}

// MARK: - Internal Implementation Methods

extension DVV {

    /**
     Obtain a DotVector containing the merge of the version vector and the dot

     - returns: new DotVector
     */
    internal func mergeDot() -> DotVector {
        guard let dot = dot else { return self.vv }
        return vv.merge([dot])
    }

    /**
     Obtain the counter for a given key. Looks first in the `dot` and then in the version vector.

     - parameter key: the key to fetch
     - returns: the counter value
     */
    internal func counter(of key: String) -> UInt64 {
        if let dot = dot, key == dot.key { return dot.counter }
        return vv.counter(of: key)
    }

    /**
     Obtain a new Dot instance containing the counter of the given key

     - parameter key: the key to use
     - returns: the new Dot instance
     */
    internal func dot(of key: String) -> Dot { Dot(key: key, counter: counter(of: key) + 1) }
}

private func mergeToVector(dvs: [DotVector]) -> DotVector { dvs.reduce(into: DotVector()) { $0 = $0.merge($1) } }
private func mergeToVector(dvvs: [DVV]) -> DotVector { mergeToVector(dvs: dvvs.map { $0.mergeDot() }) }

// MARK: - DVV transformations and reductions

extension DVV {

    /**
     Obtain a clock that is newer than the client and server clocks at the given `key` counter.

     - parameter client: the version vector from a client
     - parameter server: the version vector from a server
     - parameter key: the server key
     - returns: new DVV
     */
    public static func update(client: DVV?, server: DVV?, key: String) -> DVV {
        DVV(vv: client?.mergeDot() ?? [], dot: (server ?? DVV()).dot(of: key))
    }

    /**
     Obtain a clock that is newer than the client and server clocks at the given `key` counter.

     - parameter client: one or more version vectors from a client
     - parameter server: one or more version vectors from a server
     - parameter key: the server key
     - returns: new DVV
     */
    public static func update(client: [DVV], server: [DVV], key: String) -> DVV {
        DVV(vv: mergeToVector(dvvs: client), dot: mergeToVector(dvvs: server).dot(of: key))
    }

    /**
     Merges a collection of clocks into a new DVV, removing redundant information (old entries).

     - parameter dvvs: collection of DVV instances to merge
     - returns: new DVV
     */
    public static func merge(_ dvvs: [DVV]) -> DVV { DVV(vv: mergeToVector(dvvs: dvvs)) }

    /**
     Takes two clock sets and returns a set of concurrent clocks, each belonging to one of the sets, and that
     together cover both sets while discarding obsolete knowledge.

     - parameter lhs: collection of DVV instances to sync
     - parameter rhs: collection of DVV instances to sync
     - returns: new DVV collection that represents the two input collections
     */
    public static func sync(_ lhs: [DVV], _ rhs: [DVV]) -> [DVV] {
        guard !lhs.isEmpty else { return rhs }
        guard !rhs.isEmpty else { return lhs }

        // NOTE: this is an expensive operation. For each `DVV` in `lhs`, we check if it descends from each `DVV` in `rhs`.
        let notDescends = rhs.filter { X in lhs.allSatisfy { !$0.descends(X) }}
        // Hopefully the above left few items in `notDescends`
        let notDescendsStrictly = lhs.filter { X in notDescends.allSatisfy { !$0.descendsStrictly(X) }}
        return notDescends.reversed() + notDescendsStrictly
    }
}
