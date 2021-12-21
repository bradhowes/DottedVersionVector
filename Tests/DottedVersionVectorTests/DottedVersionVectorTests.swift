import XCTest
@testable import DottedVersionVector

final class DottedVersionVectorTests: XCTestCase {

  func testEmpty() {
    let vv = DotVector()
    XCTAssertEqual(vv, [])
  }

  func testInc() {
    let vv1 = DotVector().inc("A").inc("B").inc("A")
    XCTAssertEqual(vv1, [Dot(key: "A", counter: 2), Dot(key: "B", counter: 1)])
    let vv2 = DotVector().inc("A").inc("B").inc("B")
    XCTAssertEqual(vv2, [Dot(key: "A", counter: 1), Dot(key: "B", counter: 2)])
    let vv3 = DotVector().inc("A").inc("B").inc("C").inc("B").inc("A").inc("B")
    XCTAssertEqual(vv3, [Dot(key: "A", counter: 2), Dot(key: "B", counter: 3), Dot(key: "C", counter: 1)])
  }

  func testDVMerge() {
    let vv1 = DotVector().inc("A").inc("B").inc("A")
    let vv2 = DotVector().inc("B").inc("B").inc("C").inc("A")
    let vv3 = vv1.merge(vv2)
    XCTAssertEqual(vv3, [Dot(key: "A", counter: 2), Dot(key: "B", counter: 2), Dot(key: "C", counter: 1)])
  }

  func testMergeNew() {
    let vv1 = DotVector().inc("A").inc("B").inc("A")
    let vv2 = DotVector()
    let vv3 = vv1.merge(vv2)
    let vv4 = vv2.merge(vv1)
    XCTAssertEqual(vv3, [Dot(key: "A", counter: 2), Dot(key: "B", counter: 1)])
    XCTAssertEqual(vv4, [Dot(key: "A", counter: 2), Dot(key: "B", counter: 1)])
  }

  func testDot() {
    let vv1 = DotVector().inc("A").inc("A").inc("B").inc("B").inc("B").inc("C").inc("C")
    let dot = vv1.dot(of: "A")
    XCTAssertEqual(dot, Dot(key: "A", counter: 3))
  }

  func testExample() {
    // These tests mirror those in dvv.erl example_test()
    let A = DVV()
    let B = DVV()
    let A1 = A.increment(key: "a")
    let B1 = B.increment(key: "b")
    XCTAssertTrue(A1.descendsStrictly(A))
    XCTAssertTrue(B1.descendsStrictly(B))

    XCTAssertFalse(A1.descendsStrictly(B1))

    let A2 = A1.increment(key: "a")
    let C = DVV.merge([A2, B1])
    let C1 = C.increment(key: "c")
    XCTAssertFalse(C1 == A2)
    XCTAssertTrue(C1.descendsStrictly(A2))
    XCTAssertTrue(C1.descendsStrictly(B1))
    XCTAssertFalse(B1.descendsStrictly(C1))
    XCTAssertFalse(B1.descendsStrictly(A1))
  }

