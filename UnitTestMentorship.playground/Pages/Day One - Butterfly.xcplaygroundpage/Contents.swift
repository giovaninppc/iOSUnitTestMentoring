//: [Previous](@previous)
import UIKit
import XCTest
//: # The beautiful life of unit testing
//: Day 1 - Why unit testing?
struct Item {
    let name: String
    let price: Double
    let promotionalPrice: Double?
}

// Business Logic

extension Item {
    func canBePurchased(wallet: Double) -> Bool {
        guard self.price > 0 else { return false }
        if let promo = self.promotionalPrice, promo > 0 {
            return wallet > promo
        }
        return wallet > self.price
    }
}

final class ItemModelTests: XCTestCase {
    // - Check if our logic is correct
    // - Protect your code
    // - Keep project consistency / safety -> CI / CD

    // 3 steps - Unit tests
    // AAA
    // - Arrange
    // - Act - what we are testing
    // - Assert - make sure it works
    //
    // func test_act_arrange_assert()
    // func test_execute_whenEnabled_shouldDoSth()
    // func test_canBePurchased_whenWalletIsHigherThanPrice_shouldReturnTrue()

    func test_canBePurchased_whenWalletIsHigherThanPrice_shouldReturnTrue() {
        // Subject Under Tests
        let sut = Item(name: "", price: 30.0, promotionalPrice: nil)

        let result = sut.canBePurchased(wallet: 50.0)

        XCTAssertEqual(result, true)
    }

    // When an item has a promotional price
    // it should use the promotional price to check for purchasability

    func test_canBePurchased_whenHasPromotionalPrice_shouldBeTruIfWalletIsHigherThanPromotional() {
        let sut = Item(name: "", price: 30.0, promotionalPrice: 10.0)

        let result = sut.canBePurchased(wallet: 20.0)

        XCTAssertEqual(result, true)
    }

    // Promotional price can be `nil` when comming from backend
    // If the promotional price is ZERO - we should not consider it

    func test_canBePurchased_whenPromotionalPriceIsZERO_shouldUseDefaultPrice() {
        let sut = Item(name: "", price: 20.0, promotionalPrice: 0.0)

        let result = sut.canBePurchased(wallet: 5.0)

        XCTAssertEqual(result, false)
    }

    // Corner case checking
    // Regression Test - prevents a specific bug from happening
    // Our CI require regression tests on CPs (unles you add [TRIVIAL])

    // Backend Team: Issue - we can have items with negative price
    // If it happens - we cannot purchase it, because its no longer available

    func test_canBePurchased_whenPriceIsNegative_shouldALWAYSBeFalse() {
        let sut = Item(name: "", price: -20.0, promotionalPrice: 0.0)

        let result = sut.canBePurchased(wallet: 5.0)

        XCTAssertEqual(result, false)
    }
}


ItemModelTests.defaultTestSuite.run() // Swift 4

// NEXT WEEK - XCTestCase Lifecycles!
//: [Next](@next)
