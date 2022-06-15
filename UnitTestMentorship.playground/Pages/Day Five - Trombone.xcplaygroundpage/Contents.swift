//: [Previous](@previous)
import Foundation
import UIKit
import XCTest
//: # Day Five - Unit testing views
//:
//: Wait... unit testing a view?
//: Do you mean like, snapshoting it?
//:
//: No. =]
//:
//: We are actually going to take a look into how to test our view's interactions,
//: Testing if tapping the buttons, making gestures, actually produces the expected behaviour.
//:
//: Let's start by create a simple view using ViewCode.
final class TestingView: UIView {
    weak var delegate: ViewDelegate?

    private let privateButton = UIButton()
    private let text = UILabel()
    private let slidingBox = UIView()

    let internalButton = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
}
//: Here, well add the subviews and setup gestures and actions
extension TestingView {
    private func setup() {
        setupComponents()
        setupActions()
        setupGestures()
    }

    private func setupComponents() {
        addSubview(privateButton)
        addSubview(text)
        addSubview(slidingBox)
        addSubview(internalButton)
    }

    private func setupActions() {
        privateButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        internalButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }

    private func setupGestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressLabel))
        text.addGestureRecognizer(longPress)

        let slide = UIPanGestureRecognizer(target: self, action: #selector(didSlideView))
        slidingBox.addGestureRecognizer(slide)
    }
}
//: And here, we'll add the methods that are going to be called by this view actions
extension TestingView {
    @objc private func didTapButton() {
        delegate?.didTapButton()
    }

    @objc private func didSlideView() {
        delegate?.didSlideView()
    }

    @objc private func didLongPressLabel() {
        delegate?.didLongPressLabel()
    }
}
//: Pretty straightforward at this point, this is a very standard view code.
//: > I've intentionally supressed the constraining and placing the view's part of the code
//: > Because it's not important for this study.
//:
//: Next, let's add a delegate protocol to the view's actions
protocol ViewDelegate: AnyObject {
    func didTapButton()
    func didSlideView()
    func didLongPressLabel()
}
//: And finally, let's start looking into testing.
//:
//: We want to test, specifically, when interactor with a subview, if the correct method is called on the delegate.
//: In order to do that, let's add a Spy to the delegate:
final class ViewDelegateSpy: ViewDelegate {
    private(set) var didTapButtonCalled: Bool = false
    func didTapButton() {
        didTapButtonCalled = true
    }

    private(set) var didSlideViewCalled: Bool = false
    func didSlideView() {
        didSlideViewCalled = true
    }