  func testUpdates() {
    // These tests mirror those in dvv.erl update_test()
    let c0 = DVV()
    let c1 = c0.increment(key: "A")
    XCTAssertEqual(c1.vv, [])
    XCTAssertEqual(c1.dot, Dot(key: "A", counter: 1))

    let c2 = c1.increment(key: "A")
    XCTAssertEqual(c2.vv, [Dot(key: "A", counter: 1)])
    XCTAssertEqual(c2.dot, Dot(key: "A", counter: 2))

    let c3 = c2.increment(key: "A")
    XCTAssertEqual(c3.vv, [Dot(key: "A", counter: 2)])
    XCTAssertEqual(c3.dot, Dot(key: "A", counter: 3))

    let c7 = c3.increment(key: "A")
    XCTAssertEqual(c7.vv, [Dot(key: "A", counter: 3)])
    XCTAssertEqual(c7.dot, Dot(key: "A", counter: 4))

    let c8a = c7.increment(key: "B")
    XCTAssertEqual(c8a.vv, [Dot(key: "A", counter: 4)])
    XCTAssertEqual(c8a.dot, Dot(key: "B", counter: 1))

    let c8b = DVV.update(client: c7, server: c8a, key: "B")
    XCTAssertEqual(c8b.vv, [Dot(key: "A", counter: 4)])
    XCTAssertEqual(c8b.dot, Dot(key: "B", counter: 2))

    let c8z = DVV.update(client: nil, server: c8a, key: "B")
    XCTAssertEqual(c8z.vv, [])
    XCTAssertEqual(c8z.dot, Dot(key: "B", counter: 2))

    let c8c = DVV.update(client: [c7], server: [c8a, c8b], key: "B")
    XCTAssertEqual(c8c.vv, [Dot(key: "A", counter: 4)])
    XCTAssertEqual(c8c.dot, Dot(key: "B", counter: 3))

    let c8d = DVV.update(client: [c7], server: [c8a, c8b, c8c], key: "B")
    XCTAssertEqual(c8d.vv, [Dot(key: "A", counter: 4)])
    XCTAssertEqual(c8d.dot, Dot(key: "B", counter: 4))

    let c7a = DVV.update(client: [c7], server: [c8a, c8b, c8c, c8d], key: "A")
    XCTAssertEqual(c7a.vv, [Dot(key: "A", counter: 4)])
    XCTAssertEqual(c7a.dot, Dot(key: "A", counter: 5))

    let c8e = DVV.update(client: [c7a], server: [c8a, c8b, c8c, c8d], key: "B")
    XCTAssertEqual(c8e.vv, [Dot(key: "A", counter: 5)])
    XCTAssertEqual(c8e.dot, Dot(key: "B", counter: 5))

    let c8f = DVV.update(client: [c8e], server: [c8a, c8b, c8c, c8d, c8e], key: "B")
    XCTAssertEqual(c8f.vv, [Dot(key: "A", counter: 5), Dot(key: "B", counter: 5)])
    XCTAssertEqual(c8f.dot, Dot(key: "B", counter: 6))

    let c9 = DVV.update(client: [c8f], server: [c8a, c8b, c8c, c8d, c8e, c8f], key: "A")
    XCTAssertEqual(c9.vv, [Dot(key: "A", counter: 5), Dot(key: "B", counter: 6)])
    XCTAssertEqual(c9.dot, Dot(key: "A", counter: 6))
  }

  func testDescends() {
    let C1 = DVV(vv: [], dot: Dot(key: "a", counter: 1)) // !
    let C2 = DVV(vv: [], dot: Dot(key: "a", counter: 2)) // !
    XCTAssertFalse(C1 == C2)
    XCTAssertFalse(C1.descendsStrictly(C2))
    XCTAssertFalse(C2.descendsStrictly(C1)) // !
    XCTAssertFalse(C2.descends(C1))

    let C3 = C2.increment(key: "a")
    let C4 = C3.increment(key: "a")
    let C5 = C4.increment(key: "a")
    XCTAssertTrue(C5.descendsStrictly(C3))
    XCTAssertTrue(C5.descendsStrictly(C4))
    XCTAssertFalse(C5.descendsStrictly(C5))
    XCTAssertTrue(C5.descends(C5))
    XCTAssertFalse(C4.descendsStrictly(C5))
    XCTAssertFalse(C1.descendsStrictly(C5))

    let C6 = C5.increment(key: "b")
    let C7 = C6.increment(key: "a")
    let C8a = C7.increment(key: "b")
    XCTAssertTrue(C8a.descendsStrictly(C3))
    XCTAssertTrue(C8a.descendsStrictly(C6))
    XCTAssertFalse(C8a.descendsStrictly(C8a))
    XCTAssertTrue(C8a.descends(C8a))
    XCTAssertFalse(C1.descendsStrictly(C8a))
    XCTAssertFalse(C5.descendsStrictly(C8a))
    XCTAssertFalse(C7.descendsStrictly(C8a))

    let C8b = DVV.update(client: C7, server: C8a, key: "b")
    XCTAssertTrue(C8b.descendsStrictly(C5))
    XCTAssertTrue(C8b.descendsStrictly(C7))
    XCTAssertFalse(C8b.descendsStrictly(C8b))
    XCTAssertTrue(C8b.descends(C8b))
    XCTAssertFalse(C8a.descendsStrictly(C8b))
    XCTAssertFalse(C8b.descendsStrictly(C8a))
    XCTAssertFalse(C4.descendsStrictly(C8b))
    XCTAssertFalse(C6.descendsStrictly(C8b))

    let C11 = DVV(vv: [], dot: Dot(key: "a", counter: 1))
    let C12 = DVV(vv: [], dot: Dot(key: "b", counter: 2))
    XCTAssertFalse(C11.descends(C12))
    XCTAssertFalse(C12.descends(C11))
  }

  func testMerge() {
    let C1 = DVV(vv: [Dot(key: "1", counter: 1), Dot(key: "2", counter: 2)], dot: Dot(key: "4", counter: 4))
    let C2 = DVV(vv: [Dot(key: "3", counter: 3)], dot: Dot(key: "4", counter: 4))
    let C3 = DVV.merge([C1, C2])
    XCTAssertEqual(DVV(vv: [
      Dot(key: "1", counter: 1),
      Dot(key: "2", counter: 2),
      Dot(key: "3", counter: 3),
      Dot(key: "4", counter: 4)
    ]), C3)
  }

