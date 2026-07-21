import UIKit
import Dispatch

#if canImport(Darwin)
import Darwin // exit(), usleep()
#elseif canImport(Bionic)
import Bionic // exit(), usleep()
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

/// Runs one named test of a suite (fresh `setUp`/`tearDown`), emits its FKUITEST marker, and returns
/// nil on pass or the joined failure messages on failure. This is the unit a per-test-case host can
/// drive individually — e.g. Android runs one `@Test` per name so each shows up separately (with its
/// failure text) in the JUnit/Firebase report instead of a single opaque pass/fail.
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
    if currentFailures.isEmpty {
        emit("FKUITEST PASS \(suiteName).\(name)")
        return nil
    }
    let message = currentFailures.joined(separator: "; ")
    emit("FKUITEST FAIL \(suiteName).\(name): \(message)")
    return message
}

/// Runs every `testX` method of a suite, emitting one FKUITEST marker per test. Returns the failure count.
public func runSuite<T: XCTestCase>(_ suiteName: String, _ tests: [(String, (T) -> () throws -> Void)]) -> Int {
    var failures = 0
    for (name, _) in tests where runSingleTest(suiteName, tests, named: name) != nil {
        failures += 1
    }
    return failures
}

/// Run the given suites on the current (test) thread, report a DONE marker, and return the total
/// failure count. The caller decides what to do with it (an XCTest bridge asserts on it; a
/// standalone runner exits with a matching status) — this never exits, so it's safe under XCTest.
@discardableResult
public func runUITestSuites(_ suites: [() -> Int]) -> Int {
    var failures = 0
    for suite in suites {
        failures += suite()
    }
    emit("FKUITEST DONE failures=\(failures)")
    return failures
}

// MARK: - Marker output

/// On Android go straight to logcat via UIKit's public bridge (the stdlib `print` doesn't reach
/// logcat); on macOS stdout is captured by the run script.
func emit(_ message: String) {
    #if os(Android)
    android_log_write(LogPriority.info.rawValue, "Swift", message)
    #else
    print(message)
    #endif
}
