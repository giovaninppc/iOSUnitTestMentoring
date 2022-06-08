import Foundation

public protocol InteractorProtocol {}
public class Interactor: InteractorProtocol {
    private let presenter: PresenterProtocol

    public init(presenter: PresenterProtocol) {
        self.presenter = presenter
    }
}

public class NewInteractor: InteractorProtocol {
    private let presenter: PresenterProtocol

    public init(presenter: PresenterProtocol) {
        self.presenter = presenter
    }
}

public protocol PresenterProtocol {}
public class Presenter: PresenterProtocol {
    weak public var controller: ControllerProtocol?

    public init() {}
}

public protocol ControllerProtocol: AnyObject {}
public class Controller: ControllerProtocol {
    private let interactor: InteractorProtocol

    public init(interactor: InteractorProtocol) {
        self.interactor = interactor
    }
}
