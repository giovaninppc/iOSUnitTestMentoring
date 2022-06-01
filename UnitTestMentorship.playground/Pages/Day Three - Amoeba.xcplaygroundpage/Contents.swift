//: [Previous](@previous)
import Foundation
import UIKit
import XCTest
//: # Day Three - Custom Assertions
//:
//: We are going to talk about
//: - XCTUnwrap
//: - XCTFail
//: - Test code legibility
//: - Helper methods
//: - Completion Spies
//: - Custom Assertions
//: - Test Flakyness
//:
//:
//: ### Test Code Legibility
//:
//: We have already talked about AAA (check day 1 - Butterfly),
//: And now, we are going a ste forward to discuss a little more about doce legibility.
//:
//: As every code you create, test should be legible, it should essentially be easy to understand what each step of your test is doing, and here we'll talk a little bit on every step how to improve it.
//:
//: #### • Arrange
//:
//: Here, we set the state of our sut to be the one we expect.
//: What is important in here is `Keep everything injected and consistent for test reproduction, in order to prevent flakyness`
//:
//: Consider the following scenario:
//: - We have a class that uses a current date in order to make some validations.
final class DateValidation {
    private func isWorkingHous() -> Bool {
        let currentDate = Date()
        let hourComponent = Calendar.current.component(.hour, from: currentDate)
        return hourComponent >= 8 && hourComponent <= 18
    }

    func isWorkerWorkingValid(name: String, email: String) -> Bool {
        let isValidName = name.contains(" ") && name.count > 5
        let isValidEmail = email.contains("@") && email.contains(".com")
        return isValidName && isValidEmail && isWorkingHous()
    }
}
//: Now, let's make some tests!
//: We want to test our `isWorkerWorkingValid` method, which is public
final class DateValidationTests: XCTestCase {
    private let sut = DateValidation()

    // Is this method correct?
    // What could go wrong?
    func test_isWorkerWorkingValid_whenNameIsValidAndEmailIsValid_shouldReturnTrue() {
        let name = "Dogritos Lindones"
        let email = "dogritos@email.com"

        XCTAssertEqual(sut.isWorkerWorkingValid(name: name, email: email), true)
    }
}

DateValidationTests.defaultTestSuite.run()
//: Unwillingly, this test introduces an issue: **Flakyness**.
//:
//: It will only work from 8h - 18h.
//: If you decide to run it on a different time, it will fail, can you understand why?
//:
//: To solve this issue we should
//: Inject the date creation to provide the same date while testing so our test:
//: - Has all values it uses being injected
//: - Has a consistent input, so we can assure our output at all times
//:
//: > How would you solve this issue?
//:
//: Let's make some changes on our class, by injecting the Date provider
protocol CurrentDateProvider {
    static func now() -> Date
}

extension Date: CurrentDateProvider {
    static func now() -> Date {
        return Date()
    }
}
//: This is a nice example of another `static provider protocol`, and actually onne we can use.
//: We need to have the same handling and we discussed in Day 02 for static methods in order to test
final class CurrentDateProviderStub: CurrentDateProvider {
    static var nowToBeReturned: Date = .init()
    static func now() -> Date {
        return nowToBeReturned
    }
}
//: And finally, we can innject it on our class
final class DateValidation2 {
    private let dateProvider: CurrentDateProvider.Type

    init(dateProvider: CurrentDateProvider.Type = Date.self) {
        self.dateProvider = dateProvider
    }

    // Ideally, we'd also need to inject the `Calendar` in here
    private func isWorkingHous() -> Bool {
        let currentDate = dateProvider.now()
        let hourComponent = Calendar.current.component(.hour, from: currentDate)
        return hourComponent >= 8 && hourComponent <= 18
    }

    func isWorkerWorkingValid(name: String, email: String) -> Bool {
        let isValidName = name.contains(" ") && name.count > 5
        let isValidEmail = email.contains("@") && email.contains(".com")
        return isValidName && isValidEmail && isWorkingHous()
    }
}
//: And now we can create new tests
final class DateValidationTests2: XCTestCase {
    private let dateStub = CurrentDateProviderStub.self
    private lazy var sut = DateValidation2(dateProvider: dateStub)

    func test_isWorkerWorkingValid_whenNameIsValidAndEmailIsValidAndHourIsValid_shouldReturnTrue() {
        let name = "Dogritos Lindones"
        let email = "dogritos@email.com"
        let date = date(withHourComponent: 10)
        dateStub.nowToBeReturned = date ?? Date()

        XCTAssertEqual(sut.isWorkerWorkingValid(name: name, email: email), true)
    }

    // Fail
    func test_isWorkerWorkingValid_whenNameIsValidAndEmailIsValidAndHourIsValidXCTFail_shouldReturnTrue() throws {
        let name = "Dogritos Lindones"
        let email = "dogritos@email.com"
        guard let date = date(withHourComponent: 10) else {
            return XCTFail("Unable to mock date")
        }
        dateStub.nowToBeReturned = date

        XCTAssertEqual(sut.isWorkerWorkingValid(name: name, email: email), true)
    }

    // Unwrap
    func test_isWorkerWorkingValid_whenNameIsValidAndEmailIsValidAndHourIsValidUNWRAP_shouldReturnTrue() throws {
        let name = "Dogritos Lindones"
        let email = "dogritos@email.com"
        let date = try XCTUnwrap(date(withHourComponent: 10))
        dateStub.nowToBeReturned = date

        XCTAssertEqual(sut.isWorkerWorkingValid(name: name, email: email), true)
    }

    // Custom Setup
    func test_isWorkerWorkingValid_whenNameIsValidAndEmailIsValidAndHourIsValidCUSTOMSETUP_shouldReturnTrue() throws {
        injectDate(withHour: 12)

        let result = sut.isWorkerWorkingValid(name: "Dogritos Lindones", email: "dogritos@email.com")

        XCTAssertEqual(result, true)
    }

    // Custom Assertion
    func test_isWorkerWorkingValid_whenNameIsValidAndEmailIsValidAndHourIsValidCUSTOMASSERTION_shouldReturnTrue() throws {
        XCTAssertWorker(from: sut, withName: "Dogritos Lindoes", andEmail: "d@email.com", atHour: 13, is: true)
    }
}
// MARK: - Helper Methods
extension DateValidationTests2 {
    private func date(withHourComponent hour: Int) -> Date? {
        let format = "dd/MM/yyyy - HH:mm"
        let dateString = "01/01/2001 - \(hour):00"
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: dateString)
    }

    private func injectDate(withHour hour: Int) {
        let date = date(withHourComponent: hour) ?? Date()
        dateStub.nowToBeReturned = date
    }

    private func XCTAssertWorker(from sut: DateValidation2, withName name: String, andEmail: String, atHour hour: Int, is expectedResponse: Bool, file: StaticString = #file, line: UInt = #line) {
        injectDate(withHour: hour)
        let result = sut.isWorkerWorkingValid(name: "Dogritos Lindones", email: "dogritos@email.com")
        XCTAssertEqual(result, expectedResponse, file: file, line: line)
    }
}

DateValidationTests2.defaultTestSuite.run()
//: [Next](@next)
