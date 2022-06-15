import Foundation
import XCTest

extension XCTestCase {
    public func reflect<T>(from item: Any, propertyName: String) -> T? {
        return Mirror(reflecting: item)
            .children
            .first { $0.label?.contains(propertyName) == true } as? T
    }
}

