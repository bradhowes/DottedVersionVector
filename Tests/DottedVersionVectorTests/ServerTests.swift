import XCTest
@testable import DottedVersionVector

typealias Key = String
typealias Value = (dvv: DVV, value: String)

struct KVStore {
    var store = [Key:[Value]]()
    var counter = Dot(key: "A", counter: 0)

    func get(_ key: Key, _ dvv: DVV?) -> Value? {
        guard let values = store[key] else { return nil }
        guard let dvv = dvv else {
            // No DVV so we go for the maximum counter for this node
            return values.max { lhs, rhs in lhs.dvv.counter(of: counter.key) < rhs.dvv.counter(of: counter.key) }
        }

        // The entry could have existed at one time but is now deleted
        let value = values.first { $0.dvv == dvv }
        return value
    }

    mutating func put(_ key: String, _ dvv: DVV?, _ value: String) -> Value? {
        counter = counter.increment()
        guard var values = store[key] else {
            // First entry for this key
            precondition(dvv == nil)
            let dvv = DVV(vv: [], dot: counter)
            let value = Value(dvv: dvv, value: value)
            store[key] = [value]
            return value
        }

        guard let dvv = dvv else {
            // No initial DVV so we just add a new version
            let dvv = DVV(vv: [], dot: counter)
            let value = Value(dvv: dvv, value: value)
            values.append(value)
            store[key] = values
            return value
        }

        // The entry could have existed at one time but is now deleted
        guard let found = values.firstIndex(where: { $0.dvv.dot == dvv.dot }) else {
            return nil
        }

        // Update the entry matching the dvv.
        let oldEntry = values[found]
        let newEntry = Value(dvv: oldEntry.dvv.merge(dot: counter), value: value)
        values[found] = newEntry
        store[key] = values
        return newEntry
    }
}

final class ServerTests: XCTestCase {

    func testServer() {
        var server = KVStore()
        var C1 = server.put("key", nil, "v1")
        XCTAssertEqual(DVV(vv: [], dot: Dot(key: "A", counter: 1)), C1?.dvv)
        let C2 = server.put("key", nil, "v2")
        XCTAssertEqual(DVV(vv: [], dot: Dot(key: "A", counter: 2)), C2?.dvv)
        let v1 = server.get("key", C1?.dvv)
        XCTAssertEqual("v1", v1?.value)
        let v2 = server.get("key", C2?.dvv)
        XCTAssertEqual("v2", v2?.value)
        C1 = server.put("key", C1?.dvv, "v3")
        let v3 = server.get("key", C1?.dvv)
        XCTAssertEqual("v3", v3?.value)
    }
}