    private(set) var didLongPressLabelCalled: Bool = false
    func didLongPressLabel() {
        didLongPressLabelCalled = true
    }
}
//: And now, let's take a look into how we can test it!
final class TestingViewTests: XCTestCase {
    // Creating the sut, nothing really new in here
    private let delegateSpy = ViewDelegateSpy()
    private lazy var sut: TestingView = {
        let sut = TestingView()
        sut.delegate = delegateSpy
        return sut
    }()

//: And now, to the test cases!
//:
//: And here's the issue... HOW THE HELL CAN WE SIMULATE A BUTTON TAP?
//: It's easy if we can access the button reference
    func test_tappingTheInternalButton_whenHaveHostApp_shouldCallDelegate() {
        sut.internalButton.sendActions(for: .touchUpInside)

        // When you have the reference of the button, (or any UIControl actually),
        // You can call the method `sendActions`,
        // Which will simulate performing that action on the button.

        XCTAssertEqual(delegateSpy.didTapButtonCalled, true)

        // But there is a pitfall in here,
        // This will only work if your tests are running on a Host App.
    }
//: When we do not have a host app - and it may happen for several reasons
//: - You are making a Pod
//: - You CI/CD does not uses a host app for better performance...
//: (Mainly 2 reasons actually 🤔)
//:
//: So, the `sendActions` method will not work.
//: What we'll need to do is calling the Selector of the action directly.
    func test_tappingTheInternalButton_withoutHostApp_shouldCallDelegate() throws {
        let action = try XCTUnwrap(sut.internalButton.actions(forTarget: sut, forControlEvent: .touchUpInside)?.first)

        // A selector's action is simply a `String` object
        // And, if you remember the Meta language properties of swift from our last day (Capybara)
        // You may remember that whec compiled, Swift keep's information about the code that generated the binary file
        // And the Selector actually runs on top of it, and will look into the `target` for the named `selector` strig method
        // OBS: need @objc tag to work!

        // Since the `sut` is what has the method we want to simulate, we call it to perform the selector
        sut.performSelector(onMainThread: .init(action), with: nil, waitUntilDone: true)

        // The `with` parameter is the parameter passed to the selector call
        // Sometimes we pass which button has called the method, or some other thing
        // And in order to work, you nee to pass this parameter.
        // In our case, it would be sth like

        /* sut.internalButton.performSelector(onMainThread: .init(action), with: sut.internalButton, waitUntilDone: true) */

        // And now, we can check our delegate one more time
        XCTAssertEqual(delegateSpy.didTapButtonCalled, true)
    }
//: Oh on! My button is private!
//: Do ot worry my young padawan, from the last day, we can also get references to private properties using Mirror,
//: And then, keep exactly the same thing from above.
    func test_tappingPrivateButton_shouldCallDelegate() throws {
        // Check the internal sources for this extension
        let button: UIButton? = reflect(from: sut, propertyName: "privateButton")

        let action = try XCTUnwrap(button?.actions(forTarget: sut, forControlEvent: .touchUpInside)?.first)

        sut.performSelector(onMainThread: .init(action), with: nil, waitUntilDone: true)

        XCTAssertEqual(delegateSpy.didTapButtonCalled, true)
    }
//: And now, let's take a look into testing gestures
    func test_longPressLabel_shouldCallDelegate() throws {
        // First, let's get the reference of our private view
        let label: UILabel? = reflect(from: sut, propertyName: "text")

        // Get the gesture
        let gesture = try XCTUnwrap(label?.gestureRecognizers?.first { $0 is UILongPressGestureRecognizer })

        // And now, the tricky part
        // Getting the selector/action string
        let target = (gesture.value(forKey: "_targets") as? [NSObject])?.first

        // We'll basically manipulate the target string in order to isolate the action
        print("👀 \(String(describing: target))")
        let selectorString = String(describing: target)
                .components(separatedBy: ", ")
                .first?
                .replacingOccurrences(of: "(action=", with: "")
                .replacingOccurrences(of: "Optional(", with: "") ?? ""

        // Perform it just as before
        sut.perform(.init(stringLiteral: selectorString))

        // And assert it
        XCTAssertTrue(delegateSpy.didLongPressLabelCalled)
    }
//: And now, to improve our tests, we'll isolate this logic of extracting the selector string into a helper method
//:
//: Here, we'll make it a little more generic, performing gestures does not need to be only on the view, and any `UIControl` can have a gesture on it.
    private func performGestureRecognizer<T: UIGestureRecognizer>(type: T.Type, from interaction: AnyObject, on view: NSObject) {
            let gesture = interaction.gestureRecognizers?.first { $0 is T }

            let target = (gesture?.value(forKey: "_targets") as? [NSObject])?.first
            let selectorString = String(describing: target)
                .components(separatedBy: ", ")
                .first?
                .replacingOccurrences(of: "(action=", with: "")
                .replacingOccurrences(of: "Optional(", with: "")
                ?? ""

            view.perform(.init(stringLiteral: selectorString))
        }
//: And make more tests!
    func test_slideBox_shouldCallDelegate() throws {
        let view: UIView? = reflect(from: sut, propertyName: "slidingBox")
        let box = try XCTUnwrap(view)

        performGestureRecognizer(type: UIPanGestureRecognizer.self, from: box, on: sut)

        XCTAssertTrue(delegateSpy.didSlideViewCalled)
    }
}
//: [Next](@next)
