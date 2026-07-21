import UIKit
import Dispatch

#if canImport(Darwin)
import Darwin // usleep()
#elseif canImport(Bionic)
import Bionic // usleep()
#elseif canImport(Glibc)
import Glibc
#endif


// A tiny, synchronous, in-process UI-test framework for the SDL platforms (macOS + Android),
// API-shaped like XCTest/XCUITest so the same test file can also run under real XCUITest on iOS.
//
// The test runner runs on its OWN background thread; the app keeps rendering on the main/SDL thread.
// Waits just sleep on the test thread and poll, hopping to the main actor (`onMain`) to safely touch
// UIKit — exactly how in-process UI-test frameworks (KIF, EarlGrey) work.

open class XCTestCase {
    public required init() {}

    open func setUp() throws {}
    open func tearDown() throws {}
}

/// Run a main-actor-isolated closure synchronously from the test thread.
func onMain<T>(_ body: @MainActor () -> T) -> T {
    DispatchQueue.main.sync { MainActor.assumeIsolated { body() } }
}

/// Sleep the test thread for `seconds` (the app renders on its own thread meanwhile).
func testSleep(_ seconds: Double) {
    usleep(UInt32(seconds * 1_000_000))
}

// MARK: - Assertions (XCTest-style; record failures rather than throw, like the real thing)

var currentFailures: [String] = []

public func XCTFail(_ message: String = "", file: StaticString = #file, line: UInt = #line) {
    currentFailures.append(message.isEmpty ? "XCTFail" : message)
}

/// Record a failure unless `passed`, using `message` if provided else `defaultMessage`.
private func record(_ passed: Bool, _ defaultMessage: @autoclosure () -> String,
                    _ message: () -> String, file: StaticString, line: UInt) {
    if !passed { XCTFail(message().isEmpty ? defaultMessage() : message(), file: file, line: line) }
}

public func XCTAssert(_ expression: @autoclosure () -> Bool, _ message: @autoclosure () -> String = "",
                      file: StaticString = #file, line: UInt = #line) {
    record(expression(), "XCTAssert failed", message, file: file, line: line)
}

public func XCTAssertTrue(_ expression: @autoclosure () -> Bool, _ message: @autoclosure () -> String = "",
                          file: StaticString = #file, line: UInt = #line) {
    record(expression(), "XCTAssertTrue failed", message, file: file, line: line)
}

public func XCTAssertFalse(_ expression: @autoclosure () -> Bool, _ message: @autoclosure () -> String = "",
                           file: StaticString = #file, line: UInt = #line) {
    record(!expression(), "XCTAssertFalse failed", message, file: file, line: line)
}

public func XCTAssertEqual<T: Equatable>(_ a: @autoclosure () -> T, _ b: @autoclosure () -> T,
                                         _ message: @autoclosure () -> String = "",
                                         file: StaticString = #file, line: UInt = #line) {
    let lhs = a(), rhs = b()
    record(lhs == rhs, "XCTAssertEqual failed: (\(lhs)) != (\(rhs))", message, file: file, line: line)
}

public func XCTAssertGreaterThan<T: Comparable>(_ a: @autoclosure () -> T, _ b: @autoclosure () -> T,
                                                 _ message: @autoclosure () -> String = "",
                                                 file: StaticString = #file, line: UInt = #line) {
    let lhs = a(), rhs = b()
    record(lhs > rhs, "XCTAssertGreaterThan failed: (\(lhs)) <= (\(rhs))", message, file: file, line: line)
}

// MARK: - Runner

/// Runs one named test of a suite (fresh `setUp`/`tearDown`) and returns nil on pass or the joined
/// failure messages on failure. This is the unit a per-test-case host can drive individually — e.g.
/// Android runs one `@Test` per name so each shows up separately (with its failure text) in the
/// JUnit/Firebase report instead of a single opaque pass/fail.
public func runSingleTest<T: XCTestCase>(
    _ suiteName: String, _ tests: [(String, (T) -> () throws -> Void)], named name: String
) -> String? {
    guard let method = tests.first(where: { $0.0 == name })?.1 else {
        return "unknown test '\(name)' in suite \(suiteName)"
    }
    let testCase = T()
    currentFailures = []
    do {
        try testCase.setUp()
        try method(testCase)()
        try testCase.tearDown()
    } catch {
        currentFailures.append("\(error)")
    }
    return currentFailures.isEmpty ? nil : currentFailures.joined(separator: "; ")
}

/// Runs every `testX` method of a suite and returns the failure count.
public func runSuite<T: XCTestCase>(_ suiteName: String, _ tests: [(String, (T) -> () throws -> Void)]) -> Int {
    var failures = 0
    for (name, _) in tests where runSingleTest(suiteName, tests, named: name) != nil {
        failures += 1
    }
    return failures
}

/// Runs the given suites on the current (test) thread and returns the total failure count.
@discardableResult
public func runUITestSuites(_ suites: [() -> Int]) -> Int {
    suites.reduce(0) { $0 + $1() }
}