  func testMergeLessLeft() {
    let C1 = DVV(vv: [], dot: Dot(key: "5", counter: 5))
    let C2 = DVV(vv: [Dot(key: "6", counter: 6)], dot: Dot(key: "7", counter: 7))
    let C3 = DVV.merge([C1, C2])
    XCTAssertEqual(DVV(vv: [Dot(key: "5", counter: 5), Dot(key: "6", counter: 6), Dot(key: "7", counter: 7)]), C3)
  }

  func testMergeLessRight() {
    let C1 = DVV(vv: [Dot(key: "6", counter: 6)], dot: Dot(key: "7", counter: 7))
    let C2 = DVV(vv: [], dot: Dot(key: "5", counter: 5))
    let C3 = DVV.merge([C1, C2])
    XCTAssertEqual(DVV(vv: [Dot(key: "5", counter: 5), Dot(key: "6", counter: 6), Dot(key: "7", counter: 7)]), C3)
  }

  func testMergeSameId() {
    let C1 = DVV(vv: [Dot(key: "1", counter: 1)], dot: Dot(key: "2", counter: 2))
    let C2 = DVV(vv: [Dot(key: "1", counter: 2)], dot: Dot(key: "3", counter: 3))
    let C3 = DVV.merge([C1, C2])
    XCTAssertEqual(DVV(vv: [Dot(key: "1", counter: 2), Dot(key: "2", counter: 2), Dot(key: "3", counter: 3)]), C3)
  }

  func testEquals() {
    let C1 = DVV(vv: [], dot: Dot(key: "a", counter: 1)) // !
    let C2 = DVV(vv: [], dot: Dot(key: "a", counter: 2)) // !
    XCTAssertFalse(C1 == C2)
    XCTAssertTrue(C1 == C1)
    XCTAssertFalse(C2 == C1)

    let C3 = C2.increment(key: "a")
    XCTAssertFalse(C3 == C2)

    let C4 = C3.increment(key: "a")
    XCTAssertFalse(C4 == C3)

    let C5 = C4.increment(key: "b")
    XCTAssertFalse(C5 == C4)

    let C6 = C5.increment(key: "b")
    XCTAssertFalse(C6 == C5)

    let C6b = C5.increment(key: "b")
    XCTAssertTrue(C6 == C6b)
  }

  func testSync() {
    let C1 = DVV(vv: [], dot: Dot(key: "a", counter: 1)) // !
    let C2 = DVV(vv: [], dot: Dot(key: "a", counter: 2)) // !
    XCTAssertEqual([C2, C1], DVV.sync([C1], [C2])) // !

    let C3 = C2.increment(key: "a")
    let C4 = C3.increment(key: "a")
    XCTAssertEqual([C4], DVV.sync([C3], [C4]))

    let C5 = C4.increment(key: "a")
    let C6 = C5.increment(key: "b")
    XCTAssertEqual([C6], DVV.sync([C3], [C6]))

    let C7 = C6.increment(key: "a")
    XCTAssertEqual([C7], DVV.sync([C6], [C7]))
    XCTAssertEqual([C7], DVV.sync([C7], [C7]))

    let C8a = C7.increment(key: "b")
    XCTAssertEqual([C8a], DVV.sync([C7], [C8a]))

    let C8b = DVV.update(client: C7, server: C8a, key: "b")
    XCTAssertEqual([C8b], DVV.sync([C7], [C8b]))
    XCTAssertEqual([C8b, C8a], DVV.sync([C8a], [C8b]))

    let C8c = DVV.update(client: [C7], server: [C8a, C8b], key: "b")
    XCTAssertEqual([C8c], DVV.sync([C7], [C8c]))
    XCTAssertEqual([C8b, C8c, C8a], DVV.sync([C8c, C8a], [C8b]))

    let C8d = DVV.update(client: [C7], server: [C8a, C8b, C8c], key: "a")
    XCTAssertEqual([C8c, C8d, C8a, C8b], DVV.sync([C8d, C8a, C8b], [C8c]))

    let C9 = DVV.update(client: [C8a, C8b, C8c, C8d], server: [C8a, C8b, C8c, C8d], key: "c")
    XCTAssertEqual([C9], DVV.sync([C8d, C8a, C8b, C8c], [C9]))
  }

  func testDescription() {
    let vv1 = DotVector().inc("A").inc("B").inc("A")
    XCTAssertEqual("[•A:2, •B:1]", vv1.description)
  }
}
